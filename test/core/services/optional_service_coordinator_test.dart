import 'dart:async';

import 'package:cargo_sort_game/core/services/optional_service_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OptionalServiceCoordinator', () {
    test('reports ready when optional service initializes', () async {
      final coordinator = OptionalServiceCoordinator();

      final result = await coordinator.initialize('ads', () async {});

      expect(result, isTrue);
      expect(coordinator.snapshot('ads').status, OptionalServiceStatus.ready);
      expect(coordinator.snapshot('ads').attempts, 1);
      await coordinator.dispose();
    });

    test('reports unavailable without throwing into core flow', () async {
      final coordinator = OptionalServiceCoordinator();

      final result = await coordinator.initialize(
        'analytics',
        () async => throw StateError('offline'),
      );

      expect(result, isFalse);
      expect(
        coordinator.snapshot('analytics').status,
        OptionalServiceStatus.unavailable,
      );
      expect(coordinator.snapshot('analytics').lastError, isA<StateError>());
      await coordinator.dispose();
    });

    test('times out independently', () async {
      final coordinator = OptionalServiceCoordinator(
        defaultTimeout: const Duration(milliseconds: 10),
      );
      final never = Completer<void>();

      final result = await coordinator.initialize('remote', () => never.future);

      expect(result, isFalse);
      expect(coordinator.snapshot('remote').lastError, isA<TimeoutException>());
      await coordinator.dispose();
    });

    test('deduplicates concurrent initialization', () async {
      final coordinator = OptionalServiceCoordinator();
      final gate = Completer<void>();
      var calls = 0;

      final first = coordinator.initialize('ads', () async {
        calls++;
        await gate.future;
      });
      final second = coordinator.initialize('ads', () async {
        calls++;
      });

      gate.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(calls, 1);
      await coordinator.dispose();
    });

    test('supports safe retry after failure', () async {
      final coordinator = OptionalServiceCoordinator(maxAttempts: 2);
      var calls = 0;

      expect(
        await coordinator.initialize('ads', () async {
          calls++;
          throw StateError('offline');
        }),
        isFalse,
      );
      expect(
        await coordinator.retry('ads', () async {
          calls++;
        }),
        isTrue,
      );
      expect(calls, 2);
      expect(coordinator.snapshot('ads').status, OptionalServiceStatus.ready);
      await coordinator.dispose();
    });
  });
}
