import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/duplicate_group.dart';
import '../providers/cleaner_provider.dart';

class DuplicatesScreen extends StatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen> {
  final Map<String, String> _keepByGroup = {};

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

  Future<bool> _confirm(BuildContext context, DuplicateGroup group) async {
    final deleteCount = group.items.length - 1;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le nettoyage des doublons'),
        content: Text(
          'Vous allez garder 1 fichier et supprimer $deleteCount doublon(s) dans ce groupe. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Doublons potentiels')),
      body: provider.duplicateGroups.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun doublon detecte pour le moment.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final group = provider.duplicateGroups[index];
                final keepId = _keepByGroup[group.id] ?? group.items.first.id;

                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Groupe ${index + 1} • ${group.items.length} fichiers • ${_formatBytes(group.totalBytes)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        RadioGroup<String>(
                          groupValue: keepId,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _keepByGroup[group.id] = value;
                            });
                          },
                          child: Column(
                            children: group.items
                                .map(
                                  (item) => RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item.name),
                                    subtitle: Text(
                                      item.path,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    value: item.id,
                                    secondary: const Text('Conserver'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: () async {
                              final confirmed = await _confirm(context, group);
                              if (!confirmed || !context.mounted) return;

                              final keep =
                                  _keepByGroup[group.id] ??
                                  group.items.first.id;
                              final result = await context
                                  .read<CleanerProvider>()
                                  .deleteDuplicateGroup(
                                    group: group,
                                    keepFileId: keep,
                                  );

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${result.deleted.length} doublon(s) supprime(s), '
                                    '${_formatBytes(result.releasedBytes)} liberes.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.auto_delete_outlined),
                            label: const Text('Supprimer les autres'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: provider.duplicateGroups.length,
            ),
    );
  }
}
