import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_build_config.dart';
import 'ad_consent_controller.dart';
import 'reward_grant_guard.dart';

class AdService {
  AdService({AdRequestGate? requestGate})
    : _requestGate = requestGate ?? AdConsentState.shared {
    final gate = _requestGate;
    _listenableGate = gate is Listenable ? gate as Listenable : null;
    _listenableGate?.addListener(_handleRequestGateChanged);
  }

  static String get bannerId => Platform.isAndroid
      ? AppBuildConfig.current.adMob.androidBanner
      : AppBuildConfig.current.adMob.iosBanner;

  static String get rewardedId => Platform.isAndroid
      ? AppBuildConfig.current.adMob.androidRewarded
      : AppBuildConfig.current.adMob.iosRewarded;

  static String get interstitialId => Platform.isAndroid
      ? AppBuildConfig.current.adMob.androidInterstitial
      : AppBuildConfig.current.adMob.iosInterstitial;

  final AdRequestGate _requestGate;
  Listenable? _listenableGate;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _disposed = false;

  bool get _adsAllowed =>
      AppBuildConfig.current.enableAds && _requestGate.canRequestAds;

  bool get rewardedReady => _adsAllowed && _rewarded != null;

  void preload() {
    if (!_adsAllowed || _disposed) return;
    _loadRewarded();
    _loadInterstitial();
  }

  void _handleRequestGateChanged() {
    if (_disposed) return;
    if (!_adsAllowed) {
      _disposeLoadedAds();
      return;
    }
    preload();
  }

  void _loadRewarded() {
    if (!_adsAllowed || _disposed || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!_adsAllowed || _disposed) {
            ad.dispose();
            return;
          }
          _rewarded = ad;
        },
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  void _loadInterstitial() {
    if (!_adsAllowed || _disposed || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!_adsAllowed || _disposed) {
            ad.dispose();
            return;
          }
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  bool showRewarded({required void Function() onReward}) {
    if (!_adsAllowed || _disposed) return false;

    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }

    final rewardGuard = RewardGrantGuard();
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewarded();
      },
    );
    ad.show(
      onUserEarnedReward: (_, _) {
        if (rewardGuard.claim()) onReward();
      },
    );
    return true;
  }

  void showInterstitial() {
    if (!_adsAllowed || _disposed) return;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  void _disposeLoadedAds() {
    _rewarded?.dispose();
    _rewarded = null;
    _interstitial?.dispose();
    _interstitial = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _listenableGate?.removeListener(_handleRequestGateChanged);
    _listenableGate = null;
    _disposeLoadedAds();
  }
}
