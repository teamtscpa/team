import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherId});

  /// Profile id of the other person, or '*' for the broadcast room.
  final String otherId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await AppScope.of(context).mesh.sendText(text, toId: widget.otherId);
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final mesh = scope.mesh;
    final cs = Theme.of(context).colorScheme;
    final isBroadcast = widget.otherId == '*';

    return AnimatedBuilder(
      animation: Listenable.merge([store, mesh]),
      builder: (context, _) {
        final msgs = store.conversation(widget.otherId);
        final online = isBroadcast
            ? mesh.connectedPeers.isNotEmpty
            : mesh.connectedPeers.any((p) => p.profile?.id == widget.otherId);
        _jumpToEnd();

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                Avatar(
                    label: isBroadcast ? '✦' : store.nameFor(widget.otherId).initialsOf(),
                    size: 36,
                    online: online),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.nameFor(widget.otherId),
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        isBroadcast
                            ? '${mesh.connectedPeers.length} nearby'
                            : online
                                ? 'In range'
                                : 'Out of range · messages will relay',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: msgs.isEmpty
                    ? EmptyState(
                        icon: isBroadcast ? Icons.campaign_outlined : Icons.waving_hand_outlined,
                        title: isBroadcast ? 'Say hi to everyone nearby' : 'Start the conversation',
                        subtitle: 'Messages hop between phones, so they can '
                            'reach people who aren\'t in direct range.')
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: msgs.length,
                        itemBuilder: (_, i) {
                          final m = msgs[i];
                          final showDay = i == 0 ||
                              !_sameDay(msgs[i - 1].sentAt, m.sentAt);
                          return Column(
                            children: [
                              if (showDay) _DayLabel(m.sentAt),
                              _Bubble(
                                  message: m,
                                  mine: m.fromId == store.profile.id,
                                  showName: isBroadcast),
                            ],
                          );
                        },
                      ),
              ),
              _Composer(controller: _input, onSend: _send),
            ],
          ),
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Message',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
                onPressed: onSend, icon: const Icon(Icons.arrow_upward)),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, required this.showName});
  final Message message;
  final bool mine;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time = DateFormat.jm().format(message.sentAt);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showName && !mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(message.fromName,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
              ),
            Text(message.text,
                style: TextStyle(color: mine ? cs.onPrimary : cs.onSurface)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.hops > 0) ...[
                  Icon(Icons.alt_route, size: 12,
                      color: (mine ? cs.onPrimary : cs.onSurfaceVariant).withOpacity(0.7)),
                  const SizedBox(width: 2),
                  Text('${message.hops} hop${message.hops == 1 ? '' : 's'} · ',
                      style: TextStyle(
                          fontSize: 10,
                          color: (mine ? cs.onPrimary : cs.onSurfaceVariant)
                              .withOpacity(0.7))),
                ],
                Text(time,
                    style: TextStyle(
                        fontSize: 10,
                        color: (mine ? cs.onPrimary : cs.onSurfaceVariant)
                            .withOpacity(0.7))),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(message.delivered ? Icons.done_all : Icons.done,
                      size: 13, color: cs.onPrimary.withOpacity(0.8)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.date);
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = date.year == now.year && date.month == now.month && date.day == now.day
        ? 'Today'
        : DateFormat.MMMd().format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

extension on String {
  String initialsOf() {
    final parts = trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
