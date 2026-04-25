enum FileCategory { large, duplicate, apk, archive, video, photo, other }

extension FileCategoryX on FileCategory {
  String get label {
    switch (this) {
      case FileCategory.large:
        return 'Gros fichiers';
      case FileCategory.duplicate:
        return 'Doublons';
      case FileCategory.apk:
        return 'APK';
      case FileCategory.archive:
        return 'Archives';
      case FileCategory.video:
        return 'Videos';
      case FileCategory.photo:
        return 'Photos';
      case FileCategory.other:
        return 'Autres';
    }
  }
}
