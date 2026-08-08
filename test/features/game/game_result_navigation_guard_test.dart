import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:cargo_sort_game/core/motion/game_action_feedback.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
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

    Future<void> pumpUntil(
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

    Future<void> pumpUntilAbsent(
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
    await pumpUntil(find.byType(GameScreen));
    expect(find.byType(GameScreen), findsOneWidget);

    Future<void> placeCargo() async {
      await tester.tap(find.byKey(const ValueKey('cargo-1-0')));
      await tester.pump();

      final warehouse = find.byKey(const ValueKey('warehouse-1'));
      final viewport = Offset.zero & tester.binding.renderViews.single.size;
      final target = tester.getRect(warehouse).intersect(viewport);
      expect(target.isEmpty, isFalse);

      await tester.tapAt(target.center);
      await pumpUntil(find.byType(GameActionFeedback));
      expect(find.byType(GameActionFeedback), findsOneWidget);
      await pumpUntilAbsent(find.byType(GameActionFeedback));
    }

    await placeCargo();
    await placeCargo();

    final next = find.bySemanticsLabel('Next and back to map');
    await pumpUntil(next);
    expect(next, findsOneWidget);

    // The result sheet is intentionally scrollable. Bring the CTA into the
    // actual hit-test viewport before exercising the rapid repeated action.
    await tester.scrollUntilVisible(
      next,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    // Queue two activations before the widget can rebuild. This models the
    // actual double-tap race while keeping both taps targeted at the CTA.
    await tester.tap(next);
    await tester.tap(next);
    await pumpUntilAbsent(find.byType(GameScreen));

    expect(observer.gameRouteExits, 1);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byKey(const ValueKey('open-game')), findsOneWidget);
  });
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
