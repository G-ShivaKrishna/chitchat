import 'package:flutter/material.dart';

class CallsPage extends StatelessWidget {
  const CallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mockCalls = List.generate(
      10,
      (i) => CallEntry('Contact $i', i.isEven ? CallType.incoming : CallType.outgoing, DateTime.now().subtract(Duration(minutes: i * 11)), i % 3 == 0),
    );
    return ListView.separated(
      itemCount: mockCalls.length,
      separatorBuilder: (_, __) => const Divider(height: 0, color: Colors.white10),
      itemBuilder: (context, index) {
        final c = mockCalls[index];
        return ListTile(
          leading: CircleAvatar(backgroundColor: Colors.primaries[index % Colors.primaries.length], child: Text(c.name.substring(0,1))),
          title: Text(c.name, style: const TextStyle(color: Colors.white)),
          subtitle: Row(
            children: [
              Icon(
                c.type == CallType.incoming ? Icons.call_received : Icons.call_made,
                size: 16,
                color: c.missed ? Colors.redAccent : Colors.greenAccent,
              ),
              const SizedBox(width: 4),
              Text(_formatTime(c.time), style: const TextStyle(color: Colors.white70)),
            ],
          ),
          trailing: const Icon(Icons.call, color: Colors.greenAccent),
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

enum CallType { incoming, outgoing }

class CallEntry {
  final String name;
  final CallType type;
  final DateTime time;
  final bool missed;
  CallEntry(this.name, this.type, this.time, this.missed);
}
