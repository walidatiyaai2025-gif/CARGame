import 'dart:async';

enum OptionalServiceStatus {
  idle,
  running,
  ready,
  unavailable,
}

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

class OptionalServiceCoordinator {
  OptionalServiceCoordinator({
    this.defaultTimeout = const Duration(seconds: 15),
    this.maxAttempts = 3,
  });

  final Duration defaultTimeout;
  final int maxAttempts;

  final Map<String, OptionalServiceSnapshot> _snapshots = {};
  final Map<String, Future<bool>> _running = {};
  final StreamController<OptionalServiceSnapshot> _changes =
      StreamController<OptionalServiceSnapshot>.broadcast(sync: true);

  Stream<OptionalServiceSnapshot> get changes => _changes.stream;

  OptionalServiceSnapshot snapshot(String name) =>
      _snapshots[name] ??
      OptionalServiceSnapshot(
        name: name,
        status: OptionalServiceStatus.idle,
        attempts: 0,
      );

  Future<bool> initialize(
    String name,
    Future<void> Function() action, {
    Duration? timeout,
    bool forceRetry = false,
  }) {
    final current = snapshot(name);
    if (current.isReady && !forceRetry) {
      return Future<bool>.value(true);
    }
    if (current.attempts >= maxAttempts && !forceRetry) {
      return Future<bool>.value(false);
    }

    final existing = _running[name];
    if (existing != null) return existing;

    final future = _run(
      name,
      action,
      timeout: timeout ?? defaultTimeout,
      forceRetry: forceRetry,
    );
    _running[name] = future;
    future.whenComplete(() => _running.remove(name));
    return future;
  }

  Future<bool> retry(
    String name,
    Future<void> Function() action, {
    Duration? timeout,
  }) =>
      initialize(name, action, timeout: timeout, forceRetry: true);

  Future<bool> _run(
    String name,
    Future<void> Function() action, {
    required Duration timeout,
    required bool forceRetry,
  }) async {
    final previous = snapshot(name);
    final attempts = forceRetry && previous.attempts >= maxAttempts
        ? 1
        : previous.attempts + 1;
    _publish(
      OptionalServiceSnapshot(
        name: name,
        status: OptionalServiceStatus.running,
        attempts: attempts,
      ),
    );

    try {
      await action().timeout(timeout);
      _publish(
        OptionalServiceSnapshot(
          name: name,
          status: OptionalServiceStatus.ready,
          attempts: attempts,
        ),
      );
      return true;
    } catch (error) {
      _publish(
        OptionalServiceSnapshot(
          name: name,
          status: OptionalServiceStatus.unavailable,
          attempts: attempts,
          lastError: error,
        ),
      );
      return false;
    }
  }

  void _publish(OptionalServiceSnapshot value) {
    _snapshots[value.name] = value;
    if (!_changes.isClosed) _changes.add(value);
  }

  Future<void> dispose() => _changes.close();
}
