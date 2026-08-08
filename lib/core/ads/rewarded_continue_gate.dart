enum RewardedContinueOutcome {
  unavailable,
  started,
  rewarded,
}

/// Coordinates the loss-screen rewarded-continue flow without mutating
/// gameplay state until the ad SDK confirms a real reward.
///
/// UI contract:
/// - [unavailable]: keep the result sheet open so Retry remains reachable.
/// - [started]: the ad started; the sheet may be hidden while playback occurs.
/// - [rewarded]: grant the continue exactly once and resume gameplay.
final class RewardedContinueGate {
  bool _started = false;
  bool _rewarded = false;

  bool get started => _started;
  bool get rewarded => _rewarded;

  RewardedContinueOutcome markStart(bool didStart) {
    if (!didStart) {
      return RewardedContinueOutcome.unavailable;
    }
    _started = true;
    return RewardedContinueOutcome.started;
  }

  RewardedContinueOutcome markRewarded() {
    if (!_started || _rewarded) {
      return _rewarded
          ? RewardedContinueOutcome.rewarded
          : RewardedContinueOutcome.unavailable;
    }
    _rewarded = true;
    return RewardedContinueOutcome.rewarded;
  }
}
