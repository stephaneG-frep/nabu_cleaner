import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/history_entry.dart';
import '../models/scan_file_item.dart';
import '../models/storage_overview.dart';

class ExportService {
  Future<String> exportHistoryCsv(List<HistoryEntry> history) async {
    final dir = await _ensureExportDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/nabu_history_$stamp.csv');

    final rows = <String>[
      'date,deleted_count,released_bytes',
      ...history.map(
        (entry) =>
            '${entry.date.toIso8601String()},${entry.deletedCount},${entry.releasedBytes}',
      ),
    ];

    await file.writeAsString('${rows.join('\n')}\n');
    return file.path;
  }

  Future<String> exportReportJson({
    required DateTime? lastScanAt,
    required StorageOverview storage,
    required List<ScanFileItem> results,
    required List<HistoryEntry> history,
  }) async {
    final dir = await _ensureExportDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/nabu_report_$stamp.json');

    final payload = {
      'generatedAt': DateTime.now().toIso8601String(),
      'lastScanAt': lastScanAt?.toIso8601String(),
      'storage': {
        'totalBytes': storage.totalBytes,
        'usedBytes': storage.usedBytes,
        'freeBytes': storage.freeBytes,
      },
      'results': results
          .map(
            (item) => {
              'id': item.id,
              'path': item.path,
              'name': item.name,
              'sizeBytes': item.sizeBytes,
              'category': item.category.name,
              'modifiedAt': item.modifiedAt.toIso8601String(),
              'signature': item.signature,
            },
          )
          .toList(),
      'history': history
          .map(
            (entry) => {
              'date': entry.date.toIso8601String(),
              'deletedCount': entry.deletedCount,
              'releasedBytes': entry.releasedBytes,
            },
          )
          .toList(),
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file.path;
  }

  Future<Directory> _ensureExportDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${docs.path}/exports');
    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }
}
