import '../domain/analytics_event.dart';

abstract interface class AnalyticsPort {
  bool get isCollectionEnabled;

  Future<void> track(AnalyticsEvent event);
}

abstract interface class AnalyticsPrivacyPort {
  bool get canCollectAnalytics;
}
