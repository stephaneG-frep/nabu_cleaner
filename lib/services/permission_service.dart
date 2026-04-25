import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<int?> _androidSdkInt() async {
    if (!Platform.isAndroid) {
      return null;
    }

    final android = await DeviceInfoPlugin().androidInfo;
    return android.version.sdkInt;
  }

  Future<List<Permission>> requiredPermissions() async {
    final sdk = await _androidSdkInt();
    if (sdk == null) {
      return const [];
    }

    if (sdk <= 32) {
      return const [Permission.storage];
    }

    return const [Permission.photos, Permission.videos, Permission.audio];
  }

  Future<bool> isManageAllFilesSupported() async {
    final sdk = await _androidSdkInt();
    return sdk != null && sdk >= 30;
  }

  Future<bool> hasManageAllFilesAccess() async {
    final supported = await isManageAllFilesSupported();
    if (!supported) {
      return true;
    }
    return Permission.manageExternalStorage.status.then((s) => s.isGranted);
  }

  Future<bool> requestManageAllFilesAccess() async {
    final supported = await isManageAllFilesSupported();
    if (!supported) {
      return true;
    }
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<Map<Permission, PermissionStatus>> checkStatuses() async {
    final required = await requiredPermissions();
    final statuses = <Permission, PermissionStatus>{};

    for (final permission in required) {
      statuses[permission] = await permission.status;
    }

    return statuses;
  }

  Future<Map<Permission, PermissionStatus>> requestRequired() async {
    final required = await requiredPermissions();
    if (required.isEmpty) {
      return {};
    }

    return required.request();
  }

  Future<bool> hasAtLeastOneGranted() async {
    final statuses = await checkStatuses();
    if (statuses.isEmpty) {
      return true;
    }

    return statuses.values.any(
      (status) => status.isGranted || status.isLimited,
    );
  }

  Future<bool> ensureAccessForScan() async {
    if (await hasAtLeastOneGranted()) {
      return true;
    }

    final requested = await requestRequired();
    if (requested.isEmpty) {
      return hasAtLeastOneGranted();
    }

    return requested.values.any(
      (status) => status.isGranted || status.isLimited,
    );
  }

  Future<bool> hasPermanentlyDeniedPermission() async {
    final statuses = await checkStatuses();
    return statuses.values.any((status) => status.isPermanentlyDenied);
  }
}
