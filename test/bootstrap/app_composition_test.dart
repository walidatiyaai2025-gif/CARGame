import 'dart:async';

import 'package:cargo_sort_game/bootstrap/app_composition.dart';
import 'package:cargo_sort_game/core/ads/ad_consent_controller.dart';
import 'package:cargo_sort_game/core/application/optional_service_port.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composition exposes injected dependencies and owns disposal', () async {
    final progressStore = ProgressStore();
    final settingsStore = AppSettingsStore();
    final optionalServices = _FakeOptionalServices();
    final composition = AppComposition(
      progressStore: progressStore,
      settingsStore: settingsStore,
      optionalServices: optionalServices,
    );

    expect(identical(composition.progressStore, progressStore), isTrue);
    expect(identical(composition.settingsStore, settingsStore), isTrue);
    expect(identical(composition.optionalServices, optionalServices), isTrue);

    await composition.dispose();
    expect(optionalServices.disposed, isTrue);
  });

  test(
    'production composition creates usable offline core dependencies',
    () async {
      final composition = AppComposition.production();

      expect(composition.progressStore, isA<ProgressStore>());
      expect(composition.settingsStore, isA<AppSettingsStore>());
      expect(composition.optionalServices, isA<OptionalServicePort>());
      expect(composition.adConsent, isA<AdConsentController>());

      await composition.dispose();
    },
  );
}

class _FakeOptionalServices implements OptionalServicePort {
  final StreamController<OptionalServiceSnapshot> _changes =
      StreamController<OptionalServiceSnapshot>.broadcast();

  bool disposed = false;

  @override
  Stream<OptionalServiceSnapshot> get changes => _changes.stream;

  @override
  OptionalServiceSnapshot snapshot(String name) => OptionalServiceSnapshot(
    name: name,
    status: OptionalServiceStatus.idle,
    attempts: 0,
  );

  @override
  Future<bool> initialize(
    String name,
    Future<void> Function() action, {
    Duration? timeout,
  }) async {
    await action();
    return true;
  }

  @override
  Future<bool> retry(
    String name,
    Future<void> Function() action, {
    Duration? timeout,
  }) => initialize(name, action, timeout: timeout);

  @override
  Future<void> dispose() async {
    disposed = true;
    await _changes.close();
  }
}
