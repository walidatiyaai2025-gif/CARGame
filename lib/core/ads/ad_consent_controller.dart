import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_build_config.dart';

abstract interface class AdRequestGate {
  bool get canRequestAds;
}

class AdConsentSnapshot {
  const AdConsentSnapshot({
    required this.canRequestAds,
    required this.privacyOptionsRequired,
    this.warning,
  });

  final bool canRequestAds;
  final bool privacyOptionsRequired;
  final Object? warning;
}

abstract interface class AdConsentGateway {
  Future<AdConsentSnapshot> refresh();
  Future<AdConsentSnapshot> showPrivacyOptions();
}

class GoogleMobileAdsConsentGateway implements AdConsentGateway {
  const GoogleMobileAdsConsentGateway();

  @override
  Future<AdConsentSnapshot> refresh() async {
    FormError? warning;
    final update = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!update.isCompleted) update.complete();
      },
      (error) {
        warning = error;
        if (!update.isCompleted) update.complete();
      },
    );
    await update.future;

    if (warning == null) {
      await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
        if (formError != null) warning = formError;
      });
    }

    return _readSnapshot(warning);
  }

  @override
  Future<AdConsentSnapshot> showPrivacyOptions() async {
    FormError? warning;
    await ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) warning = formError;
    });
    return _readSnapshot(warning);
  }

  Future<AdConsentSnapshot> _readSnapshot(Object? warning) async {
    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    final requirement = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return AdConsentSnapshot(
      canRequestAds: canRequestAds,
      privacyOptionsRequired:
          requirement == PrivacyOptionsRequirementStatus.required,
      warning: warning,
    );
  }
}

class AdConsentState extends ChangeNotifier implements AdRequestGate {
  AdConsentState();

  static final AdConsentState shared = AdConsentState();

  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  bool _refreshing = false;
  bool _hasRefreshed = false;
  Object? _lastError;

  @override
  bool get canRequestAds => _canRequestAds;
  bool get privacyOptionsRequired => _privacyOptionsRequired;
  bool get refreshing => _refreshing;
  bool get hasRefreshed => _hasRefreshed;
  Object? get lastError => _lastError;

  // CARGame has no first-party analytics SDK today. ENG-012 owns any future
  // analytics collection and must add its own consent/config gate.
  bool get firstPartyAnalyticsAllowed => false;

  void markRefreshing() {
    _refreshing = true;
    _lastError = null;
    notifyListeners();
  }

  void apply(AdConsentSnapshot snapshot) {
    _canRequestAds = snapshot.canRequestAds;
    _privacyOptionsRequired = snapshot.privacyOptionsRequired;
    _refreshing = false;
    _hasRefreshed = true;
    _lastError = snapshot.warning;
    notifyListeners();
  }

  void failClosed(Object error) {
    _canRequestAds = false;
    _privacyOptionsRequired = false;
    _refreshing = false;
    _hasRefreshed = true;
    _lastError = error;
    notifyListeners();
  }

  void disableByConfiguration() {
    _canRequestAds = false;
    _privacyOptionsRequired = false;
    _refreshing = false;
    _hasRefreshed = true;
    _lastError = null;
    notifyListeners();
  }
}

class AdConsentController {
  AdConsentController({
    required AdConsentGateway gateway,
    AdConsentState? state,
    bool Function()? adsEnabled,
  }) : _gateway = gateway,
       state = state ?? AdConsentState.shared,
       _adsEnabled = adsEnabled ?? (() => AppBuildConfig.current.enableAds);

  factory AdConsentController.production({AdConsentState? state}) =>
      AdConsentController(
        gateway: const GoogleMobileAdsConsentGateway(),
        state: state ?? AdConsentState.shared,
      );

  final AdConsentGateway _gateway;
  final bool Function() _adsEnabled;
  final AdConsentState state;
  Future<bool>? _refreshFuture;

  Future<bool> refresh() {
    final running = _refreshFuture;
    if (running != null) return running;

    final future = _refreshInternal();
    _refreshFuture = future;
    return future.whenComplete(() {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    });
  }

  Future<bool> _refreshInternal() async {
    if (!_adsEnabled()) {
      state.disableByConfiguration();
      return false;
    }

    state.markRefreshing();
    try {
      final snapshot = await _gateway.refresh();
      state.apply(snapshot);
      return state.canRequestAds;
    } catch (error) {
      state.failClosed(error);
      return false;
    }
  }

  Future<bool> showPrivacyOptions() async {
    if (!_adsEnabled() || !state.privacyOptionsRequired || state.refreshing) {
      return false;
    }

    state.markRefreshing();
    try {
      final snapshot = await _gateway.showPrivacyOptions();
      state.apply(snapshot);
      return snapshot.warning == null;
    } catch (error) {
      state.failClosed(error);
      return false;
    }
  }
}
