import 'package:hive/hive.dart';

import '../models/history_entry.dart';

class HistoryService {
  static const String _boxName = 'history';
  static const String _entriesKey = 'entries';
  static const String _darkThemeKey = 'dark_theme';

  Box get _box => Hive.box(_boxName);

  Future<void> add(HistoryEntry entry) async {
    final raw =
        _box.get(_entriesKey, defaultValue: <dynamic>[]) as List<dynamic>;
    raw.insert(0, entry.toMap());
    await _box.put(_entriesKey, raw.take(200).toList());
  }

  List<HistoryEntry> getEntries() {
    final raw =
        _box.get(_entriesKey, defaultValue: <dynamic>[]) as List<dynamic>;
    return raw
        .map(
          (item) =>
              HistoryEntry.fromMap(Map<dynamic, dynamic>.from(item as Map)),
        )
        .toList();
  }

  bool isDarkThemeEnabled() {
    return _box.get(_darkThemeKey, defaultValue: false) as bool;
  }

  Future<void> setDarkThemeEnabled(bool value) async {
    await _box.put(_darkThemeKey, value);
  }
}
