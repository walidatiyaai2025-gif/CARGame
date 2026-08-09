enum OptionalServiceStatus { idle, running, ready, unavailable }

class OptionalServiceSnapshot {
  const OptionalServiceSnapshot({
    required this.name,
    required this.status,
    required this.attempts,
    this.lastError,
  });

  final String name;
  final OptionalServiceStatus status;
  final int attempts;
  final Object? lastError;

  bool get isReady => status == OptionalServiceStatus.ready;
  bool get canRetry => status == OptionalServiceStatus.unavailable;
}
