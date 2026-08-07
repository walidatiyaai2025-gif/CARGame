# CI formatting debt

Status: TRACKED
Date: 2026-08-07
Owner: Shared maintenance queue

## Context

The strict repository-wide Dart formatting gate introduced during CI hardening exposed 22 pre-existing files that differ from Dart 3.12.2 formatting. These files span active asset, configuration, storage, UI, test, and tooling workstreams.

A bulk formatting sweep is intentionally deferred while those workstreams are active because it would create a high-conflict, behavior-neutral diff across files currently owned by teammates.

## Current policy

Flutter CI validates formatting only for Dart files changed by the current push or pull request. This prevents new formatting drift without rewriting unrelated legacy files during CI.

## Follow-up acceptance

- Rebase or wait until overlapping asset/UI/config branches are merged or closed.
- Run Dart 3.12.2 formatter across `lib`, `test`, and `tool` in one formatting-only change.
- Verify the resulting diff contains formatting changes only.
- Run Analyze, full tests, and Debug APK before merge.
- After the debt sweep lands, consider restoring repository-wide formatting validation.

## Evidence

Flutter CI run `31195278597`, job `92921857079`, reported 71 Dart files scanned and 22 changed by the formatter before exiting with code 1.
