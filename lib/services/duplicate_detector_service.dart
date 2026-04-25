import '../models/duplicate_group.dart';
import '../models/scan_file_item.dart';

class DuplicateDetectorService {
  List<DuplicateGroup> detect(List<ScanFileItem> files) {
    final map = <String, List<ScanFileItem>>{};

    for (final file in files) {
      final signature = file.signature;
      if (signature == null || signature.isEmpty) {
        continue;
      }
      map.putIfAbsent(signature, () => []).add(file);
    }

    final groups = <DuplicateGroup>[];
    var index = 0;
    for (final entry in map.entries) {
      if (entry.value.length < 2) {
        continue;
      }
      groups.add(
        DuplicateGroup(
          id: 'group_${index++}',
          signature: entry.key,
          items: entry.value,
        ),
      );
    }

    return groups;
  }
}
