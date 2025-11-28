import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class UsernameSetupPage extends StatefulWidget {
  const UsernameSetupPage({super.key});

  @override
  State<UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<UsernameSetupPage> {
  final _controller = TextEditingController();
  bool _checking = false;
  bool _saving = false;
  String? _error;
  String? _availability;

  Future<void> _checkAvailability() async {
    setState(() {
      _checking = true;
      _error = null;
      _availability = null;
    });
    final username = _normalize(_controller.text);
    if (username == null) {
      setState(() {
        _checking = false;
        _error = 'Enter 3-20 characters: letters, numbers, underscore.';
      });
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('username', username);
      final exists = (rows as List).isNotEmpty;
      setState(() {
        _availability = exists ? 'Not available' : 'Available';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to check availability: $e';
      });
    } finally {
      setState(() {
        _checking = false;
      });
    }
  }

  Future<void> _saveUsername() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final username = _normalize(_controller.text);
    if (username == null) {
      setState(() {
        _saving = false;
        _error = 'Enter 3-20 characters: letters, numbers, underscore.';
      });
      return;
    }
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
      // Upsert profile with unique username, with a safety timeout.
      await client
          .from('profiles')
          .upsert({'id': user.id, 'username': username}, onConflict: 'id')
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        // Move out of setup to main home.
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const ChatHome()));
      }
    } on PostgrestException catch (e) {
      setState(() {
        _error = e.message;
      });
    } on TimeoutException catch (e) {
      setState(() {
        _error = e.message ?? 'Saving timed out. Check connection.';
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

  String? _normalize(String raw) {
    final s = raw.trim().toLowerCase();
    final valid = RegExp(r'^[a-z0-9_]{3,20}$');
    if (!valid.hasMatch(s)) return null;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        title: const Text('Choose a username'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pick a unique username so friends can find you.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                hintText: 'e.g. alex_123',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _checking ? null : _checkAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.black,
                  ),
                  child: _checking
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Check'),
                ),
                const SizedBox(width: 12),
                if (_availability != null)
                  Text(
                    _availability!,
                    style: TextStyle(
                      color: _availability == 'Available'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : _saveUsername,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save username'),
            ),
          ],
        ),
      ),
    );
  }
}
