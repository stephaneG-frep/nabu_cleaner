import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/file_category.dart';
import '../models/scan_file_item.dart';
import '../models/scan_report.dart';
import '../models/storage_overview.dart';
import 'permission_service.dart';

class StorageScanService {
  static const MethodChannel _storageChannel = MethodChannel(
    'nabu_cleaner/storage',
  );

  static const List<String> progressMessages = [
    'Verification des permissions de stockage...',
    'Analyse des dossiers utilisateurs accessibles...',
    'Recherche des fichiers volumineux...',
    'Identification des APK et archives...',
    'Detection des doublons potentiels...',
    'Finalisation du rapport de nettoyage...',
  ];

  static const int _largeFileThresholdBytes = 150 * 1024 * 1024;
  static const int _minDuplicateCandidateBytes = 1 * 1024 * 1024;
  static const int _maxFilesToInspect = 5000;

  static const Set<String> _apkExtensions = {'apk'};
  static const Set<String> _archiveExtensions = {
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
    'bz2',
    'xz',
    'tgz',
  };
  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'mkv',
    'avi',
    'webm',
    'm4v',
    '3gp',
  };
  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'heic',
    'webp',
    'bmp',
    'gif',
  };

  static const List<String> _blockedPrefixes = [
    '/system',
    '/vendor',
    '/proc',
    '/data/system',
  ];

  static const List<String> _blockedPathFragments = [
    '/Android/data/',
    '/Android/obb/',
    '/.thumbnails/',
    '/cache/',
  ];

  Future<ScanReport> runSimulatedScan({
    required void Function(double progress, String message) onProgress,
  }) async {
    for (var i = 0; i < progressMessages.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      onProgress((i + 1) / progressMessages.length, progressMessages[i]);
    }

    final now = DateTime.now();
    final files = <ScanFileItem>[
      ScanFileItem(
        id: 'f1',
        path: '/storage/emulated/0/Download/video_4k_trip.mp4',
        name: 'video_4k_trip.mp4',
        sizeBytes: 812 * 1024 * 1024,
        category: FileCategory.video,
        modifiedAt: now.subtract(const Duration(days: 3)),
      ),
      ScanFileItem(
        id: 'f2',
        path: '/storage/emulated/0/Movies/family_archive.mov',
        name: 'family_archive.mov',
        sizeBytes: 1200 * 1024 * 1024,
        category: FileCategory.large,
        modifiedAt: now.subtract(const Duration(days: 19)),
      ),
      ScanFileItem(
        id: 'f3',
        path: '/storage/emulated/0/Download/app_beta.apk',
        name: 'app_beta.apk',
        sizeBytes: 118 * 1024 * 1024,
        category: FileCategory.apk,
        modifiedAt: now.subtract(const Duration(days: 40)),
      ),
      ScanFileItem(
        id: 'f4',
        path: '/storage/emulated/0/Download/old_suite.apk',
        name: 'old_suite.apk',
        sizeBytes: 88 * 1024 * 1024,
        category: FileCategory.apk,
        modifiedAt: now.subtract(const Duration(days: 70)),
      ),
      ScanFileItem(
        id: 'f5',
        path: '/storage/emulated/0/Documents/photos_backup_2024.zip',
        name: 'photos_backup_2024.zip',
        sizeBytes: 640 * 1024 * 1024,
        category: FileCategory.archive,
        modifiedAt: now.subtract(const Duration(days: 12)),
      ),
      ScanFileItem(
        id: 'f6',
        path: '/storage/emulated/0/Documents/server_dump.tar.gz',
        name: 'server_dump.tar.gz',
        sizeBytes: 460 * 1024 * 1024,
        category: FileCategory.archive,
        modifiedAt: now.subtract(const Duration(days: 93)),
      ),
      ScanFileItem(
        id: 'f7',
        path: '/storage/emulated/0/DCIM/Camera/IMG_3801.jpg',
        name: 'IMG_3801.jpg',
        sizeBytes: 8 * 1024 * 1024,
        category: FileCategory.photo,
        modifiedAt: now.subtract(const Duration(days: 5)),
        signature: 'dup_img_01',
      ),
      ScanFileItem(
        id: 'f8',
        path: '/storage/emulated/0/Pictures/IMG_3801_copy.jpg',
        name: 'IMG_3801_copy.jpg',
        sizeBytes: 8 * 1024 * 1024,
        category: FileCategory.duplicate,
        modifiedAt: now.subtract(const Duration(days: 4)),
        signature: 'dup_img_01',
      ),
      ScanFileItem(
        id: 'f9',
        path: '/storage/emulated/0/WhatsApp/Media/video_meeting.mp4',
        name: 'video_meeting.mp4',
        sizeBytes: 190 * 1024 * 1024,
        category: FileCategory.video,
        modifiedAt: now.subtract(const Duration(days: 30)),
        signature: 'dup_vid_09',
      ),
      ScanFileItem(
        id: 'f10',
        path: '/storage/emulated/0/Telegram/video_meeting_copy.mp4',
        name: 'video_meeting_copy.mp4',
        sizeBytes: 190 * 1024 * 1024,
        category: FileCategory.duplicate,
        modifiedAt: now.subtract(const Duration(days: 29)),
        signature: 'dup_vid_09',
      ),
      ScanFileItem(
        id: 'f11',
        path: '/storage/emulated/0/Download/tutorial_bundle.rar',
        name: 'tutorial_bundle.rar',
        sizeBytes: 302 * 1024 * 1024,
        category: FileCategory.archive,
        modifiedAt: now.subtract(const Duration(days: 112)),
      ),
      ScanFileItem(
        id: 'f12',
        path: '/storage/emulated/0/Movies/screen_recording_2025_02.mp4',
        name: 'screen_recording_2025_02.mp4',
        sizeBytes: 380 * 1024 * 1024,
        category: FileCategory.video,
        modifiedAt: now.subtract(const Duration(days: 60)),
      ),
    ];

    return ScanReport(
      storage: const StorageOverview(
        totalBytes: 256 * 1024 * 1024 * 1024,
        usedBytes: 198 * 1024 * 1024 * 1024,
      ),
      files: files,
    );
  }

  Future<ScanReport> runRealScan({
    required PermissionService permissionService,
    required void Function(double progress, String message) onProgress,
  }) async {
    onProgress(0.05, 'Verification des permissions de stockage...');
    final hasPermission = await permissionService.ensureAccessForScan();
    if (!hasPermission) {
      throw StateError(
        'Permission media non accordee. Autorisez Photos/Videos '
        'dans les permissions Android de Nabu Cleaner.',
      );
    }

    onProgress(0.12, 'Preparation des dossiers utilisateur accessibles...');
    final roots = await _discoverRoots();
    if (roots.isEmpty) {
      throw StateError('Aucun dossier utilisateur accessible pour le scan.');
    }

    final provisional = <ScanFileItem>[];
    var inspectedCount = 0;
    var id = 0;

    for (var rootIndex = 0; rootIndex < roots.length; rootIndex++) {
      final root = roots[rootIndex];
      final pendingDirectories = <Directory>[root];

      while (pendingDirectories.isNotEmpty &&
          inspectedCount < _maxFilesToInspect) {
        final dir = pendingDirectories.removeLast();
        List<FileSystemEntity> entities;
        try {
          entities = dir.listSync(followLinks: false);
        } catch (_) {
          continue;
        }

        for (final entity in entities) {
          if (entity is Directory) {
            if (_shouldSkipPath(entity.path)) {
              continue;
            }
            pendingDirectories.add(entity);
            continue;
          }

          if (entity is! File || _shouldSkipPath(entity.path)) {
            continue;
          }

          inspectedCount++;
          if (inspectedCount % 60 == 0) {
            final baseProgress = 0.15 + (rootIndex / roots.length) * 0.55;
            final fileProgress = (inspectedCount / _maxFilesToInspect) * 0.25;
            final progress = (baseProgress + fileProgress)
                .clamp(0.15, 0.85)
                .toDouble();
            onProgress(
              progress,
              'Analyse des fichiers accessibles... ($inspectedCount)'
                  .toString(),
            );
          }

          FileStat stat;
          try {
            stat = entity.statSync();
          } catch (_) {
            continue;
          }
          if (stat.type != FileSystemEntityType.file || stat.size <= 0) {
            continue;
          }

          final category = _categoryFromPath(entity.path, stat.size);
          final signature = await _buildPotentialDuplicateSignature(
            file: entity,
            sizeBytes: stat.size,
            extension: _extensionOf(entity.path),
          );

          // We keep meaningful categories immediately, and keep potential duplicates
          // as "other" until we verify they really have at least one pair.
          if (category == FileCategory.other && signature == null) {
            continue;
          }

          provisional.add(
            ScanFileItem(
              id: 'real_${id++}',
              path: entity.path,
              name: _nameOf(entity.path),
              sizeBytes: stat.size,
              category: category,
              modifiedAt: stat.modified,
              signature: signature,
            ),
          );
        }
      }

      if (inspectedCount >= _maxFilesToInspect) {
        break;
      }
    }

    onProgress(0.9, 'Validation des doublons potentiels...');
    final duplicateSignatures = _duplicateSignatureSet(provisional);

    final files = provisional
        .where(
          (item) =>
              item.category != FileCategory.other ||
              duplicateSignatures.contains(item.signature),
        )
        .map((item) {
          if (item.category == FileCategory.other &&
              duplicateSignatures.contains(item.signature)) {
            return ScanFileItem(
              id: item.id,
              path: item.path,
              name: item.name,
              sizeBytes: item.sizeBytes,
              category: FileCategory.duplicate,
              modifiedAt: item.modifiedAt,
              signature: item.signature,
            );
          }
          return item;
        })
        .toList();

    files.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    final scannedBytes = files.fold<int>(
      0,
      (sum, item) => sum + item.sizeBytes,
    );
    final storageOverview = await _readDeviceStorageOverview(scannedBytes);

    onProgress(1, 'Scan termine. ${files.length} fichier(s) identifies.');
    return ScanReport(storage: storageOverview, files: files);
  }

  Future<StorageOverview> _readDeviceStorageOverview(int scannedBytes) async {
    try {
      final raw = await _storageChannel.invokeMapMethod<String, dynamic>(
        'getStorageOverview',
      );
      if (raw == null) {
        return _fallbackStorageOverview(scannedBytes);
      }

      final total = (raw['totalBytes'] as num?)?.toInt() ?? 0;
      final used = (raw['usedBytes'] as num?)?.toInt() ?? 0;
      if (total <= 0 || used < 0 || used > total) {
        return _fallbackStorageOverview(scannedBytes);
      }

      return StorageOverview(totalBytes: total, usedBytes: used);
    } catch (_) {
      return _fallbackStorageOverview(scannedBytes);
    }
  }

  StorageOverview _fallbackStorageOverview(int scannedBytes) {
    final total = 256 * 1024 * 1024 * 1024;
    final used = (scannedBytes * 1.1).toInt().clamp(
      0,
      total - (1024 * 1024 * 1024),
    );
    return StorageOverview(totalBytes: total, usedBytes: used);
  }

  Future<List<Directory>> _discoverRoots() async {
    final roots = <String>{'/storage/emulated/0', '/sdcard'};

    final appExternal = await getExternalStorageDirectory();
    if (appExternal != null) {
      roots.add(appExternal.path);
      final idx = appExternal.path.indexOf('/Android/');
      if (idx > 0) {
        roots.add(appExternal.path.substring(0, idx));
      }
    }

    final externalDirs = await getExternalStorageDirectories();
    if (externalDirs != null) {
      for (final dir in externalDirs) {
        roots.add(dir.path);
        final idx = dir.path.indexOf('/Android/');
        if (idx > 0) {
          roots.add(dir.path.substring(0, idx));
        }
      }
    }

    return roots.map(Directory.new).where((dir) {
      try {
        return dir.existsSync() && !_shouldSkipPath(dir.path);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Set<String> _duplicateSignatureSet(List<ScanFileItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final sig = item.signature;
      if (sig == null || sig.isEmpty) continue;
      counts[sig] = (counts[sig] ?? 0) + 1;
    }

    return counts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toSet();
  }

  Future<String?> _buildPotentialDuplicateSignature({
    required File file,
    required int sizeBytes,
    required String extension,
  }) async {
    if (sizeBytes < _minDuplicateCandidateBytes) {
      return null;
    }

    try {
      final firstChunk = await file
          .openRead(0, 64 * 1024)
          .fold<List<int>>(<int>[], (buffer, data) => buffer..addAll(data));
      final digest = sha1.convert(firstChunk).toString();
      return '$sizeBytes:$extension:$digest';
    } catch (_) {
      return null;
    }
  }

  FileCategory _categoryFromPath(String path, int sizeBytes) {
    final ext = _extensionOf(path);
    if (_apkExtensions.contains(ext)) {
      return FileCategory.apk;
    }
    if (_archiveExtensions.contains(ext)) {
      return FileCategory.archive;
    }
    if (_videoExtensions.contains(ext)) {
      return FileCategory.video;
    }
    if (_imageExtensions.contains(ext)) {
      return FileCategory.photo;
    }
    if (sizeBytes >= _largeFileThresholdBytes) {
      return FileCategory.large;
    }
    return FileCategory.other;
  }

  String _extensionOf(String path) {
    final name = _nameOf(path);
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot >= name.length - 1) {
      return '';
    }
    return name.substring(dot + 1).toLowerCase();
  }

  String _nameOf(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  bool _shouldSkipPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    if (_blockedPrefixes.any(normalized.startsWith)) {
      return true;
    }
    return _blockedPathFragments.any(normalized.contains);
  }
}
