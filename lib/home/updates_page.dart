import 'package:flutter/material.dart';

class UpdatesPage extends StatelessWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mockStatuses = List.generate(
      8,
      (i) => StatusPreview(
        'Friend $i',
        DateTime.now().subtract(Duration(hours: i)),
      ),
    );
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent updates',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final s = mockStatuses[index];
            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Colors.primaries[index % Colors.primaries.length],
                    child: Text(s.name.substring(0, 1)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      width: 12,
                      height: 12,
                    ),
                  ),
                ],
              ),
              title: Text(s.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                _relativeTime(s.time),
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {},
            );
          }, childCount: mockStatuses.length),
        ),
      ],
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class StatusPreview {
  final String name;
  final DateTime time;
  StatusPreview(this.name, this.time);
}
