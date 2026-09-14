# Hatora mobile

Flutter foundation for the Hatora learning notebook. Uses Riverpod, go_router, Dio, secure token storage, and a layered feature-first architecture.

## Run on Android

Start the backend separately, then run from this directory:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

The default URL reaches the host from the Android emulator. For a physical device, configure a reachable backend URL. Release builds require HTTPS; local cleartext is enabled only in the Android debug manifest.

If desktop plugin symlink creation fails on Windows, use these process-local options for Android work:

```powershell
$env:FLUTTER_WINDOWS = 'false'
$env:FLUTTER_LINUX = 'false'
```

## Checks

```powershell
dart format .
flutter analyze
flutter test
```

Tests use fakes and do not need a live backend. Current result: 32 passing tests and clean analysis. APK verification was blocked by DNS failures downloading Google/Flutter Gradle artifacts; see the status report.

## Documentation

- [Architecture, source contracts, and diagrams](docs/architecture/MOBILE_ARCHITECTURE.md)
- [Implementation status, verification, and deferrals](docs/architecture/MOBILE_IMPLEMENTATION_STATUS.md)
- [Visual reference](docs/design/hatora-prototip.html)

This pass connects email/password auth, catalog/onboarding, and question analysis/creation. Review and statistics are explicitly deferred. The backend at `../HatoraBackend` is read-only reference material.
