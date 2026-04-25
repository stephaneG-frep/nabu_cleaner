import 'scan_file_item.dart';
import 'storage_overview.dart';

class ScanReport {
  const ScanReport({required this.storage, required this.files});

  final StorageOverview storage;
  final List<ScanFileItem> files;
}
