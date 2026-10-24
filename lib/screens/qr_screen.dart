import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../main.dart';
import '../models/models.dart';
import '../widgets/common.dart';

const _qrPrefix = 'meshcard:';

/// Shows my profile as a QR code so someone can scan it even when the
/// mesh isn't connected (e.g. iOS <-> Android, or a crowded room).
class QrShareScreen extends StatelessWidget {
  const QrShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).store.profile;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My QR card')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: cs.shadow.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8))
                    ]),
                child: QrImageView(
                  data: '$_qrPrefix${profile.encode()}',
                  size: 260,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 24),
              Text(profile.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (profile.headline.isNotEmpty) Text(profile.headline),
              const SizedBox(height: 8),
              Text('Ask them to scan this from Contacts → scan icon.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates, formats: [BarcodeFormat.qrCode]);
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || !raw.startsWith(_qrPrefix)) return;
    Profile profile;
    try {
      profile = Profile.decode(raw.substring(_qrPrefix.length));
    } catch (_) {
      return;
    }
    _handled = true;
    await _controller.stop();
    if (!mounted) return;

    final save = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileCard(profile: profile),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save to contacts'),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (save == true) {
      await AppScope.of(context).store.addContact(profile);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${profile.name} saved')));
        Navigator.pop(context);
      }
    } else {
      _handled = false;
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan a card'),
        actions: [
          IconButton(
              icon: const Icon(Icons.flashlight_on_outlined),
              onPressed: _controller.toggleTorch),
          IconButton(
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: _controller.switchCamera),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
