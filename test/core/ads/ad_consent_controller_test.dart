import 'dart:async';

import 'package:cargo_sort_game/core/ads/ad_consent_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disabled ads skip UMP and fail closed', () async {
    final gateway = _FakeGateway();
    final state = AdConsentState();
    final controller = AdConsentController(
      gateway: gateway,
      state: state,
      adsEnabled: () => false,
    );

    expect(await controller.refresh(), isFalse);
    expect(gateway.refreshCalls, 0);
    expect(state.canRequestAds, isFalse);
    expect(state.hasRefreshed, isTrue);
    expect(state.firstPartyAnalyticsAllowed, isFalse);
  });

  test(
    'refresh applies UMP request eligibility and privacy option requirement',
    () async {
      final gateway = _FakeGateway(
        refreshSnapshot: const AdConsentSnapshot(
          canRequestAds: true,
          privacyOptionsRequired: true,
        ),
      );
      final state = AdConsentState();
      final controller = AdConsentController(
        gateway: gateway,
        state: state,
        adsEnabled: () => true,
      );

      expect(await controller.refresh(), isTrue);
      expect(gateway.refreshCalls, 1);
      expect(state.canRequestAds, isTrue);
      expect(state.privacyOptionsRequired, isTrue);
      expect(state.lastError, isNull);
    },
  );

  test('gateway warning preserves UMP canRequestAds result', () async {
    final warning = StateError('transient consent refresh warning');
    final gateway = _FakeGateway(
      refreshSnapshot: AdConsentSnapshot(
        canRequestAds: true,
        privacyOptionsRequired: false,
        warning: warning,
      ),
    );
    final state = AdConsentState();
    final controller = AdConsentController(
      gateway: gateway,
      state: state,
      adsEnabled: () => true,
    );

    expect(await controller.refresh(), isTrue);
    expect(state.canRequestAds, isTrue);
    expect(state.lastError, same(warning));
  });

  test('unexpected UMP failure is fail closed', () async {
    final gateway = _FakeGateway(refreshError: StateError('UMP unavailable'));
    final state = AdConsentState();
    final controller = AdConsentController(
      gateway: gateway,
      state: state,
      adsEnabled: () => true,
    );

    expect(await controller.refresh(), isFalse);
    expect(state.canRequestAds, isFalse);
    expect(state.lastError, isA<StateError>());
  });

  test(
    'privacy options are not opened unless UMP requires an entry point',
    () async {
      final gateway = _FakeGateway();
      final controller = AdConsentController(
        gateway: gateway,
        state: AdConsentState(),
        adsEnabled: () => true,
      );

      expect(await controller.showPrivacyOptions(), isFalse);
      expect(gateway.privacyCalls, 0);
    },
  );

  test(
    'privacy options refresh runtime request eligibility without restart',
    () async {
      final gateway = _FakeGateway(
        refreshSnapshot: const AdConsentSnapshot(
          canRequestAds: true,
          privacyOptionsRequired: true,
        ),
        privacySnapshot: const AdConsentSnapshot(
          canRequestAds: false,
          privacyOptionsRequired: true,
        ),
      );
      final state = AdConsentState();
      final controller = AdConsentController(
        gateway: gateway,
        state: state,
        adsEnabled: () => true,
      );

      expect(await controller.refresh(), isTrue);
      expect(state.canRequestAds, isTrue);
      expect(await controller.showPrivacyOptions(), isTrue);
      expect(gateway.privacyCalls, 1);
      expect(state.canRequestAds, isFalse);
      expect(state.privacyOptionsRequired, isTrue);
    },
  );

  test('concurrent refresh calls are deduplicated', () async {
    final completer = _ControlledGateway();
    final controller = AdConsentController(
      gateway: completer,
      state: AdConsentState(),
      adsEnabled: () => true,
    );

    final first = controller.refresh();
    final second = controller.refresh();
    expect(completer.refreshCalls, 1);
    completer.complete(
      const AdConsentSnapshot(
        canRequestAds: true,
        privacyOptionsRequired: false,
      ),
    );

    expect(await first, isTrue);
    expect(await second, isTrue);
  });
}

class _FakeGateway implements AdConsentGateway {
  _FakeGateway({
    this.refreshSnapshot = const AdConsentSnapshot(
      canRequestAds: false,
      privacyOptionsRequired: false,
    ),
    this.privacySnapshot = const AdConsentSnapshot(
      canRequestAds: false,
      privacyOptionsRequired: false,
    ),
    this.refreshError,
  });

  final AdConsentSnapshot refreshSnapshot;
  final AdConsentSnapshot privacySnapshot;
  final Object? refreshError;
  int refreshCalls = 0;
  int privacyCalls = 0;

  @override
  Future<AdConsentSnapshot> refresh() async {
    refreshCalls++;
    final error = refreshError;
    if (error != null) throw error;
    return refreshSnapshot;
  }

  @override
  Future<AdConsentSnapshot> showPrivacyOptions() async {
    privacyCalls++;
    return privacySnapshot;
  }
}

class _ControlledGateway implements AdConsentGateway {
  int refreshCalls = 0;
  late final _pending = _PendingSnapshot();

  void complete(AdConsentSnapshot value) => _pending.complete(value);

  @override
  Future<AdConsentSnapshot> refresh() {
    refreshCalls++;
    return _pending.future;
  }

  @override
  Future<AdConsentSnapshot> showPrivacyOptions() async =>
      const AdConsentSnapshot(
        canRequestAds: false,
        privacyOptionsRequired: false,
      );
}

class _PendingSnapshot {
  final _completer = Completer<AdConsentSnapshot>();
  Future<AdConsentSnapshot> get future => _completer.future;
  void complete(AdConsentSnapshot value) => _completer.complete(value);
}
