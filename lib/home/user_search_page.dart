import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _queryController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final q = _queryController.text.trim().toLowerCase();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id, username')
          .ilike('username', '%$q%');
      setState(() {
        _results = List<Map<String, dynamic>>.from(rows as List);
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _pingUser(Map<String, dynamic> row) {
    final username = row['username'] as String? ?? 'unknown';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Pinged $username')));
    // TODO: Create/open conversation and navigate to chat thread.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C33),
        title: const Text('Search users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search by username',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white70),
                  onPressed: _loading ? null : _search,
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final row = _results[index];
                      final username = row['username'] as String? ?? 'unknown';
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(username.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: TextButton(
                          onPressed: () => _pingUser(row),
                          child: const Text('Ping'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
