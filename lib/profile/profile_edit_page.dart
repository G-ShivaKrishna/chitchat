import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController(text: 'Hey there! I am using Chitchat');

  String? _email;
  String? _username;
  String? _avatarUrl;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Not signed in';
        _loading = false;
      });
      return;
    }
    try {
      _email = user.email;
      final row = await client
          .from('profiles')
          .select('username, display_name, about, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      _username = row?['username'] as String?;
      _nameController.text = (row?['display_name'] as String?) ?? '';
      _aboutController.text = (row?['about'] as String?) ?? _aboutController.text;
      _avatarUrl = row?['avatar_url'] as String?;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    final ext = _extensionFromName(file.name) ?? 'jpg';
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final mime = lookupMimeType(file.name) ?? 'image/jpeg';

    try {
      await client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: true),
          );
      final publicUrl = client.storage.from('avatars').getPublicUrl(path);
      setState(() {
        _avatarUrl = publicUrl;
      });
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar upload failed: $e')),
        );
      }
    }
  }

  String? _extensionFromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return null;
    return name.substring(dot + 1);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() {
        _saving = false;
        _error = 'Not signed in';
      });
      return;
    }

    try {
      await client
          .from('profiles')
          .upsert({
            'id': user.id,
            'display_name': _nameController.text.trim(),
            'about': _aboutController.text.trim(),
            if (_avatarUrl != null) 'avatar_url': _avatarUrl,
          }, onConflict: 'id')
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on PostgrestException catch (e) {
      setState(() {
        _error = e.message;
      });
    } on TimeoutException catch (e) {
      setState(() {
        _error = e.message ?? 'Save timed out. Check connection.';
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.redAccent.withOpacity(0.2),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  const SizedBox(height: 12),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null ? const Icon(Icons.person, size: 48) : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: FloatingActionButton.small(
                            onPressed: _pickAndUploadAvatar,
                            backgroundColor: const Color(0xFF25D366),
                            child: const Icon(Icons.camera_alt, color: Colors.black),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _label('Email (read-only)'),
                  _roText(_email ?? ''),
                  const SizedBox(height: 16),
                  _label('Username (read-only)'),
                  _roText(_username ?? ''),
                  const SizedBox(height: 16),
                  _label('Display name'),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(),
                  ),
                  const SizedBox(height: 16),
                  _label('About'),
                  TextField(
                    controller: _aboutController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
      );

  Widget _roText(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white24.withOpacity(0.6)),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      );

  InputDecoration _inputDecoration() => const InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
      );
}
