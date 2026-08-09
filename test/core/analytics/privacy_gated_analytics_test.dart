import 'package:cargo_sort_game/core/analytics/privacy_gated_analytics.dart';
import 'package:cargo_sort_game/core/application/analytics_port.dart';
import 'package:cargo_sort_game/core/domain/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final event = AnalyticsEvent(AnalyticsEventName.appOpened);

  test('collection is disabled when build config is disabled', () async {
    final privacy = _MutableAnalyticsPrivacy(true);
    final emitted = <AnalyticsEvent>[];
    final analytics = PrivacyGatedAnalytics(
      configEnabled: false,
      privacy: privacy,
      emitter: (value) async => emitted.add(value),
    );

    expect(analytics.isCollectionEnabled, isFalse);
    await analytics.track(event);
    expect(emitted, isEmpty);
  });

  test('collection is disabled without runtime privacy eligibility', () async {
    final privacy = _MutableAnalyticsPrivacy(false);
    final emitted = <AnalyticsEvent>[];
    final analytics = PrivacyGatedAnalytics(
      configEnabled: true,
      privacy: privacy,
      emitter: (value) async => emitted.add(value),
    );

    expect(analytics.isCollectionEnabled, isFalse);
    await analytics.track(event);
    expect(emitted, isEmpty);
  });

  test('collection remains disabled without an outward emitter', () async {
    final analytics = PrivacyGatedAnalytics(
      configEnabled: true,
      privacy: _MutableAnalyticsPrivacy(true),
    );

    expect(analytics.isCollectionEnabled, isFalse);
    await analytics.track(event);
  });

  test('eligible events are forwarded exactly once', () async {
    final privacy = _MutableAnalyticsPrivacy(true);
    final emitted = <AnalyticsEvent>[];
    final analytics = PrivacyGatedAnalytics(
      configEnabled: true,
      privacy: privacy,
      emitter: (value) async => emitted.add(value),
    );

    expect(analytics.isCollectionEnabled, isTrue);
    await analytics.track(event);

    expect(emitted, <AnalyticsEvent>[event]);
  });

  test('runtime revocation takes effect immediately', () async {
    final privacy = _MutableAnalyticsPrivacy(true);
    final emitted = <AnalyticsEvent>[];
    final analytics = PrivacyGatedAnalytics(
      configEnabled: true,
      privacy: privacy,
      emitter: (value) async => emitted.add(value),
    );

    await analytics.track(event);
    privacy.canCollectAnalytics = false;
    await analytics.track(event);

    expect(analytics.isCollectionEnabled, isFalse);
    expect(emitted, <AnalyticsEvent>[event]);
  });

  test('emitter failures never escape into gameplay code', () async {
    final analytics = PrivacyGatedAnalytics(
      configEnabled: true,
      privacy: _MutableAnalyticsPrivacy(true),
      emitter: (_) async => throw StateError('network adapter failed'),
    );

    await expectLater(analytics.track(event), completes);
  });

  test('disabled production fallback is fail-closed', () {
    final analytics = PrivacyGatedAnalytics.disabled();

    expect(analytics.isCollectionEnabled, isFalse);
  });
}

final class _MutableAnalyticsPrivacy implements AnalyticsPrivacyPort {
  _MutableAnalyticsPrivacy(this.canCollectAnalytics);

  @override
  bool canCollectAnalytics;
}
