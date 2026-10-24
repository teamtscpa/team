import 'package:flutter/material.dart';

import '../models/models.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.label, this.size = 44, this.online});
  final String label;
  final double size;
  final bool? online;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Deterministic hue from the label so each person keeps a stable colour.
    final hue = (label.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
    final bg = HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.80).toColor();
    final fg = HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.25).toColor();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
                color: fg, fontWeight: FontWeight.w700, fontSize: size * 0.36),
          ),
        ),
        if (online != null)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: online! ? const Color(0xFF2ECC71) : cs.outline,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle, this.action});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.primary.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// A business-card style view of a profile.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.profile, this.trailing});
  final Profile profile;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(label: profile.initials, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name,
                        style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    if (profile.headline.isNotEmpty)
                      Text(profile.headline, style: t.bodyMedium),
                    if (profile.company.isNotEmpty)
                      Text(profile.company,
                          style: t.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(profile.bio, style: t.bodyMedium),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (profile.phone.isNotEmpty)
                _chip(context, Icons.phone_outlined, profile.phone),
              if (profile.email.isNotEmpty)
                _chip(context, Icons.mail_outline, profile.email),
              if (profile.website.isNotEmpty)
                _chip(context, Icons.link, profile.website),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
