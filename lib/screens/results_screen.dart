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
  static const int _pageSize = 60;

  FileCategory? _categoryFilter;
  bool _showRecommendedOnly = false;
  ResultsSort _sort = ResultsSort.sizeDesc;
  late final ScrollController _scrollController;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

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
    final provider = context.read<CleanerProvider>();
    final filtered = source
        .where(
          (item) =>
              (_categoryFilter == null || item.category == _categoryFilter) &&
              (!_showRecommendedOnly || provider.isRecommendedDelete(item)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFF2F7FF)
        : const Color(0xFF111827);
    final contentColor = isDark
        ? const Color(0xFFE3EEFF)
        : const Color(0xFF374151);
    final cancelColor = isDark
        ? const Color(0xFFBDEEFF)
        : Theme.of(context).colorScheme.primary;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        titleTextStyle: TextStyle(
          color: titleColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: contentColor, fontSize: 15),
        title: const Text('Confirmation requise'),
        content: Text(
          'Vous allez supprimer $count element(s) selectionne(s). '
          'Cette action est irreversible. Continuer ?',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: cancelColor),
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

  void _resetPagination() {
    setState(() {
      _visibleCount = _pageSize;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 280) return;
    setState(() {
      _visibleCount += _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanerProvider>();
    final visibleItems = _applyFilterAndSort(provider.results);
    final pagedItems = visibleItems.take(_visibleCount).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultats'),
        actions: [
          PopupMenuButton<ResultsSort>(
            initialValue: _sort,
            onSelected: (value) {
              _sort = value;
              _resetPagination();
            },
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
                          label: const Text('Recommandes'),
                          selected: _showRecommendedOnly,
                          onSelected: (value) {
                            _showRecommendedOnly = value;
                            _resetPagination();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Tout'),
                          selected: _categoryFilter == null,
                          onSelected: (_) {
                            _categoryFilter = null;
                            _resetPagination();
                          },
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
                                onSelected: (_) {
                                  _categoryFilter = category;
                                  _resetPagination();
                                },
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recommandes: ${provider.recommendedCount} fichier(s) • ${_formatBytes(provider.recommendedBytes)}',
                        ),
                      ),
                      TextButton(
                        onPressed: provider.recommendedCount == 0
                            ? null
                            : () => context
                                  .read<CleanerProvider>()
                                  .selectRecommended(),
                        child: const Text('Tout selectionner'),
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
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          itemBuilder: (context, index) {
                            final item = pagedItems[index];
                            return FileResultTile(
                              item: item,
                              selected: provider.isSelected(item.id),
                              recommended: provider.isRecommendedDelete(item),
                              onChanged: (value) =>
                                  provider.toggleSelection(item.id, value),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemCount: pagedItems.length,
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
                                      '${_formatBytes(result.releasedBytes)} liberes. '
                                      '${result.skipped.isNotEmpty ? '${result.skipped.length} ignore(s) (acces refuse/protege).' : ''}',
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
