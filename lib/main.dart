import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/welcome_page.dart';
import 'auth/email_auth_page.dart';

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
      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/email': (_) => const EmailAuthPage(),
      },
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
        return const WelcomePage();
      },
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
