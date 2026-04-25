import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/cleaner_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${NumberFormat('0.#', 'fr_FR').format(value)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des nettoyages'),
        actions: [
          IconButton(
            tooltip: 'Exporter CSV',
            onPressed: () async {
              final path = await context
                  .read<CleanerProvider>()
                  .exportHistoryCsv();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('CSV exporte: $path')));
            },
            icon: const Icon(Icons.table_chart_outlined),
          ),
          IconButton(
            tooltip: 'Exporter JSON',
            onPressed: () async {
              final path = await context
                  .read<CleanerProvider>()
                  .exportReportJson();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('JSON exporte: $path')));
            },
            icon: const Icon(Icons.data_object_outlined),
          ),
        ],
      ),
      body: provider.history.isEmpty
          ? const Center(child: Text('Aucune action de nettoyage enregistree.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = provider.history[index];
                final date = DateFormat(
                  'dd/MM/yyyy HH:mm',
                  'fr_FR',
                ).format(item.date);
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.history_toggle_off),
                    title: Text(date),
                    subtitle: Text(
                      '${item.deletedCount} fichier(s) supprime(s) • ${_formatBytes(item.releasedBytes)} liberes',
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: provider.history.length,
            ),
    );
  }
}
