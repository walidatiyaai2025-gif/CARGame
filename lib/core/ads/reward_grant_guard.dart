/// One-shot guard for rewarded-ad economy callbacks.
///
/// Google Mobile Ads may deliver lifecycle callbacks independently from the
/// reward callback. Economy mutation must therefore be driven only by the
/// explicit reward signal and must be idempotent for a single ad instance.
final class RewardGrantGuard {
  bool _claimed = false;

  bool claim() {
    if (_claimed) return false;
    _claimed = true;
    return true;
  }

  bool get claimed => _claimed;
}
