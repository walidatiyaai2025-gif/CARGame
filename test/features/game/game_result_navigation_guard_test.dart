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

  testWidgets('repeated Next action pops the game route only once', (tester) async {
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
    await tester.pumpAndSettle();

    Future<void> pumpUntil(
      Finder finder, {
      Duration step = const Duration(milliseconds: 50),
      int maxPumps = 30,
    }) async {
      for (var attempt = 0; attempt < maxPumps; attempt++) {
        if (finder.evaluate().isNotEmpty) return;
        await tester.pump(step);
      }
      expect(finder, findsWidgets);
    }

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

      for (var attempt = 0; attempt < 30; attempt++) {
        if (find.byType(GameActionFeedback).evaluate().isEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(GameActionFeedback), findsNothing);
    }

    await placeCargo();
    await placeCargo();
    await tester.pumpAndSettle();

    final next = find.text('NEXT — BACK TO MAP');
    expect(next, findsOneWidget);

    await tester.tap(next);
    await tester.tap(next, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(observer.gameRoutePops, 1);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byKey(const ValueKey('open-game')), findsOneWidget);
  });
}

class _GameRouteObserver extends NavigatorObserver {
  int gameRoutePops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == 'game') {
      gameRoutePops++;
    }
    super.didPop(route, previousRoute);
  }
}

class _FakeAdService extends AdService {
  @override
  void preload() {}

  @override
  void dispose() {}
}
