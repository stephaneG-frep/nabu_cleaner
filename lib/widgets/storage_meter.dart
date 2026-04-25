import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/storage_overview.dart';

class StorageMeter extends StatelessWidget {
  const StorageMeter({super.key, required this.storage});

  final StorageOverview storage;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final formatted = NumberFormat('#,##0.#', 'fr_FR').format(value);
    return '$formatted ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = storage.usedRatio.clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stockage appareil',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: ratio, minHeight: 10),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Text('Utilise: ${_formatBytes(storage.usedBytes)}'),
            Text('Libre: ${_formatBytes(storage.freeBytes)}'),
          ],
        ),
      ],
    );
  }
}
