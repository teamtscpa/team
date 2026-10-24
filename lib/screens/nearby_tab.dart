import 'package:flutter/material.dart';

import '../main.dart';
import '../models/models.dart';
import '../services/mesh_service.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

class NearbyTab extends StatelessWidget {
  const NearbyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final mesh = scope.mesh;
    final store = scope.store;
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([mesh, store]),
      builder: (context, _) {
        final peers = mesh.peers.values.toList()
          ..sort((a, b) {
            if (a.connected != b.connected) return a.connected ? -1 : 1;
            return a.displayName.compareTo(b.displayName);
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Nearby'),
            actions: [
              IconButton(
                tooltip: 'Broadcast to everyone',
                icon: const Icon(Icons.campaign_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChatScreen(otherId: '*'))),
              ),
            ],
          ),
          body: Column(
            children: [
              _StatusBanner(mesh: mesh),
              Expanded(
                child: peers.isEmpty
                    ? EmptyState(
                        icon: Icons.radar,
                        title: mesh.running
                            ? 'Searching for people nearby…'
                            : 'Mesh is off',
                        subtitle: mesh.running
                            ? 'Open the app on another phone within ~100 m. '
                                'Bluetooth and location must be on.'
                            : 'Turn it on to find people around you.',
                        action: mesh.running
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 3))
                            : FilledButton.icon(
                                onPressed: mesh.start,
                                icon: const Icon(Icons.power_settings_new),
                                label: const Text('Turn on')),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: peers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                        itemBuilder: (_, i) => _PeerTile(peer: peers[i]),
                      ),
              ),
            ],
          ),
          floatingActionButton: mesh.running
              ? null
              : FloatingActionButton.extended(
                  onPressed: mesh.start,
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Go online')),
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.mesh});
  final MeshService mesh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String text;
    final Color color;
    if (mesh.lastError != null) {
      text = mesh.lastError!;
      color = cs.errorContainer;
    } else if (!mesh.running) {
      text = 'Mesh is off';
      color = cs.surfaceContainerHighest;
    } else {
      final n = mesh.connectedPeers.length;
      text = n == 0
          ? 'Online · looking for peers'
          : 'Online · $n ${n == 1 ? 'peer' : 'peers'} connected';
      color = cs.primaryContainer;
    }
    return Material(
      color: color,
      child: InkWell(
        onTap: mesh.running ? mesh.stop : mesh.start,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(mesh.running ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                  size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
              Text(mesh.running ? 'Stop' : 'Start',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  const _PeerTile({required this.peer});
  final Peer peer;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final profile = peer.profile;
    final saved = profile != null &&
        scope.store.contacts.any((c) => c.profile.id == profile.id);

    return ListTile(
      leading: Avatar(
          label: profile?.initials ??
              (peer.displayName.isEmpty ? '?' : peer.displayName[0].toUpperCase()),
          online: peer.connected),
      title: Text(peer.displayName),
      subtitle: Text(
        !peer.connected
            ? 'Connecting…'
            : profile == null
                ? 'Connected · exchanging cards'
                : [profile.headline, profile.company]
                    .where((s) => s.isNotEmpty)
                    .join(' · ')
                    .ifEmpty('Connected'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (profile != null)
            IconButton(
              tooltip: saved ? 'Saved to contacts' : 'Save contact',
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_add_outlined,
                  color: saved ? cs.primary : null),
              onPressed: saved
                  ? null
                  : () async {
                      await scope.store.addContact(profile);
                      scope.mesh.shareMyProfile(peer.endpointId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${profile.name} saved · your card was sent')));
                      }
                    },
            ),
          IconButton(
            tooltip: 'Message',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: profile == null
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(otherId: profile.id))),
          ),
        ],
      ),
      onTap: profile == null
          ? null
          : () => showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (_) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: ProfileCard(profile: profile),
                ),
              ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
