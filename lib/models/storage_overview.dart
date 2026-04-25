class StorageOverview {
  const StorageOverview({required this.totalBytes, required this.usedBytes});

  final int totalBytes;
  final int usedBytes;

  int get freeBytes => totalBytes - usedBytes;
  double get usedRatio => totalBytes == 0 ? 0 : usedBytes / totalBytes;
}
