import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _info;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!_validateInputs(email, password)) {
      setState(() => _loading = false);
      return;
    }
    try {
      final stopwatch = Stopwatch()..start();
      final response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Sign-in timed out. Check connection.');
            },
          );
      stopwatch.stop();
      debugPrint(
        '[Auth] Sign in completed in ${stopwatch.elapsedMilliseconds}ms; session: ${response.session != null}',
      );
      if (response.session == null) {
        setState(
          () => _info =
              'Signed in, but no session. Email confirmation may be required.',
        );
      } else {
        // Successful sign in: return to AuthGate (root) so it rebuilds and shows HomeShell.
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } on TimeoutException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!_validateInputs(email, password)) {
      setState(() => _loading = false);
      return;
    }
    try {
      final stopwatch = Stopwatch()..start();
      final response = await Supabase.instance.client.auth
          .signUp(email: email, password: password)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Sign-up timed out. Check connection.');
            },
          );
      stopwatch.stop();
      debugPrint(
        '[Auth] Sign up completed in ${stopwatch.elapsedMilliseconds}ms; user: ${response.user != null}; session: ${response.session != null}',
      );
      if (response.session != null) {
        setState(
          () =>
              _info = 'Account created & signed in as ${response.user!.email}',
        );
        // Navigate back to root; AuthGate will detect session and show HomeShell.
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        setState(
          () => _info =
              'Account created. Please verify your email before signing in.',
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } on TimeoutException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _validateInputs(String email, String password) {
    if (email.isEmpty) {
      _error = 'Email required';
      return false;
    }
    if (!email.contains('@')) {
      _error = 'Invalid email format';
      return false;
    }
    if (password.length < 6) {
      _error = 'Password must be at least 6 characters';
      return false;
    }
    return true;
  }

  String _friendlyAuthError(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Invalid email/password. If new, tap Create account first.';
      case 'email_not_confirmed':
        return 'Email not confirmed. Check inbox for verification link.';
      case 'user_not_found':
        return 'User not found. Create an account first.';
      case 'over_email_send_rate':
        return 'Too many requests. Please wait before trying again.';
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        title: const Text('Sign in with email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
              obscureText: true,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_info != null)
              Text(_info!, style: const TextStyle(color: Colors.green)),
            const Spacer(),
            ElevatedButton(
              onPressed: _loading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _loading ? null : _signUp,
                  child: const Text('Create account'),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
