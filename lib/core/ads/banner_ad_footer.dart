import 'package:flutter/foundation.dart';
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
