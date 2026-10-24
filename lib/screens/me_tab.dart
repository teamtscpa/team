import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/common.dart';
import 'profile_edit_screen.dart';
import 'qr_screen.dart';

class MeTab extends StatelessWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final mesh = scope.mesh;
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([store, mesh]),
      builder: (context, _) {
        final p = store.profile;
        return Scaffold(
          appBar: AppBar(title: const Text('Me')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ProfileCard(
                profile: p,
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProfileEditScreen(profile: p))),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const QrShareScreen())),
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Show my QR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const QrScanScreen())),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Mesh', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Discoverable'),
                subtitle: Text(mesh.running
                    ? '${mesh.connectedPeers.length} connected · '
                        '${mesh.peers.length} seen'
                    : 'Off — nobody can find or message you'),
                value: mesh.running,
                onChanged: (v) => v ? mesh.start() : mesh.stop(),
              ),
              const SizedBox(height: 20),
              Text('Stats', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  _stat(context, '${store.contacts.length}', 'contacts'),
                  _stat(context, '${store.messages.length}', 'messages'),
                  _stat(context, '${store.conversationIds().length}', 'chats'),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Everything stays on this phone. There is no account and no server — '
                'messages travel directly between phones over Bluetooth and Wi-Fi.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(BuildContext c, String value, String label) {
    final cs = Theme.of(c).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(c)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: Theme.of(c).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
