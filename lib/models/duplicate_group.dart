import 'scan_file_item.dart';

class DuplicateGroup {
  const DuplicateGroup({
    required this.id,
    required this.signature,
    required this.items,
  });

  final String id;
  final String signature;
  final List<ScanFileItem> items;

  int get totalBytes => items.fold(0, (sum, item) => sum + item.sizeBytes);
}
