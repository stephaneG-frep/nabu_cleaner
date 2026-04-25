import 'package:hive/hive.dart';

import '../models/history_entry.dart';

class HistoryService {
  static const String _boxName = 'history';

  Box get _box => Hive.box(_boxName);

  Future<void> add(HistoryEntry entry) async {
    final raw = _box.get('entries', defaultValue: <dynamic>[]) as List<dynamic>;
    raw.insert(0, entry.toMap());
    await _box.put('entries', raw.take(200).toList());
  }

  List<HistoryEntry> getEntries() {
    final raw = _box.get('entries', defaultValue: <dynamic>[]) as List<dynamic>;
    return raw
        .map(
          (item) =>
              HistoryEntry.fromMap(Map<dynamic, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
