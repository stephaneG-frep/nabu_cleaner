import 'package:flutter/material.dart';

import '../models/duplicate_group.dart';
import '../models/file_category.dart';
import '../models/history_entry.dart';
import '../models/scan_file_item.dart';
import '../models/scan_report.dart';
import '../models/storage_overview.dart';
import '../services/duplicate_detector_service.dart';
import '../services/export_service.dart';
import '../services/file_delete_service.dart';
import '../services/history_service.dart';
import '../services/permission_service.dart';
import '../services/storage_scan_service.dart';

class CleanerProvider extends ChangeNotifier {
  CleanerProvider({
    required StorageScanService storageScanService,
    required FileDeleteService fileDeleteService,
    required DuplicateDetectorService duplicateDetectorService,
    required HistoryService historyService,
    required ExportService exportService,
    required PermissionService permissionService,
  }) : _storageScanService = storageScanService,
       _fileDeleteService = fileDeleteService,
       _duplicateDetectorService = duplicateDetectorService,
       _historyService = historyService,
       _exportService = exportService,
       _permissionService = permissionService;

  final StorageScanService _storageScanService;
  final FileDeleteService _fileDeleteService;
  final DuplicateDetectorService _duplicateDetectorService;
  final HistoryService _historyService;
  final ExportService _exportService;
  final PermissionService _permissionService;

  bool isInitializing = true;
  bool isScanning = false;
  double scanProgress = 0;
  String scanMessage = 'Pret a analyser';
  bool safeModeEnabled = true;
  bool realScanEnabled = true;
  bool darkThemeEnabled = false;

  DateTime? lastScanAt;
  String? lastScanWarning;
  StorageOverview storage = const StorageOverview(totalBytes: 0, usedBytes: 0);

  final List<ScanFileItem> _results = [];
  final Map<String, bool> _selectedResultIds = {};
  final List<HistoryEntry> _history = [];
  List<DuplicateGroup> _duplicateGroups = [];

  List<ScanFileItem> get results => List.unmodifiable(_results);
  List<HistoryEntry> get history => List.unmodifiable(_history);
  List<DuplicateGroup> get duplicateGroups =>
      List.unmodifiable(_duplicateGroups);
  List<ScanFileItem> get recommendedItems =>
      _results.where(isRecommendedDelete).toList(growable: false);

  int get selectedCount => _selectedResultIds.values.where((it) => it).length;
  int get recommendedCount => recommendedItems.length;
  int get recommendedBytes =>
      recommendedItems.fold(0, (sum, item) => sum + item.sizeBytes);

  int get selectedBytes {
    return _results
        .where((file) => _selectedResultIds[file.id] == true)
        .fold(0, (sum, item) => sum + item.sizeBytes);
  }

  int categoryCount(FileCategory category) {
    return _results.where((item) => item.category == category).length;
  }

  Future<void> initialize() async {
    _history
      ..clear()
      ..addAll(_historyService.getEntries());
    darkThemeEnabled = _historyService.isDarkThemeEnabled();
    isInitializing = false;
    notifyListeners();
  }

  Future<void> runScan() async {
    isScanning = true;
    lastScanWarning = null;
    scanProgress = 0;
    scanMessage = 'Preparation du scan...';
    notifyListeners();

    try {
      final report = await _scanWithPreferredMode();
      _results
        ..clear()
        ..addAll(report.files);

      _selectedResultIds.clear();
      if (report.storage.totalBytes > 0) {
        storage = report.storage;
      }
      lastScanAt = DateTime.now();
      _rebuildDuplicates();
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  Future<String> exportHistoryCsv() async {
    return _exportService.exportHistoryCsv(_history);
  }

  Future<String> exportReportJson() async {
    return _exportService.exportReportJson(
      lastScanAt: lastScanAt,
      storage: storage,
      results: _results,
      history: _history,
    );
  }

  void setSafeMode(bool value) {
    safeModeEnabled = value;
    notifyListeners();
  }

  void setRealScanEnabled(bool value) {
    realScanEnabled = value;
    notifyListeners();
  }

  Future<void> setDarkThemeEnabled(bool value) async {
    darkThemeEnabled = value;
    notifyListeners();
    await _historyService.setDarkThemeEnabled(value);
  }

  void toggleSelection(String fileId, bool selected) {
    _selectedResultIds[fileId] = selected;
    notifyListeners();
  }

  bool isSelected(String fileId) {
    return _selectedResultIds[fileId] == true;
  }

  void clearSelection() {
    _selectedResultIds.clear();
    notifyListeners();
  }

  void selectRecommended() {
    for (final item in recommendedItems) {
      _selectedResultIds[item.id] = true;
    }
    notifyListeners();
  }

  bool isRecommendedDelete(ScanFileItem item) {
    final ageDays = DateTime.now().difference(item.modifiedAt).inDays;
    switch (item.category) {
      case FileCategory.duplicate:
        return true;
      case FileCategory.apk:
        return ageDays >= 7;
      case FileCategory.archive:
        return ageDays >= 14;
      case FileCategory.large:
        return item.sizeBytes >= 200 * 1024 * 1024 || ageDays >= 30;
      case FileCategory.video:
        return item.sizeBytes >= 500 * 1024 * 1024 && ageDays >= 30;
      case FileCategory.photo:
      case FileCategory.other:
        return false;
    }
  }

  Future<DeleteOperationResult> deleteSelected() async {
    final toDelete = _results
        .where((f) => _selectedResultIds[f.id] == true)
        .toList();
    final result = await _fileDeleteService.deleteSelected(
      files: toDelete,
      safeMode: safeModeEnabled,
    );

    _results.removeWhere((file) => result.deleted.any((d) => d.id == file.id));

    _selectedResultIds.clear();
    _rebuildDuplicates();

    if (result.deleted.isNotEmpty) {
      final entry = HistoryEntry(
        date: DateTime.now(),
        deletedCount: result.deleted.length,
        releasedBytes: result.releasedBytes,
      );
      _history.insert(0, entry);
      await _historyService.add(entry);
    }

    notifyListeners();
    return result;
  }

  Future<DeleteOperationResult> deleteDuplicateGroup({
    required DuplicateGroup group,
    required String keepFileId,
  }) async {
    final toDelete = group.items
        .where((item) => item.id != keepFileId)
        .toList();

    final result = await _fileDeleteService.deleteSelected(
      files: toDelete,
      safeMode: safeModeEnabled,
    );

    _results.removeWhere((file) => result.deleted.any((d) => d.id == file.id));
    _selectedResultIds.clear();
    _rebuildDuplicates();

    if (result.deleted.isNotEmpty) {
      final entry = HistoryEntry(
        date: DateTime.now(),
        deletedCount: result.deleted.length,
        releasedBytes: result.releasedBytes,
      );
      _history.insert(0, entry);
      await _historyService.add(entry);
    }

    notifyListeners();
    return result;
  }

  void _rebuildDuplicates() {
    _duplicateGroups = _duplicateDetectorService.detect(_results);
  }

  Future<ScanReport> _scanWithPreferredMode() async {
    if (!realScanEnabled) {
      return _storageScanService.runSimulatedScan(
        onProgress: (progress, message) {
          scanProgress = progress;
          scanMessage = message;
          notifyListeners();
        },
      );
    }

    try {
      return await _storageScanService.runRealScan(
        permissionService: _permissionService,
        onProgress: (progress, message) {
          scanProgress = progress;
          scanMessage = message;
          notifyListeners();
        },
      );
    } catch (e) {
      lastScanWarning = 'Scan reel indisponible: $e. Bascule en mode simule.';
      final simulated = await _storageScanService.runSimulatedScan(
        onProgress: (progress, message) {
          scanProgress = progress;
          scanMessage = '$message (mode simule)';
          notifyListeners();
        },
      );
      return simulated;
    }
  }
}
