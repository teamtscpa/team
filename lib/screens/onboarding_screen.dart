import 'package:flutter/material.dart';

import '../main.dart';
import 'profile_edit_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.hub_outlined, color: cs.onPrimary, size: 40),
              ),
              const SizedBox(height: 28),
              Text('Mesh',
                  style: t.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(
                'Chat with people around you without internet or cell service, '
                'and swap contact cards with the people you meet.',
                style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              _feature(context, Icons.wifi_tethering, 'Works offline',
                  'Messages hop phone-to-phone over Bluetooth & Wi-Fi.'),
              _feature(context, Icons.badge_outlined, 'Your card',
                  'Share your profile by tapping a peer or scanning a QR code.'),
              _feature(context, Icons.lock_outline, 'Stays on your phone',
                  'No account, no server. Everything is stored locally.'),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ProfileEditScreen(
                            profile: AppScope.of(context).store.profile,
                            firstRun: true)),
                  ),
                  child: const Text('Set up my profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(BuildContext c, IconData i, String title, String body) {
    final cs = Theme.of(c).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(i, color: cs.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(c).textTheme.titleSmall),
                Text(body,
                    style: Theme.of(c)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
