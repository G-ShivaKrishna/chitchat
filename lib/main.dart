import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/welcome_page.dart';
import 'auth/email_auth_page.dart';
import 'home/chats_page.dart';
import 'home/updates_page.dart';
import 'home/calls_page.dart';
import 'home/settings_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1F2C33),
        title: const Text('Chitchat'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            onSelected: (v) async {
              if (v == 'logout') await _signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF25D366),
          labelColor: const Color(0xFF25D366),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Updates'),
            Tab(text: 'Calls'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ChatsPage(),
          UpdatesPage(),
          CallsPage(),
          SettingsPage(),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton(
          backgroundColor: const Color(0xFF25D366),
          onPressed: () {},
          child: const Icon(Icons.chat),
        );
      case 1:
        return FloatingActionButton(
          backgroundColor: const Color(0xFF25D366),
          onPressed: () {},
          child: const Icon(Icons.camera_alt),
        );
      case 2:
        return FloatingActionButton(
          backgroundColor: const Color(0xFF25D366),
          onPressed: () {},
          child: const Icon(Icons.add_call),
        );
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
