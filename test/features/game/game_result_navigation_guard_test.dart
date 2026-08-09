import 'dart:math';

import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:cargo_sort_game/core/motion/game_action_feedback.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/features/game/game_screen.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('repeated Next action exits the game route only once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final observer = _GameRouteObserver();
    final cargo = productCatalog.first;
    final level = LevelData(
      number: 1,
      world: 1,
      moves: 4,
      items: [cargo, cargo],
      difficulty: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('open-game'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: 'game'),
                      builder: (_) => GameScreen(
                        level: level,
                        store: ProgressStore(),
                        adService: _FakeAdService(),
                        hapticsEnabled: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open game'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-game')));
    await _pumpUntil(tester, find.byType(GameScreen));
    expect(find.byType(GameScreen), findsOneWidget);

    Future<void> placeCargo() async {
      await tester.tap(find.byKey(const ValueKey('cargo-1-0')));
      await tester.pump();

      final warehouse = find.byKey(const ValueKey('warehouse-1'));
      final viewport = Offset.zero & tester.binding.renderViews.single.size;
      final target = tester.getRect(warehouse).intersect(viewport);
      expect(target.isEmpty, isFalse);

      await tester.tapAt(target.center);
      await _pumpUntil(tester, find.byType(GameActionFeedback));
      expect(find.byType(GameActionFeedback), findsOneWidget);
      await _pumpUntilAbsent(tester, find.byType(GameActionFeedback));
    }

    await placeCargo();
    await placeCargo();

    final next = find.bySemanticsLabel('Next and back to map');
    await _pumpUntil(tester, next);
    expect(next, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));

    final nextButtonFinder = find.ancestor(
      of: next,
      matching: find.byType(GameButton),
    );
    expect(nextButtonFinder, findsOneWidget);
    final nextButton = tester.widget<GameButton>(nextButtonFinder);
    expect(nextButton.onPressed, isNotNull);

    final firstAction = Future<void>.sync(() async {
      await nextButton.onPressed!.call();
    });
    final secondAction = Future<void>.sync(() async {
      await nextButton.onPressed!.call();
    });

    await tester.pump();
    await Future.wait([firstAction, secondAction]);
    await _pumpUntilAbsent(tester, find.byType(GameScreen));

    expect(observer.gameRouteExits, 1);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byKey(const ValueKey('open-game')), findsOneWidget);
  });

  testWidgets('repeated Retry action resets gameplay without duplicate loss', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = ProgressStore();
    await store.load();
    addTearDown(store.dispose);
    final initialHearts = store.hearts;

    final first = productCatalog[0];
    final second = productCatalog[1];
    final level = LevelData(
      number: 1,
      world: 1,
      moves: 1,
      items: [first, second],
      difficulty: 1,
    );
    final shuffled = [...level.items]..shuffle(Random(level.number * 41));
    final selected = shuffled.first;
    final wrongWarehouse = selected.id == first.id ? second : first;

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: level,
          store: store,
          adService: _FakeAdService(),
          hapticsEnabled: false,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(ValueKey('cargo-${selected.id}-0')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('warehouse-${wrongWarehouse.id}')));
    await _pumpUntil(tester, find.byType(GameActionFeedback));
    await _pumpUntilAbsent(tester, find.byType(GameActionFeedback));

    final retry = find.bySemanticsLabel('Retry');
    await _pumpUntil(tester, retry);
    await tester.pump(const Duration(milliseconds: 500));
    expect(store.hearts, initialHearts - 1);

    final retryButtonFinder = find.ancestor(
      of: retry,
      matching: find.byType(GameButton),
    );
    expect(retryButtonFinder, findsOneWidget);
    final retryButton = tester.widget<GameButton>(retryButtonFinder);
    expect(retryButton.onPressed, isNotNull);

    final firstAction = Future<void>.sync(() async {
      await retryButton.onPressed!.call();
    });
    final secondAction = Future<void>.sync(() async {
      await retryButton.onPressed!.call();
    });

    await tester.pump();
    await Future.wait([firstAction, secondAction]);
    await tester.pump();

    expect(find.byType(GameScreen), findsOneWidget);
    expect(retry, findsNothing);
    expect(store.hearts, initialHearts - 1);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('game-moves')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 50),
  int maxPumps = 40,
}) async {
  for (var attempt = 0; attempt < maxPumps; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }
  expect(finder, findsWidgets);
}

Future<void> _pumpUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 50),
  int maxPumps = 40,
}) async {
  for (var attempt = 0; attempt < maxPumps; attempt++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(step);
  }
  expect(finder, findsNothing);
}

class _GameRouteObserver extends NavigatorObserver {
  int gameRouteExits = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == 'game') {
      gameRouteExits++;
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == 'game') {
      gameRouteExits++;
    }
    super.didRemove(route, previousRoute);
  }
}

class _FakeAdService extends AdService {
  @override
  void preload() {}

  @override
  void dispose() {}
}
