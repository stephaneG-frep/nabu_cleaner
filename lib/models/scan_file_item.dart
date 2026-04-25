import 'file_category.dart';

class ScanFileItem {
  const ScanFileItem({
    required this.id,
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.category,
    required this.modifiedAt,
    this.signature,
    this.isSystemFile = false,
  });

  final String id;
  final String path;
  final String name;
  final int sizeBytes;
  final FileCategory category;
  final DateTime modifiedAt;
  final String? signature;
  final bool isSystemFile;
}
