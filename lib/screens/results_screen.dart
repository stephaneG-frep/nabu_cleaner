import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/file_category.dart';
import '../models/scan_file_item.dart';
import '../providers/cleaner_provider.dart';
import '../widgets/file_result_tile.dart';

enum ResultsSort { sizeDesc, sizeAsc, dateDesc, dateAsc, nameAsc, nameDesc }

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  FileCategory? _categoryFilter;
  ResultsSort _sort = ResultsSort.sizeDesc;

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

  List<ScanFileItem> _applyFilterAndSort(List<ScanFileItem> source) {
    final filtered = source
        .where(
          (item) => _categoryFilter == null || item.category == _categoryFilter,
        )
        .toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case ResultsSort.sizeDesc:
          return b.sizeBytes.compareTo(a.sizeBytes);
        case ResultsSort.sizeAsc:
          return a.sizeBytes.compareTo(b.sizeBytes);
        case ResultsSort.dateDesc:
          return b.modifiedAt.compareTo(a.modifiedAt);
        case ResultsSort.dateAsc:
          return a.modifiedAt.compareTo(b.modifiedAt);
        case ResultsSort.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ResultsSort.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      }
    });

    return filtered;
  }

  Future<bool> _confirmDelete(BuildContext context, int count) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation requise'),
        content: Text(
          'Vous allez supprimer $count element(s) selectionne(s). '
          'Cette action est irreversible. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    return shouldDelete ?? false;
  }

  String _sortLabel(ResultsSort value) {
    switch (value) {
      case ResultsSort.sizeDesc:
        return 'Taille: plus grands';
      case ResultsSort.sizeAsc:
        return 'Taille: plus petits';
      case ResultsSort.dateDesc:
        return 'Date: plus recents';
      case ResultsSort.dateAsc:
        return 'Date: plus anciens';
      case ResultsSort.nameAsc:
        return 'Nom: A-Z';
      case ResultsSort.nameDesc:
        return 'Nom: Z-A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanerProvider>();
    final visibleItems = _applyFilterAndSort(provider.results);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultats'),
        actions: [
          PopupMenuButton<ResultsSort>(
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => ResultsSort.values
                .map(
                  (value) => PopupMenuItem(
                    value: value,
                    child: Text(_sortLabel(value)),
                  ),
                )
                .toList(),
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: provider.results.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun resultat. Lancez une analyse depuis l\'accueil.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Tout'),
                          selected: _categoryFilter == null,
                          onSelected: (_) =>
                              setState(() => _categoryFilter = null),
                        ),
                      ),
                      ...FileCategory.values
                          .where((cat) => cat != FileCategory.other)
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category.label),
                                selected: _categoryFilter == category,
                                onSelected: (_) =>
                                    setState(() => _categoryFilter = category),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                Expanded(
                  child: visibleItems.isEmpty
                      ? const Center(
                          child: Text('Aucun fichier pour ce filtre.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          itemBuilder: (context, index) {
                            final item = visibleItems[index];
                            return FileResultTile(
                              item: item,
                              selected: provider.isSelected(item.id),
                              onChanged: (value) =>
                                  provider.toggleSelection(item.id, value),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemCount: visibleItems.length,
                        ),
                ),
              ],
            ),
      bottomSheet: provider.results.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${provider.selectedCount} selection(s) • ${_formatBytes(provider.selectedBytes)}',
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: provider.selectedCount == 0
                            ? null
                            : () async {
                                final confirmed = await _confirmDelete(
                                  context,
                                  provider.selectedCount,
                                );
                                if (!confirmed || !context.mounted) return;

                                final result = await context
                                    .read<CleanerProvider>()
                                    .deleteSelected();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${result.deleted.length} element(s) supprime(s), '
                                      '${_formatBytes(result.releasedBytes)} liberes.',
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer la selection'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
