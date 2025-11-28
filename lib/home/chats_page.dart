import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mockChats = List.generate(12, (i) => ChatPreview('Contact $i', 'Last message snippet $i', DateTime.now().subtract(Duration(minutes: i * 7))));
    return ListView.separated(
      itemCount: mockChats.length,
      separatorBuilder: (_, __) => const Divider(height: 0, color: Colors.white10),
      itemBuilder: (context, index) {
        final chat = mockChats[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.primaries[index % Colors.primaries.length],
            child: Text(chat.name.substring(0, 1)),
          ),
          title: Text(chat.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(chat.lastMessage, style: const TextStyle(color: Colors.white70)),
          trailing: Text(_formatTime(chat.time), style: const TextStyle(color: Colors.white60, fontSize: 12)),
          onTap: () {},
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class ChatPreview {
  final String name;
  final String lastMessage;
  final DateTime time;
  ChatPreview(this.name, this.lastMessage, this.time);
}
