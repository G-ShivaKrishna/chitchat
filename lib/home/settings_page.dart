import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return ListView(
      children: [
        const SizedBox(height: 16),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(
            user?.email ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Tap to edit profile',
            style: TextStyle(color: Colors.white70),
          ),
          onTap: () {},
        ),
        const Divider(color: Colors.white24),
        ListTile(
          leading: const Icon(Icons.lock, color: Colors.white70),
          title: const Text('Privacy', style: TextStyle(color: Colors.white)),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.color_lens, color: Colors.white70),
          title: const Text(
            'Appearance',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.storage, color: Colors.white70),
          title: const Text(
            'Storage & Data',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.white70),
          title: const Text('About', style: TextStyle(color: Colors.white)),
          onTap: () {},
        ),
        const Divider(color: Colors.white24),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.redAccent),
          ),
          onTap: _signOut,
        ),
      ],
    );
  }
}
