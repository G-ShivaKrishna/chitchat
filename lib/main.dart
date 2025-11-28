import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: 'https://exzmgkgznwguyafvmnrh.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4em1na2d6bndndXlhZnZtbnJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMzI0MzAsImV4cCI6MjA3OTkwODQzMH0.z1tna4xDeIheIAMaHWhrunUiQXXUmQqzJbG4br8n2bo',
    );
    debugPrint('[Supabase] Initialization succeeded');
    // Lightweight connectivity check: fetch current user (null if not signed in).
    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('[Supabase] Current user: ${user?.id ?? 'none'}');
  } catch (e, st) {
    debugPrint('[Supabase] Initialization failed: $e');
    debugPrint(st.toString());
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chitchat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const ChatHome();
        }
        return const SignInPage();
      },
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
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
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session != null) {
        setState(() => _info = 'Signed in as ${res.session!.user.email}');
      }
    } on AuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
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
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (!_validateInputs(email, password)) {
        setState(() => _loading = false);
        return;
      }
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user != null) {
        setState(() => _info = 'Account created. Check email for confirmation if required.');
      }
    } on AuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
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
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_info != null)
              Text(_info!, style: const TextStyle(color: Colors.green)),
            ElevatedButton(
              onPressed: _loading ? null : _signIn,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Sign in'),
            ),
            TextButton(
              onPressed: _loading ? null : _signUp,
              child: const Text('Create account'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                        _info = null;
                      });
                      try {
                        final version = await Supabase.instance.client.functions.invoke('health');
                        setState(() => _info = 'Edge Function health: ${version.data}');
                      } catch (e) {
                        setState(() => _error = 'Health check failed: $e');
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: const Text('Connectivity check'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatHome extends StatelessWidget {
  const ChatHome({super.key});

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chitchat'),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(child: Text('Hello, ${user?.email ?? 'user'}')),
    );
  }
}
