import 'package:cargo_sort_game/core/ads/ad_consent_controller.dart';
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

  test('AdService refuses interstitial operations when consent gate is closed', () {
    final service = AdService(requestGate: _Gate(false));

    expect(() => service.showInterstitial(), returnsNormally);
    expect(() => service.preload(), returnsNormally);

    service.dispose();
  });
}

class _Gate implements AdRequestGate {
  const _Gate(this.canRequestAds);

  @override
  final bool canRequestAds;
}
