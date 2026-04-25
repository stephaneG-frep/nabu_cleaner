# Android Release - Nabu Cleaner

## 1) Configure signing
1. Generate or provide a release keystore (`.jks`).
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Fill `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.

The Gradle config automatically uses release signing when `android/key.properties` exists.
If it does not exist, build falls back to debug signing for local validation only.

## 2) Build release artifacts
From project root:

```bash
flutter build apk --release
flutter build appbundle --release
```

If your environment fails while building universal APK (x86 native variant), use:

```bash
flutter build apk --release --target-platform android-arm64
```

Outputs:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## 3) Verify package metadata
- App name: `Nabu Cleaner`
- Android label: `android/app/src/main/AndroidManifest.xml`

## 4) Play Store prep checklist
- Use release keystore (never debug) for final publication.
- Test with real media permissions and real deletion flows.
- Run `flutter analyze` and regression tests before upload.
