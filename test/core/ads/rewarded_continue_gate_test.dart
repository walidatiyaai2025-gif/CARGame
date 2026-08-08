import 'package:cargo_sort_game/core/ads/rewarded_continue_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RewardedContinueGate', () {
    test('keeps loss result available when no rewarded ad starts', () {
      final gate = RewardedContinueGate();

      expect(gate.markStart(false), RewardedContinueOutcome.unavailable);
      expect(gate.started, isFalse);
      expect(gate.rewarded, isFalse);
    });

    test('records a real ad start without granting gameplay reward', () {
      final gate = RewardedContinueGate();

      expect(gate.markStart(true), RewardedContinueOutcome.started);
      expect(gate.started, isTrue);
      expect(gate.rewarded, isFalse);
    });

    test('cannot grant a reward before the ad started', () {
      final gate = RewardedContinueGate();

      expect(gate.markRewarded(), RewardedContinueOutcome.unavailable);
      expect(gate.rewarded, isFalse);
    });

    test('accepts the rewarded callback after a real ad start', () {
      final gate = RewardedContinueGate();
      gate.markStart(true);

      expect(gate.markRewarded(), RewardedContinueOutcome.rewarded);
      expect(gate.rewarded, isTrue);
    });

    test('rewarded state remains idempotent on duplicate callbacks', () {
      final gate = RewardedContinueGate();
      gate.markStart(true);
      gate.markRewarded();

      expect(gate.markRewarded(), RewardedContinueOutcome.rewarded);
      expect(gate.rewarded, isTrue);
    });
  });
}
