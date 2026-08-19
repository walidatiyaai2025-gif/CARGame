import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:cargo_sort_game/core/motion/game_travel_motion.dart';
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

  testWidgets('manual pause remains authoritative across lifecycle resume', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: _buildGame()),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('game-pause-button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('game-pause-overlay')), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.byKey(const ValueKey('game-pause-overlay')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('game-resume-button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('game-pause-overlay')), findsNothing);
  });

  testWidgets('lifecycle pause freezes in-flight cargo without consuming a move', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: _buildGame()),
    );
    await tester.pump();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('house-1-cargo-1-0')),
    );
    await tester.pump();

    final warehouse = find.byKey(const ValueKey('warehouse-1'));
    final viewport = Offset.zero & tester.binding.renderViews.single.size;
    final target = tester.getRect(warehouse).intersect(viewport);
    expect(target.isEmpty, isFalse);
    await tester.tapAt(target.center);
    await tester.pump();
    expect(find.byType(GameTravelMotion), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(GameTravelMotion), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('game-moves')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump();

    expect(find.byType(GameTravelMotion), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('game-moves')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });
}

GameScreen _buildGame() {
  final cargo = productCatalog.first;
  return GameScreen(
    level: LevelData(
      number: 1,
      world: 1,
      moves: 4,
      items: [cargo, cargo],
      difficulty: 1,
    ),
    store: ProgressStore(),
    adService: _FakeAdService(),
    hapticsEnabled: false,
    soundEnabled: false,
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

class _FakeAdService extends AdService {
  @override
  void preload() {}

  @override
  void dispose() {}
}
