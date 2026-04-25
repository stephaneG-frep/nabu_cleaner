import '../models/scan_file_item.dart';

class DeleteOperationResult {
  const DeleteOperationResult({
    required this.deleted,
    required this.releasedBytes,
  });

  final List<ScanFileItem> deleted;
  final int releasedBytes;
}

class FileDeleteService {
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
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final deleted = <ScanFileItem>[];

    for (final file in files) {
      final blockedByPath = _blockedSystemPrefixes.any(
        (prefix) => file.path.startsWith(prefix),
      );
      if (file.isSystemFile || blockedByPath) {
        continue;
      }

      if (safeMode && file.path.contains('/Android/data/')) {
        continue;
      }

      deleted.add(file);
    }

    final released = deleted.fold<int>(0, (sum, item) => sum + item.sizeBytes);

    return DeleteOperationResult(deleted: deleted, releasedBytes: released);
  }
}
