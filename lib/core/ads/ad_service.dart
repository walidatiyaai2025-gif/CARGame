import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_build_config.dart';
import 'reward_grant_guard.dart';

class AdService {
  static String get bannerId => Platform.isAndroid
      ? AppBuildConfig.current.adMob.androidBanner
      : AppBuildConfig.current.adMob.iosBanner;

  static String get rewardedId => Platform.isAndroid
      ? AppBuildConfig.current.adMob.androidRewarded
      : AppBuildConfig.current.adMob.iosRewarded;

  static String get interstitialId => Platform.isAndroid
      ? AppBuildConfig.current.adMob.androidInterstitial
      : AppBuildConfig.current.adMob.iosInterstitial;

  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;

  bool get rewardedReady => AppBuildConfig.current.enableAds && _rewarded != null;

  void preload() {
    if (!AppBuildConfig.current.enableAds) return;
    _loadRewarded();
    _loadInterstitial();
  }

  void _loadRewarded() {
    if (!AppBuildConfig.current.enableAds) return;
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  void _loadInterstitial() {
    if (!AppBuildConfig.current.enableAds) return;
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  bool showRewarded({required void Function() onReward}) {
    if (!AppBuildConfig.current.enableAds) return false;

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
        if (rewardGuard.claim()) {
          onReward();
        }
      },
    );
    return true;
  }

  void showInterstitial() {
    if (!AppBuildConfig.current.enableAds) return;

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

  void dispose() {
    _rewarded?.dispose();
    _interstitial?.dispose();
  }
}
