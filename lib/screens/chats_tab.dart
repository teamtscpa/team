import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final ids = store.conversationIds();
        return Scaffold(
          appBar: AppBar(title: const Text('Chats')),
          body: ids.isEmpty
              ? EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No conversations yet',
                  subtitle: 'Message someone from the Nearby tab, or broadcast to everyone.',
                  action: FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ChatScreen(otherId: '*'))),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Everyone nearby'),
                  ),
                )
              : ListView.separated(
                  itemCount: ids.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final id = ids[i];
                    final msgs = store.conversation(id);
                    final last = msgs.last;
                    final name = store.nameFor(id);
                    return ListTile(
                      leading: Avatar(
                          label: id == '*'
                              ? '✦'
                              : name.split(' ').take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase()),
                      title: Text(name),
                      subtitle: Text(
                        (last.fromId == store.profile.id ? 'You: ' : '') + last.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _when(last.sentAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ChatScreen(otherId: id))),
                    );
                  },
                ),
        );
      },
    );
  }

  static String _when(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return DateFormat.jm().format(d);
    }
    return DateFormat.MMMd().format(d);
  }
}
