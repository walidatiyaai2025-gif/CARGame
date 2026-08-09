import '../core/ads/ad_consent_controller.dart';
import '../core/analytics/privacy_gated_analytics.dart';
import '../core/application/analytics_port.dart';
import '../core/application/optional_service_port.dart';
import '../core/config/app_build_config.dart';
import '../core/services/optional_service_coordinator.dart';
import '../core/settings/app_settings_store.dart';
import '../core/storage/progress_store.dart';

class AppComposition {
  AppComposition({
    required this.progressStore,
    required this.settingsStore,
    required this.optionalServices,
    AnalyticsPort? analytics,
    AdConsentController? adConsent,
  }) : analytics = analytics ?? PrivacyGatedAnalytics.disabled(),
       adConsent = adConsent ?? AdConsentController.production();

  factory AppComposition.production() => AppComposition(
    progressStore: ProgressStore(),
    settingsStore: AppSettingsStore(),
    optionalServices: OptionalServiceCoordinator(
      defaultTimeout: const Duration(seconds: 20),
      maxAttempts: 3,
    ),
    analytics: PrivacyGatedAnalytics(
      configEnabled: AppBuildConfig.current.enableAnalytics,
      privacy: const DenyAllAnalyticsPrivacy(),
    ),
    adConsent: AdConsentController.production(),
  );

  final ProgressStore progressStore;
  final AppSettingsStore settingsStore;
  final OptionalServicePort optionalServices;
  final AnalyticsPort analytics;
  final AdConsentController adConsent;

  Future<void> dispose() => optionalServices.dispose();
}
