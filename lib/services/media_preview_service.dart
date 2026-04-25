import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import 'dart:io';

class MediaPreviewService {
  MediaPreviewService._();

  static final MediaPreviewService instance = MediaPreviewService._();

  static const MethodChannel _channel = MethodChannel('nabu_cleaner/media');
  static const int _maxCacheEntries = 220;

  final Map<String, Uint8List?> _memoryCache = <String, Uint8List?>{};
  final Map<String, Future<Uint8List?>> _inflight =
      <String, Future<Uint8List?>>{};
  Directory? _cacheDir;

  Future<Uint8List?> getVideoThumbnail({
    required String path,
    int maxWidth = 140,
  }) async {
    final cacheKey = '$path|$maxWidth';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    final running = _inflight[cacheKey];
    if (running != null) {
      return running;
    }

    final task = _fetchOrLoadThumbnail(
      cacheKey: cacheKey,
      path: path,
      maxWidth: maxWidth,
    );
    _inflight[cacheKey] = task;
    final bytes = await task;
    _inflight.remove(cacheKey);

    _memoryCache[cacheKey] = bytes;
    _trimCacheIfNeeded();
    return bytes;
  }

  Future<Uint8List?> _fetchOrLoadThumbnail({
    required String cacheKey,
    required String path,
    required int maxWidth,
  }) async {
    final file = await _thumbnailCacheFile(cacheKey);
    if (file.existsSync()) {
      try {
        return await file.readAsBytes();
      } catch (_) {
        // Fall through to regenerate
      }
    }

    final bytes = await _fetchThumbnail(path: path, maxWidth: maxWidth);
    if (bytes == null) {
      return null;
    }

    try {
      await file.writeAsBytes(bytes, flush: false);
    } catch (_) {
      // Non blocking: keep memory cache only.
    }
    return bytes;
  }

  Future<Uint8List?> _fetchThumbnail({
    required String path,
    required int maxWidth,
  }) async {
    try {
      return await _channel.invokeMethod<Uint8List>('getVideoThumbnail', {
        'path': path,
        'maxWidth': maxWidth,
      });
    } on PlatformException {
      return null;
    }
  }

  void _trimCacheIfNeeded() {
    while (_memoryCache.length > _maxCacheEntries) {
      final firstKey = _memoryCache.keys.first;
      _memoryCache.remove(firstKey);
    }
  }

  Future<File> _thumbnailCacheFile(String cacheKey) async {
    _cacheDir ??= await _ensureCacheDirectory();
    final hashed = md5.convert(cacheKey.codeUnits).toString();
    return File('${_cacheDir!.path}/thumb_$hashed.jpg');
  }

  Future<Directory> _ensureCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/nabu_thumbs');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
