import 'dart:io';

import 'package:flutter/services.dart';

import '../models/scan_file_item.dart';

class DeleteOperationResult {
  const DeleteOperationResult({
    required this.deleted,
    required this.skipped,
    required this.releasedBytes,
  });

  final List<ScanFileItem> deleted;
  final List<ScanFileItem> skipped;
  final int releasedBytes;
}

class FileDeleteService {
  static const MethodChannel _deleteChannel = MethodChannel(
    'nabu_cleaner/delete',
  );

  static const List<String> _blockedSystemPrefixes = [
    '/system',
    '/vendor',
    '/proc',
    '/data/system',
  ];

  Future<DeleteOperationResult> deleteSelected({
    required List<ScanFileItem> files,
    required bool safeMode,
  }) async {
    final eligible = <ScanFileItem>[];
    final skipped = <ScanFileItem>[];

    for (final file in files) {
      final blockedByPath = _blockedSystemPrefixes.any(
        (prefix) => file.path.startsWith(prefix),
      );
      if (file.isSystemFile || blockedByPath) {
        skipped.add(file);
        continue;
      }

      if (safeMode && file.path.contains('/Android/data/')) {
        skipped.add(file);
        continue;
      }

      eligible.add(file);
    }

    final deleted = <ScanFileItem>[];
    if (eligible.isNotEmpty) {
      final byPath = <String, ScanFileItem>{
        for (final item in eligible) item.path: item,
      };

      try {
        final response = await _deleteChannel.invokeMapMethod<String, dynamic>(
          'deleteFiles',
          {'paths': eligible.map((item) => item.path).toList()},
        );

        final deletedPathsRaw =
            response?['deletedPaths'] as List<dynamic>? ?? const [];
        final skippedPathsRaw =
            response?['skippedPaths'] as List<dynamic>? ?? const [];

        for (final path in deletedPathsRaw.cast<String>()) {
          final item = byPath[path];
          if (item != null) {
            deleted.add(item);
            byPath.remove(path);
          }
        }

        for (final path in skippedPathsRaw.cast<String>()) {
          final item = byPath[path];
          if (item != null) {
            skipped.add(item);
            byPath.remove(path);
          }
        }

        // Any path not explicitly returned is treated as skipped.
        skipped.addAll(byPath.values);
      } on PlatformException {
        await _fallbackDirectDelete(eligible, deleted, skipped);
      }
    }

    final released = deleted.fold<int>(0, (sum, item) => sum + item.sizeBytes);

    return DeleteOperationResult(
      deleted: deleted,
      skipped: skipped,
      releasedBytes: released,
    );
  }

  Future<void> _fallbackDirectDelete(
    List<ScanFileItem> eligible,
    List<ScanFileItem> deleted,
    List<ScanFileItem> skipped,
  ) async {
    for (final file in eligible) {
      try {
        final diskFile = File(file.path);
        if (!diskFile.existsSync()) {
          deleted.add(file);
          continue;
        }

        await diskFile.delete();
        deleted.add(file);
      } catch (_) {
        skipped.add(file);
      }
    }
  }
}
