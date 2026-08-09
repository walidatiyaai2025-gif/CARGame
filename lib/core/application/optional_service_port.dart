import 'dart:async';

import '../domain/optional_service_state.dart';

export '../domain/optional_service_state.dart';

abstract interface class OptionalServicePort {
  Stream<OptionalServiceSnapshot> get changes;

  OptionalServiceSnapshot snapshot(String name);

  Future<bool> initialize(
    String name,
    Future<void> Function() action, {
    Duration? timeout,
  });

  Future<bool> retry(
    String name,
    Future<void> Function() action, {
    Duration? timeout,
  });

  Future<void> dispose();
}
