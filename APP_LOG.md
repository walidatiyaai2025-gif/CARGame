# Cargo Sort Application Log

The application now has a centralized runtime logging system.

## In-app log viewer

Open the application and press the document icon in the top bar. The viewer shows:

- Flutter framework errors
- asynchronous and platform errors
- isolate errors
- bootstrap and initialization events
- Google Mobile Ads initialization failures
- local storage initialization failures
- the physical runtime log-file path

Use **Copy complete log** to copy the full message and stack trace.

## Fatal startup screen

If the application cannot start, a full-screen error box appears with a selectable error message and a **Copy error** button.

## Runtime log location

Android stores the runtime log in the application support directory under:

```text
logs/app_error.log
```

The exact absolute path is displayed at the bottom of the in-app log viewer.

## Root-level diagnostic capture

Run the following from the repository root while the phone is connected:

```powershell
.\COLLECT_ANDROID_LOG.ps1
```

This creates or replaces:

```text
android_runtime.log
```

in the repository root. The generated runtime log is intentionally ignored by Git.

## Build

```powershell
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter build apk --release --target-platform android-arm64
```
