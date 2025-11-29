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
  final _aboutController = TextEditingController(
    text: 'Hey there! I am using Chitchat',
  );

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
      _aboutController.text =
          (row?['about'] as String?) ?? _aboutController.text;
      _avatarUrl = await _toDisplayUrl(row?['avatar_url'] as String?);
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
      // Remember current avatar path for cleanup after successful upload.
      final oldPath = _extractPathFromPublicUrl(_avatarUrl);
      await client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: true),
          );
      final publicUrl = client.storage.from('avatars').getPublicUrl(path);
      final displayUrl = await _toDisplayUrl(publicUrl);
      setState(() {
        _avatarUrl = displayUrl;
      });
      // Persist avatar_url immediately to the user's profile.
      final exists = await _profileExists(user.id);
      if (exists) {
        await client
            .from('profiles')
            .update({'avatar_url': publicUrl})
            .eq('id', user.id);
      } else {
        if (_username == null || _username!.trim().isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Set a username first before adding an avatar.'),
              ),
            );
          }
        } else {
          await client.from('profiles').insert({
            'id': user.id,
            'username': _username,
            'avatar_url': publicUrl,
          });
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar updated')));
      }

      // After successfully updating, delete the previous avatar file if it exists.
      if (oldPath != null && oldPath != path) {
        try {
          await client.storage.from('avatars').remove([oldPath]);
        } catch (_) {
          // Non-fatal cleanup error; ignore.
        }
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Storage error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Avatar upload failed: $e')));
      }
    }
  }

  Future<String?> _toDisplayUrl(String? storedUrl) async {
    if (storedUrl == null) return null;
    // If bucket is private or CDN caching causes issues on web, use a signed URL.
    final client = Supabase.instance.client;
    final path = _extractPathFromPublicUrl(storedUrl);
    if (path == null) return storedUrl;
    try {
      final signed = await client.storage
          .from('avatars')
          .createSignedUrl(path, 3600); // 1 hour
      return signed;
    } catch (_) {
      return storedUrl; // fallback to public URL
    }
  }

  Future<bool> _profileExists(String userId) async {
    final client = Supabase.instance.client;
    try {
      final row = await client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  String? _extensionFromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return null;
    return name.substring(dot + 1);
  }

  // Extract '<uid>/<filename>' from public avatar URL
  String? _extractPathFromPublicUrl(String? url) {
    if (url == null) return null;
    const marker = '/storage/v1/object/public/avatars/';
    final i = url.indexOf(marker);
    if (i == -1) return null;
    return url.substring(i + marker.length);
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
      final exists = await _profileExists(user.id);
      if (exists) {
        await client
            .from('profiles')
            .update({
              'display_name': _nameController.text.trim(),
              'about': _aboutController.text.trim(),
              if (_avatarUrl != null) 'avatar_url': _avatarUrl,
            })
            .eq('id', user.id)
            .timeout(const Duration(seconds: 15));
      } else {
        if (_username == null || _username!.trim().isEmpty) {
          setState(() {
            _error = 'Set a username first before saving profile.';
          });
          return;
        }
        await client
            .from('profiles')
            .insert({
              'id': user.id,
              'username': _username,
              'display_name': _nameController.text.trim(),
              'about': _aboutController.text.trim(),
              if (_avatarUrl != null) 'avatar_url': _avatarUrl,
            })
            .timeout(const Duration(seconds: 15));
      }
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
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
          ),
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
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFF1F2C33),
                          child: ClipOval(
                            child: _avatarUrl != null
                                ? Image.network(
                                    _avatarUrl!,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) {
                                      return const Icon(
                                        Icons.person,
                                        size: 48,
                                        color: Colors.white70,
                                      );
                                    },
                                  )
                                : const Icon(Icons.person, size: 48),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: FloatingActionButton.small(
                            onPressed:
                                (_username == null || _username!.trim().isEmpty)
                                ? null
                                : _pickAndUploadAvatar,
                            backgroundColor: const Color(0xFF25D366),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_username == null || _username!.trim().isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.4),
                        ),
                      ),
                      child: const Text(
                        'Set your username first to enable avatar uploads.',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                  if (_username == null || _username!.trim().isEmpty)
                    const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.black,
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
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
