# Cargo Sort – Warehouse Puzzle

Offline-first Flutter cargo sorting game with 150 levels across six worlds,
Arabic/English localization, persistent progress/economy, reusable motion,
diagnostics, and isolated test advertising.

## Requirements
- Flutter 3.44.8 (the version pinned by CI) or a compatible newer stable release
- Dart 3.10 or newer
- JDK 17
- Android Studio or VS Code with Flutter extension

## First setup (recommended)
The ZIP contains the complete game source. Because generated Gradle/Xcode wrapper files depend on your installed Flutter SDK, run:
```bash
chmod +x bootstrap.sh
./bootstrap.sh
flutter run
```
On Windows, run these commands instead:
```powershell
flutter create --platforms=android,ios --org com.walka --project-name cargo_sort_game .
flutter pub get
flutter gen-l10n
flutter run
```

## Build Android
```bash
flutter build appbundle --release
```

## Important: advertising
The project uses Google's official test App ID and test ad units. Do not click production ads while developing. Before publishing:
1. Create an AdMob app and ad units.
2. Replace the test App IDs in AndroidManifest.xml and Info.plist.
3. Replace test unit IDs in lib/core/ads/ad_service.dart.
4. Add UMP consent flow and your privacy-policy URL.
5. Configure Meta Audience Network through AdMob Mediation; do not embed Meta credentials in source control.

## Current engineering state

- 150 deterministic level entries and six worlds
- Offline SharedPreferences progress, economy, settings, and daily systems
- Mission briefing, boosters, guarded gameplay, results, shop, and progress hub
- Arabic RTL and English LTR
- Shared button, ambient, cargo travel, and action-feedback motion systems
- Local copyable diagnostics and non-blocking optional-service startup
- GitHub Actions format, analysis, tests, and debug APK gate

## Notes
The runtime currently uses Flutter widgets. `flame` is installed but does not own
the game loop. Release signing, production ad configuration/consent, and binary 3D
asset packs remain explicit release blockers.

Repository architecture, tooling, persistence keys, asset inventory, and tracked
delivery risks are recorded in [`docs/BASELINE_AUDIT.md`](docs/BASELINE_AUDIT.md).
The production 3D asset contract is in
[`docs/ASSET_CATALOG.md`](docs/ASSET_CATALOG.md).
