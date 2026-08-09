import '../application/analytics_port.dart';
import '../domain/analytics_event.dart';

typedef AnalyticsEmitter = Future<void> Function(AnalyticsEvent event);

final class DenyAllAnalyticsPrivacy implements AnalyticsPrivacyPort {
  const DenyAllAnalyticsPrivacy();

  @override
  bool get canCollectAnalytics => false;
}

final class PrivacyGatedAnalytics implements AnalyticsPort {
  PrivacyGatedAnalytics({
    required bool configEnabled,
    required AnalyticsPrivacyPort privacy,
    AnalyticsEmitter? emitter,
  }) : _configEnabled = configEnabled,
       _privacy = privacy,
       _emitter = emitter;

  factory PrivacyGatedAnalytics.disabled() => PrivacyGatedAnalytics(
    configEnabled: false,
    privacy: const DenyAllAnalyticsPrivacy(),
  );

  final bool _configEnabled;
  final AnalyticsPrivacyPort _privacy;
  final AnalyticsEmitter? _emitter;

  @override
  bool get isCollectionEnabled =>
      _configEnabled && _privacy.canCollectAnalytics && _emitter != null;

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (!isCollectionEnabled) return;

    try {
      await _emitter!(event);
    } catch (_) {
      // Analytics is always optional. Adapter failures must never affect the
      // offline gameplay path or user-visible application behavior.
    }
  }
}
