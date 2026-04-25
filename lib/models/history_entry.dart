class HistoryEntry {
  const HistoryEntry({
    required this.date,
    required this.deletedCount,
    required this.releasedBytes,
  });

  final DateTime date;
  final int deletedCount;
  final int releasedBytes;

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'deletedCount': deletedCount,
      'releasedBytes': releasedBytes,
    };
  }

  factory HistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return HistoryEntry(
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      deletedCount: map['deletedCount'] as int? ?? 0,
      releasedBytes: map['releasedBytes'] as int? ?? 0,
    );
  }
}
