import 'package:cargo_sort_game/core/ads/reward_grant_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reward grant guard allows exactly one claim', () {
    final guard = RewardGrantGuard();

    expect(guard.claimed, isFalse);
    expect(guard.claim(), isTrue);
    expect(guard.claimed, isTrue);
    expect(guard.claim(), isFalse);
    expect(guard.claim(), isFalse);
  });
}
