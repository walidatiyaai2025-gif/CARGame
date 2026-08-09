import 'dart:async';

import '../application/optional_service_port.dart';

export '../domain/optional_service_state.dart';

class OptionalServiceCoordinator implements OptionalServicePort {
  OptionalServiceCoordinator({
    this.defaultTimeout = const Duration(seconds: 15),
    this.maxAttempts = 3,
  }) : assert(maxAttempts > 0);

  final Duration defaultTimeout;
  final int maxAttempts;

  final Map<String, OptionalServiceSnapshot> _snapshots = {};
  final Map<String, Future<bool>> _running = {};
  final StreamController<OptionalServiceSnapshot> _changes =
      StreamController<OptionalServiceSnapshot>.broadcast(sync: true);

  @override
  Stream<OptionalServiceSnapshot> get changes => _changes.stream;

  @override
  OptionalServiceSnapshot snapshot(String name) =>
      _snapshots[name] ??
      OptionalServiceSnapshot(
        name: name,
        status: OptionalServiceStatus.idle,
        attempts: 0,
      );

  @override
  Future<bool> initialize(
    String name,
    Future<void> Function() action, {
    Duration? timeout,
  }) {
    final current = snapshot(name);
    if (current.isReady) return Future<bool>.value(true);
    if (current.attempts >= maxAttempts) return Future<bool>.value(false);

    final existing = _running[name];
    if (existing != null) return existing;

    final future = _run(name, action, timeout: timeout ?? defaultTimeout);
    _running[name] = future;
    unawaited(future.whenComplete(() => _running.remove(name)));
    return future;
  }

  @override
  Future<bool> retry(
    String name,
    Future<void> Function() action, {
    Duration? timeout,
  }) => initialize(name, action, timeout: timeout);

  Future<bool> _run(
    String name,
    Future<void> Function() action, {
    required Duration timeout,
  }) async {
    final attempts = snapshot(name).attempts + 1;
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

  @override
  Future<void> dispose() => _changes.close();
}
