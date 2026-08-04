#!/usr/bin/env bash
set -euo pipefail
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or not in PATH. Install Flutter 3.38.1+ first."
  exit 1
fi
# Generate any standard platform files that are missing (Gradle wrapper/Xcode project).
flutter create --platforms=android,ios --org com.walka --project-name cargo_sort_game .
flutter pub get
flutter gen-l10n
flutter doctor
printf '\nReady. Run: flutter run\n'
