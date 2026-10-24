import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';
import 'qr_screen.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final q = _query.toLowerCase();
        final list = store.contacts
            .where((c) =>
                q.isEmpty ||
                c.profile.name.toLowerCase().contains(q) ||
                c.profile.company.toLowerCase().contains(q) ||
                c.profile.headline.toLowerCase().contains(q))
            .toList()
          ..sort((a, b) => b.metAt.compareTo(a.metAt));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Contacts'),
            actions: [
              IconButton(
                tooltip: 'Scan a card',
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QrScanScreen())),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search people',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
          ),
          body: list.isEmpty
              ? EmptyState(
                  icon: Icons.people_outline,
                  title: store.contacts.isEmpty ? 'No contacts yet' : 'No matches',
                  subtitle: store.contacts.isEmpty
                      ? 'Save people from Nearby, or scan their QR card.'
                      : null,
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) => _ContactTile(contact: list[i]),
                ),
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final p = contact.profile;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Avatar(label: p.initials),
      title: Text(p.name),
      subtitle: Text(
        [p.headline, p.company].where((s) => s.isNotEmpty).join(' · ').isEmpty
            ? 'Met ${DateFormat.yMMMd().format(contact.metAt)}'
            : [p.headline, p.company].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact))),
    );
  }
}

class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({super.key, required this.contact});
  final Contact contact;

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late final _note = TextEditingController(text: widget.contact.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _open(String uri) async {
    final u = Uri.tryParse(uri);
    if (u != null && await canLaunchUrl(u)) await launchUrl(u);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final p = widget.contact.profile;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Remove ${p.name}?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Remove')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await store.removeContact(p.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileCard(profile: p),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatScreen(otherId: p.id))),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message'),
                ),
              ),
              const SizedBox(width: 10),
              if (p.phone.isNotEmpty)
                IconButton.filledTonal(
                    onPressed: () => _open('tel:${p.phone}'),
                    icon: const Icon(Icons.phone)),
              if (p.email.isNotEmpty)
                IconButton.filledTonal(
                    onPressed: () => _open('mailto:${p.email}'),
                    icon: const Icon(Icons.mail_outline)),
              if (p.website.isNotEmpty)
                IconButton.filledTonal(
                    onPressed: () => _open(p.website.startsWith('http')
                        ? p.website
                        : 'https://${p.website}'),
                    icon: const Icon(Icons.open_in_new)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Met ${DateFormat.yMMMMd().add_jm().format(widget.contact.metAt)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Private note',
                hintText: 'Where you met, what you talked about…',
                alignLabelWithHint: true),
            onChanged: (v) => store.updateContactNote(p.id, v),
          ),
        ],
      ),
    );
  }
}
