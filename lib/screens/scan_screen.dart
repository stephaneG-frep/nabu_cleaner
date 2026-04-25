import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cleaner_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    final provider = context.read<CleanerProvider>();
    Future<void>.microtask(() async {
      await provider.runScan();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanerProvider>();
    final progress = provider.scanProgress;
    final done = !provider.isScanning && progress >= 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Analyse en cours')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            RotationTransition(
              turns: _controller,
              child: Icon(
                Icons.radar,
                size: 96,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              provider.scanMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              provider.realScanEnabled
                  ? 'Mode de scan: Reel Android'
                  : 'Mode de scan: Simule',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('${(progress * 100).toStringAsFixed(0)} %'),
            const SizedBox(height: 20),
            const Text(
              'Nous analysons uniquement les fichiers accessibles utilisateur: '
              'gros fichiers, APK, archives, videos et doublons potentiels. '
              'Aucune suppression automatique n\'est effectuee.',
              textAlign: TextAlign.center,
            ),
            if (provider.lastScanWarning != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.lastScanWarning!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: done ? () => Navigator.of(context).pop() : null,
                child: const Text('Voir les resultats'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
