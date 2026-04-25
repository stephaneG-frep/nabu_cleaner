import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/file_category.dart';
import '../providers/cleaner_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/category_summary_card.dart';
import '../widgets/storage_meter.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenResults,
    required this.onOpenDuplicates,
  });

  final VoidCallback onOpenResults;
  final VoidCallback onOpenDuplicates;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanerProvider>();
    final lastScan = provider.lastScanAt == null
        ? 'Aucun scan'
        : DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(provider.lastScanAt!);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Nabu Cleaner',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Nettoyage intelligent, transparent et securise.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AppCard(child: StorageMeter(storage: provider.storage)),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.schedule_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text('Dernier scan: $lastScan')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
              if (context.mounted) {
                onOpenResults();
              }
            },
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Lancer l\'analyse'),
          ),
          const SizedBox(height: 16),
          CategorySummaryCard(
            title: 'Gros fichiers',
            icon: Icons.sd_storage_outlined,
            count: provider.categoryCount(FileCategory.large),
            onTap: onOpenResults,
          ),
          const SizedBox(height: 10),
          CategorySummaryCard(
            title: 'Doublons',
            icon: Icons.copy_all_outlined,
            count: provider.duplicateGroups.length,
            onTap: onOpenDuplicates,
          ),
          const SizedBox(height: 10),
          CategorySummaryCard(
            title: 'APK',
            icon: Icons.android_outlined,
            count: provider.categoryCount(FileCategory.apk),
            onTap: onOpenResults,
          ),
          const SizedBox(height: 10),
          CategorySummaryCard(
            title: 'Archives',
            icon: Icons.archive_outlined,
            count: provider.categoryCount(FileCategory.archive),
            onTap: onOpenResults,
          ),
          const SizedBox(height: 10),
          CategorySummaryCard(
            title: 'Videos',
            icon: Icons.video_file_outlined,
            count: provider.categoryCount(FileCategory.video),
            onTap: onOpenResults,
          ),
        ],
      ),
    );
  }
}
