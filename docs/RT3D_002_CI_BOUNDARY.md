# RT3D-002 CI boundary

The focused RT3D-002 workflow is additive. It does not replace the repository's normal Flutter CI. A production 3D checkpoint must satisfy both the focused contract gates and the normal full-suite/build/security gates before merge.

The focused workflow intentionally uses the same stable Flutter 3.44.8 baseline and `flutter pub get --enforce-lockfile` policy as normal CI.
