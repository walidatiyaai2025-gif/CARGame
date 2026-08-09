from pathlib import Path
import json


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text(encoding='utf-8')
    if old not in text:
        raise SystemExit(f'missing replacement in {path}: {old[:80]!r}')
    p.write_text(text.replace(old, new, 1), encoding='utf-8')

Path('lib/core/ads/ad_consent_controller.dart').write_text(r'''import 'dart:async';

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
''', encoding='utf-8')

Path('lib/core/ads/ad_service.dart').write_text(r'''import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_build_config.dart';
import 'ad_consent_controller.dart';
import 'reward_grant_guard.dart';

class AdService {
  AdService({AdRequestGate? requestGate})
    : _requestGate = requestGate ?? AdConsentState.shared {
    final gate = _requestGate;
    if (gate is Listenable) gate.addListener(_handleRequestGateChanged);
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
    final gate = _requestGate;
    if (gate is Listenable) gate.removeListener(_handleRequestGateChanged);
    _disposeLoadedAds();
  }
}
''', encoding='utf-8')

Path('lib/core/ads/banner_ad_footer.dart').write_text(r'''import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_build_config.dart';
import 'ad_consent_controller.dart';
import 'ad_service.dart';

class BannerAdFooter extends StatefulWidget {
  const BannerAdFooter({super.key, this.consentState});

  final AdConsentState? consentState;

  @override
  State<BannerAdFooter> createState() => _BannerAdFooterState();
}

class _BannerAdFooterState extends State<BannerAdFooter> {
  late AdConsentState _consentState;
  BannerAd? _banner;
  bool _loaded = false;

  bool get _platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _requestAllowed =>
      AppBuildConfig.current.enableAds &&
      _platformSupported &&
      _consentState.canRequestAds;

  @override
  void initState() {
    super.initState();
    _consentState = widget.consentState ?? AdConsentState.shared;
    _consentState.addListener(_syncWithConsent);
    _syncWithConsent();
  }

  @override
  void didUpdateWidget(covariant BannerAdFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.consentState ?? AdConsentState.shared;
    if (identical(next, _consentState)) return;
    _consentState.removeListener(_syncWithConsent);
    _disposeBanner();
    _consentState = next;
    _consentState.addListener(_syncWithConsent);
    _syncWithConsent();
  }

  void _syncWithConsent() {
    if (!_requestAllowed) {
      _disposeBanner();
      if (mounted && _loaded) setState(() => _loaded = false);
      return;
    }
    if (_banner == null) _load();
  }

  void _load() {
    if (!_requestAllowed || _banner != null) return;
    final ad = BannerAd(
      adUnitId: AdService.bannerId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !_requestAllowed) {
            ad.dispose();
            if (identical(_banner, ad)) _banner = null;
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _banner = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _banner = ad;
    ad.load();
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
  }

  @override
  void dispose() {
    _consentState.removeListener(_syncWithConsent);
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_requestAllowed || !_loaded || banner == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Material(
        color: const Color(0xFFF7F8FA),
        elevation: 8,
        shadowColor: Colors.black26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 30,
              child: Center(
                child: Text(
                  'Ad',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              alignment: Alignment.center,
              child: SizedBox(
                width: banner.size.width.toDouble(),
                height: banner.size.height.toDouble(),
                child: AdWidget(ad: banner),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''', encoding='utf-8')

# Composition owns the UMP controller but keeps the existing constructor source-compatible.
replace_once(
    'lib/bootstrap/app_composition.dart',
    "import '../core/application/optional_service_port.dart';\n",
    "import '../core/ads/ad_consent_controller.dart';\nimport '../core/application/optional_service_port.dart';\n",
)
replace_once(
    'lib/bootstrap/app_composition.dart',
    "    required this.optionalServices,\n  });",
    "    required this.optionalServices,\n    AdConsentController? adConsent,\n  }) : adConsent = adConsent ?? AdConsentController.production();",
)
replace_once(
    'lib/bootstrap/app_composition.dart',
    "    optionalServices: OptionalServiceCoordinator(\n      defaultTimeout: const Duration(seconds: 20),\n      maxAttempts: 3,\n    ),\n  );",
    "    optionalServices: OptionalServiceCoordinator(\n      defaultTimeout: const Duration(seconds: 20),\n      maxAttempts: 3,\n    ),\n    adConsent: AdConsentController.production(),\n  );",
)
replace_once(
    'lib/bootstrap/app_composition.dart',
    "  final OptionalServicePort optionalServices;\n",
    "  final OptionalServicePort optionalServices;\n  final AdConsentController adConsent;\n",
)

# Bootstrap requests UMP first; MobileAds initializes only when UMP permits requests.
replace_once(
    'lib/main.dart',
    "    WidgetsBinding.instance.addObserver(this);\n    unawaited(_bootstrap());",
    "    WidgetsBinding.instance.addObserver(this);\n    _composition.adConsent.state.addListener(_handleConsentChanged);\n    unawaited(_bootstrap());",
)
replace_once(
    'lib/main.dart',
    "    WidgetsBinding.instance.removeObserver(this);\n    unawaited(_composition.dispose());",
    "    WidgetsBinding.instance.removeObserver(this);\n    _composition.adConsent.state.removeListener(_handleConsentChanged);\n    unawaited(_composition.dispose());",
)
replace_once(
    'lib/main.dart',
    "    if (_composition.optionalServices.snapshot(_adsServiceName).canRetry) {\n      unawaited(_initializeAdsInBackground(forceRetry: true));\n    }",
    "    final consent = _composition.adConsent.state;\n    if (!consent.canRequestAds) {\n      if (consent.lastError != null) {\n        unawaited(_refreshConsentAndInitializeAds());\n      }\n      return;\n    }\n    if (_composition.optionalServices.snapshot(_adsServiceName).canRetry) {\n      unawaited(_initializeAdsInBackground(forceRetry: true));\n    }",
)
replace_once(
    'lib/main.dart',
    "    unawaited(_initializeAdsInBackground());",
    "    unawaited(_refreshConsentAndInitializeAds());",
)
replace_once(
    'lib/main.dart',
    "  Future<void> _initializeAdsInBackground({bool forceRetry = false}) async {\n",
    "  void _handleConsentChanged() {\n    if (!_composition.adConsent.state.canRequestAds) return;\n    final snapshot = _composition.optionalServices.snapshot(_adsServiceName);\n    if (snapshot.isReady) return;\n    unawaited(_initializeAdsInBackground(forceRetry: snapshot.canRetry));\n  }\n\n  Future<void> _refreshConsentAndInitializeAds() async {\n    final canRequestAds = await _composition.adConsent.refresh();\n    if (!canRequestAds) {\n      try {\n        await AppLogger.instance.info(\n          'Ads remain unavailable until privacy requirements permit requests.',\n          details: '${_composition.adConsent.state.lastError ?? 'consent not granted/required state'}',\n        );\n      } catch (_) {\n        // Privacy/ads are optional and must never block offline play.\n      }\n      return;\n    }\n    final snapshot = _composition.optionalServices.snapshot(_adsServiceName);\n    await _initializeAdsInBackground(forceRetry: snapshot.canRetry);\n  }\n\n  Future<void> _initializeAdsInBackground({bool forceRetry = false}) async {\n    if (!_composition.adConsent.state.canRequestAds) return;\n",
)
replace_once(
    'lib/main.dart',
    "      return CargoSortApp(\n        store: _composition.progressStore,\n        settings: _composition.settingsStore,\n      );",
    "      return CargoSortApp(\n        store: _composition.progressStore,\n        settings: _composition.settingsStore,\n        adConsentController: _composition.adConsent,\n      );",
)

# Thread the production consent state to Home and controller to Settings.
replace_once(
    'lib/bootstrap/cargo_sort_app.dart',
    "import '../core/logging/app_logger.dart';\n",
    "import '../core/ads/ad_consent_controller.dart';\nimport '../core/logging/app_logger.dart';\n",
)
replace_once(
    'lib/bootstrap/cargo_sort_app.dart',
    "  const CargoSortApp({super.key, required this.store, required this.settings});\n\n  final ProgressStore store;\n  final AppSettingsStore settings;",
    "  const CargoSortApp({\n    super.key,\n    required this.store,\n    required this.settings,\n    this.adConsentController,\n  });\n\n  final ProgressStore store;\n  final AppSettingsStore settings;\n  final AdConsentController? adConsentController;",
)
replace_once(
    'lib/bootstrap/cargo_sort_app.dart',
    "        builder: (_) => SettingsScreen(\n          settings: widget.settings,\n          onToggleLanguage: _toggleLanguage,\n        ),",
    "        builder: (_) => SettingsScreen(\n          settings: widget.settings,\n          onToggleLanguage: _toggleLanguage,\n          adConsentController: widget.adConsentController,\n        ),",
)
replace_once(
    'lib/bootstrap/cargo_sort_app.dart',
    "            HomeScreen(\n              store: widget.store,\n              settings: widget.settings,\n              onToggleLanguage: _toggleLanguage,\n            ),",
    "            HomeScreen(\n              store: widget.store,\n              settings: widget.settings,\n              onToggleLanguage: _toggleLanguage,\n              adConsentState: widget.adConsentController?.state,\n            ),",
)

replace_once(
    'lib/features/home/home_screen.dart',
    "import '../../core/ads/banner_ad_footer.dart';\n",
    "import '../../core/ads/ad_consent_controller.dart';\nimport '../../core/ads/banner_ad_footer.dart';\n",
)
replace_once(
    'lib/features/home/home_screen.dart',
    "    required this.onToggleLanguage,\n  });\n\n  final ProgressStore store;\n  final AppSettingsStore settings;\n  final VoidCallback onToggleLanguage;",
    "    required this.onToggleLanguage,\n    this.adConsentState,\n  });\n\n  final ProgressStore store;\n  final AppSettingsStore settings;\n  final VoidCallback onToggleLanguage;\n  final AdConsentState? adConsentState;",
)
replace_once(
    'lib/features/home/home_screen.dart',
    "      bottomNavigationBar: const BannerAdFooter(),",
    "      bottomNavigationBar: BannerAdFooter(\n        consentState: widget.adConsentState,\n      ),",
)

# Settings keeps the existing information entry and adds the required UMP privacy-options entry when applicable.
replace_once(
    'lib/features/settings/settings_screen.dart',
    "import '../../core/settings/app_settings_store.dart';\n",
    "import '../../core/ads/ad_consent_controller.dart';\nimport '../../core/settings/app_settings_store.dart';\n",
)
replace_once(
    'lib/features/settings/settings_screen.dart',
    "    required this.onToggleLanguage,\n  });\n\n  final AppSettingsStore settings;\n  final VoidCallback onToggleLanguage;",
    "    required this.onToggleLanguage,\n    this.adConsentController,\n  });\n\n  final AppSettingsStore settings;\n  final VoidCallback onToggleLanguage;\n  final AdConsentController? adConsentController;",
)
replace_once(
    'lib/features/settings/settings_screen.dart',
    "            animation: settings,",
    "            animation: Listenable.merge([\n              settings,\n              adConsentController?.state,\n            ]),",
)
replace_once(
    'lib/features/settings/settings_screen.dart',
    "                        subtitle: ar\n                            ? 'سياسة الخصوصية والإعلانات'\n                            : 'Privacy and advertising information',\n                        onTap: () => _showInfo(context, ar),",
    "                        subtitle: _privacySubtitle(ar),\n                        onTap: () => _showPrivacyInfo(context, ar),",
)
replace_once(
    'lib/features/settings/settings_screen.dart',
    "  void _showInfo(BuildContext context, bool ar) {\n    showModalBottomSheet<void>(\n      context: context,\n      showDragHandle: true,\n      builder: (context) => Padding(\n        padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),\n        child: Column(\n          mainAxisSize: MainAxisSize.min,\n          children: [\n            const Icon(Icons.shield_rounded, size: 54, color: AppTheme.green),\n            const SizedBox(height: 12),\n            Text(\n              ar ? 'الخصوصية والإعلانات' : 'Privacy & Ads',\n              style: Theme.of(\n                context,\n              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),\n            ),\n            const SizedBox(height: 10),\n            Text(\n              ar\n                  ? 'تستخدم اللعبة التخزين المحلي لحفظ التقدم، وقد تعرض إعلانات من شبكات الإعلانات المدعومة.'\n                  : 'The game uses local storage for progress and may display ads from supported advertising networks.',\n              textAlign: TextAlign.center,\n            ),\n          ],\n        ),\n      ),\n    );\n  }",
    "  String _privacySubtitle(bool ar) {\n    final state = adConsentController?.state;\n    if (state == null) {\n      return ar ? 'سياسة الخصوصية والإعلانات' : 'Privacy and advertising information';\n    }\n    if (state.refreshing) {\n      return ar ? 'جارٍ تحديث خيارات الخصوصية…' : 'Updating privacy choices…';\n    }\n    if (state.privacyOptionsRequired) {\n      return ar ? 'مراجعة أو تغيير خيارات الخصوصية' : 'Review or change privacy choices';\n    }\n    return ar\n        ? 'معلومات الخصوصية والإعلانات'\n        : 'Privacy and advertising information';\n  }\n\n  void _showPrivacyInfo(BuildContext context, bool ar) {\n    showModalBottomSheet<void>(\n      context: context,\n      showDragHandle: true,\n      builder: (context) => _PrivacySheet(\n        ar: ar,\n        controller: adConsentController,\n      ),\n    );\n  }",
)

# Insert privacy sheet before _HeroHeader.
settings_path = Path('lib/features/settings/settings_screen.dart')
settings_text = settings_path.read_text(encoding='utf-8')
marker = '\nclass _HeroHeader extends StatelessWidget {'
if marker not in settings_text:
    raise SystemExit('Settings _HeroHeader marker missing')
privacy_sheet = r'''

class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet({required this.ar, required this.controller});

  final bool ar;
  final AdConsentController? controller;

  @override
  Widget build(BuildContext context) {
    final consentController = controller;
    final animation = consentController?.state;
    if (animation == null) return _content(context, null);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => _content(context, consentController),
    );
  }

  Widget _content(BuildContext context, AdConsentController? consentController) {
    final state = consentController?.state;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, size: 54, color: AppTheme.green),
          const SizedBox(height: 12),
          Text(
            ar ? 'الخصوصية والإعلانات' : 'Privacy & Ads',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            ar
                ? 'تستخدم اللعبة التخزين المحلي لحفظ التقدم. يتم طلب الإعلانات فقط عندما تسمح حالة الخصوصية الحالية بذلك، ولا تجمع اللعبة تحليلات خاصة بها حاليًا.'
                : 'The game stores progress locally. Ad requests are made only when the current privacy state permits them, and the game does not currently collect first-party analytics.',
            textAlign: TextAlign.center,
          ),
          if (state?.lastError != null) ...[
            const SizedBox(height: 10),
            Text(
              ar
                  ? 'تعذر تحديث حالة الخصوصية الآن. ستظل اللعبة متاحة بدون إعلانات.'
                  : 'Privacy status could not be refreshed right now. The game remains available without ads.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          if (state?.privacyOptionsRequired == true) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('privacy-options-button'),
              onPressed: state!.refreshing
                  ? null
                  : () async {
                      final shown = await consentController!.showPrivacyOptions();
                      if (!context.mounted || shown) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ar
                                ? 'تعذر فتح خيارات الخصوصية الآن.'
                                : 'Privacy options are unavailable right now.',
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.manage_accounts_rounded),
              label: Text(ar ? 'إدارة خيارات الخصوصية' : 'Manage privacy choices'),
            ),
          ],
        ],
      ),
    );
  }
}
'''
settings_path.write_text(settings_text.replace(marker, privacy_sheet + marker, 1), encoding='utf-8')

# Privacy inventory: ADS-007 resolves the SDK bootstrap gap and remains analytics-off.
inv_path = Path('docs/privacy/data_inventory.json')
inv = json.loads(inv_path.read_text(encoding='utf-8'))
principles = inv['principles']
principles['adsFailClosedByConfig'] = True
principles['adRequestsFailClosedByConfig'] = True
principles['adSdkInitializationConsentGated'] = True
principles['adRequestsConsentGated'] = True
for flow in inv['dataFlows']:
    if flow['id'] == 'ad-sdk-processing':
        flow['examples'] = [
            'UMP consent state and privacy options determine whether Google Mobile Ads requests are permitted',
            'SDK/device/network signals potentially processed by Google Mobile Ads only after the consent gate permits ad requests',
        ]
        flow['purpose'] = 'Refresh UMP privacy state, initialize Google Mobile Ads only when requests are permitted, and load banner, rewarded, and interstitial advertisements'
        flow['consent'] = 'Google UMP is refreshed on launch; Mobile Ads initialization and all app-owned ad request/load/show paths are fail-closed behind current canRequestAds state. The app does not persist a duplicate consent-granted value.'
        flow['source'] = 'lib/core/ads/ad_consent_controller.dart'
inv['knownGaps'] = [gap for gap in inv['knownGaps'] if gap.get('id') != 'ad-sdk-bootstrap-consent']
inv_path.write_text(json.dumps(inv, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

# Human-readable privacy truth.
privacy_path = Path('docs/PRIVACY_DATA_INVENTORY.md')
privacy = privacy_path.read_text(encoding='utf-8')
privacy = privacy.replace(
    "Google Mobile Ads is the only intentional third-party network data processor in the current runtime dependency set. The app's `AdService` blocks ad load/show calls when `ENABLE_ADS=false`, but current bootstrap still calls `MobileAds.instance.initialize()` after the offline UI becomes available. Production consent and regulated-region gating before SDK initialization/requests therefore remains an explicit ADS-007 blocker rather than a capability claimed by PRIV-001.",
    "Google Mobile Ads is the only intentional third-party network data processor in the current runtime dependency set. ADS-007 uses Google UMP as the privacy source of truth: consent information is refreshed on launch, required forms are shown before ad startup, and `canRequestAds` gates Mobile Ads initialization plus banner/rewarded/interstitial request paths. No duplicate app-side consent-granted value is persisted.",
)
privacy = privacy.replace(
    "Sources: `lib/main.dart`, `lib/core/ads/ad_service.dart`, and `lib/core/config/app_build_config.dart`.",
    "Sources: `lib/main.dart`, `lib/core/ads/ad_consent_controller.dart`, `lib/core/ads/ad_service.dart`, `lib/core/ads/banner_ad_footer.dart`, and `lib/core/config/app_build_config.dart`.",
)
privacy = privacy.replace(
    "- `AdService` refuses ad preload/load/show operations when `ENABLE_ADS=false`.\n- Release builds reject Google test ad-unit IDs.\n- No first-party server receives ad identifiers or ad telemetry in the current codebase.\n- `MobileAds.instance.initialize()` is still invoked by optional-service bootstrap independently of the `AdService` request gate.\n- Production consent and regulated-region handling before SDK initialization/requests are not complete; ADS-007 owns that blocker.",
    "- Google UMP consent information is refreshed on launch and any required consent form is presented before ad startup.\n- `ConsentInformation.canRequestAds()` is the runtime source of truth for whether the app may initialize/request ads; no cached consent-granted preference is maintained by CARGame.\n- `AdService` and `BannerAdFooter` refuse request/load/show operations unless both `ENABLE_ADS` and current consent state permit requests, and loaded app-owned ads are disposed when eligibility is revoked.\n- Settings keeps a publisher-rendered privacy entry; when Google reports privacy options are required, the user can re-open the privacy options form and runtime eligibility updates without restarting.\n- Release builds reject Google test ad-unit IDs.\n- No first-party server receives ad identifiers or ad telemetry, and first-party analytics remains absent/disabled until ENG-012 adds a separately privacy-gated design.",
)
privacy = privacy.replace(
    "6. Production ad consent must be implemented before SDK initialization/requests where required; PRIV-001 documents the present gap and ADS-007 owns remediation.",
    "6. Google UMP must remain the source of truth before Mobile Ads initialization/requests; app-owned ad paths must remain fail-closed behind current `canRequestAds` state and must not cache a duplicate consent-granted value.",
)
privacy = privacy.replace(
    "- **ADS-007 — ad SDK bootstrap consent:** request/load calls are config-gated, but current bootstrap still initializes Google Mobile Ads. Production consent/regulated-region gating must execute before SDK initialization and requests.\n",
    "",
)
privacy = privacy.replace(
    "- ADS-007: production consent and privacy controls before ad SDK initialization/requests.\n",
    "- ADS-007: UMP consent and re-openable privacy controls now gate ad SDK initialization/requests; automated verification must remain green.\n",
)
privacy_path.write_text(privacy, encoding='utf-8')

# Security model mirrors the resolved consent gate; the advertising threat remains monitored under PRIV-002/TEST-011.
threat_path = Path('docs/security/threat_model.json')
threat = json.loads(threat_path.read_text(encoding='utf-8'))
threat['securityPrinciples']['adSdkInitializationConsentGated'] = True
for boundary in threat['trustBoundaries']:
    if boundary['id'] == 'google-mobile-ads':
        boundary['description'] = 'Third-party Google UMP and Mobile Ads SDK/network endpoints; UMP state is refreshed before startup and current canRequestAds eligibility gates app-owned Mobile Ads initialization and requests'
threat['knownGaps'] = [gap for gap in threat['knownGaps'] if gap.get('id') != 'ad-sdk-bootstrap-consent']
for item in threat['threats']:
    if item['category'] == 'advertising-boundary':
        item['mitigations'] = [
            'Google Mobile Ads is explicitly declared as the only current network processor in PRIV-001',
            'ADS-007 refreshes Google UMP consent state before ad startup and uses canRequestAds as the runtime eligibility source',
            'AdService and BannerAdFooter fail closed when consent/configuration does not permit requests and discard loaded app-owned ads after revocation',
            'Settings exposes Google privacy options when the SDK reports that a publisher entry point is required',
            'Release configuration rejects Google test ad-unit IDs',
        ]
        item['residualRisk'] = 'Google privacy-message configuration and third-party processor behavior remain external to the client and must stay aligned with PRIV-002 store disclosures and TEST-011 release verification.'
threat_path.write_text(json.dumps(threat, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

# Security verifier no longer requires a resolved ADS-007 gap, but still requires the runtime principle.
sec_path = Path('tool/verify_security_baseline.py')
sec = sec_path.read_text(encoding='utf-8')
sec = sec.replace(
    '    required_security_gap_ids = {\n        "ad-sdk-bootstrap-consent",\n        "diagnostics-build-gate",\n    }',
    '    required_security_gap_ids = {"diagnostics-build-gate"}',
)
sec = sec.replace(
    '    advertising_threat = threats_by_category["advertising-boundary"]\n    if advertising_threat.get("owner") != security_gap_by_id[\n        "ad-sdk-bootstrap-consent"\n    ].get("owner"):\n        fail("advertising threat owner must match the ad SDK bootstrap gap owner")\n',
    '    advertising_threat = threats_by_category["advertising-boundary"]\n    if advertising_threat.get("owner") != "ADS-007":\n        fail("advertising threat must remain owned by ADS-007 after consent integration")\n    if principles.get("adSdkInitializationConsentGated") is not True:\n        fail("advertising boundary requires consent-gated Mobile Ads initialization")\n',
)
sec_path.write_text(sec, encoding='utf-8')

# Strengthen PRIV-001 mechanical contract so JSON cannot claim ADS-007 without source gates.
priv_verifier = Path('tool/verify_privacy_inventory.py')
text = priv_verifier.read_text(encoding='utf-8')
needle = '    if principles.get("cloudSyncEnabled") is not False:\n        fail("cloudSyncEnabled changed without inventory review")\n\n'
addition = '''    if principles.get("cloudSyncEnabled") is not False:\n        fail("cloudSyncEnabled changed without inventory review")\n    for key in (\n        "adsFailClosedByConfig",\n        "adRequestsFailClosedByConfig",\n        "adSdkInitializationConsentGated",\n        "adRequestsConsentGated",\n    ):\n        if principles.get(key) is not True:\n            fail(f"{key} must remain true after ADS-007")\n\n    consent_source = (ROOT / "lib/core/ads/ad_consent_controller.dart").read_text(\n        encoding="utf-8"\n    )\n    main_source = (ROOT / "lib/main.dart").read_text(encoding="utf-8")\n    ad_service_source = (ROOT / "lib/core/ads/ad_service.dart").read_text(\n        encoding="utf-8"\n    )\n    banner_source = (ROOT / "lib/core/ads/banner_ad_footer.dart").read_text(\n        encoding="utf-8"\n    )\n    settings_source = (ROOT / "lib/features/settings/settings_screen.dart").read_text(\n        encoding="utf-8"\n    )\n    required_source_contracts = {\n        "UMP launch refresh": (consent_source, "requestConsentInfoUpdate"),\n        "UMP required form": (consent_source, "loadAndShowConsentFormIfRequired"),\n        "UMP request eligibility": (consent_source, "canRequestAds"),\n        "privacy options form": (consent_source, "showPrivacyOptionsForm"),\n        "bootstrap consent refresh": (main_source, "_composition.adConsent.refresh()"),\n        "bootstrap request gate": (main_source, "if (!_composition.adConsent.state.canRequestAds) return;"),\n        "fullscreen ad gate": (ad_service_source, "_requestGate.canRequestAds"),\n        "banner ad gate": (banner_source, "_consentState.canRequestAds"),\n        "publisher privacy entry": (settings_source, "privacy-options-button"),\n    }\n    for label, (source, token) in required_source_contracts.items():\n        if token not in source:\n            fail(f"ADS-007 source contract missing {label}: {token}")\n\n'''
if needle not in text:
    raise SystemExit('privacy verifier insertion point missing')
priv_verifier.write_text(text.replace(needle, addition, 1), encoding='utf-8')

# Focused state-machine tests use a fake gateway; no platform channels or cached consent values.
Path('test/core/ads/ad_consent_controller_test.dart').write_text(r'''import 'package:cargo_sort_game/core/ads/ad_consent_controller.dart';
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

  test('refresh applies UMP request eligibility and privacy option requirement', () async {
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
  });

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

  test('privacy options are not opened unless UMP requires an entry point', () async {
    final gateway = _FakeGateway();
    final controller = AdConsentController(
      gateway: gateway,
      state: AdConsentState(),
      adsEnabled: () => true,
    );

    expect(await controller.showPrivacyOptions(), isFalse);
    expect(gateway.privacyCalls, 0);
  });

  test('privacy options refresh runtime request eligibility without restart', () async {
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
  });

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
  final _completer = Future<AdConsentSnapshot>.sync(() async => throw StateError('not started'));
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
''', encoding='utf-8')

# Fix test imports/control helper immediately (kept explicit for source readability).
test_path = Path('test/core/ads/ad_consent_controller_test.dart')
test_text = test_path.read_text(encoding='utf-8')
test_text = test_text.replace("import 'package:cargo_sort_game/core/ads/ad_consent_controller.dart';\n", "import 'dart:async';\n\nimport 'package:cargo_sort_game/core/ads/ad_consent_controller.dart';\n")
test_text = test_text.replace("  final _completer = Future<AdConsentSnapshot>.sync(() async => throw StateError('not started'));\n", "")
test_path.write_text(test_text, encoding='utf-8')

Path('test/core/ads/ad_request_gate_test.dart').write_text(r'''import 'package:cargo_sort_game/core/ads/ad_consent_controller.dart';
import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdService refuses rewarded operations when consent gate is closed', () {
    final service = AdService(requestGate: _Gate(false));

    expect(service.rewardedReady, isFalse);
    expect(service.showRewarded(onReward: () {}), isFalse);
    expect(() => service.preload(), returnsNormally);

    service.dispose();
  });
}

class _Gate implements AdRequestGate {
  const _Gate(this.canRequestAds);

  @override
  final bool canRequestAds;
}
''', encoding='utf-8')

# Extend composition test to prove consent controller is owned/exposed without platform calls.
replace_once(
    'test/bootstrap/app_composition_test.dart',
    "import 'package:cargo_sort_game/core/application/optional_service_port.dart';\n",
    "import 'package:cargo_sort_game/core/ads/ad_consent_controller.dart';\nimport 'package:cargo_sort_game/core/application/optional_service_port.dart';\n",
)
replace_once(
    'test/bootstrap/app_composition_test.dart',
    "      expect(composition.optionalServices, isA<OptionalServicePort>());\n",
    "      expect(composition.optionalServices, isA<OptionalServicePort>());\n      expect(composition.adConsent, isA<AdConsentController>());\n",
)
