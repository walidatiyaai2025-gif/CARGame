# Cargo Sort – Warehouse Puzzle

Flutter MVP game with five playable levels, Arabic/English localization, offline progress, coins, hints, rewarded ads, and interstitial ads.

## Requirements
- Flutter 3.44.8 (the version pinned by CI) or a compatible newer stable release
- Dart 3.10 or newer
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

## Current MVP
- 5 levels
- Tap package then matching warehouse
- Limited moves
- Coins and paid hints
- Saved unlocked levels
- Rewarded test ad gives 5 moves
- Interstitial test ad after every third completed level
- Arabic RTL and English LTR

## Notes
The `flame` dependency is included for the next phase (animations, particles, game loop, sound, and sprite-based mechanics). The MVP uses Flutter widgets for a reliable first playable build.

Repository architecture, tooling, persistence keys, asset inventory, and tracked
delivery risks are recorded in [`docs/BASELINE_AUDIT.md`](docs/BASELINE_AUDIT.md).
