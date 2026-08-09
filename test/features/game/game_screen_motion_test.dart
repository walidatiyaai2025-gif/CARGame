import 'dart:math';

import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:cargo_sort_game/core/motion/game_action_feedback.dart';
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

  testWidgets('gameplay ignores warehouse input while cargo is resolving', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cargo = productCatalog.first;
    final sounds = <(GameActionFeedbackKind, int)>[];
    final level = LevelData(
      number: 1,
      world: 1,
      moves: 4,
      items: [cargo, cargo],
      difficulty: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: level,
          store: ProgressStore(),
          adService: _FakeAdService(),
          hapticsEnabled: false,
          onPlacementSound: (kind, intensity) => sounds.add((kind, intensity)),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('cargo-1-0')));
    await tester.pump();

    final warehouse = find.byKey(const ValueKey('warehouse-1'));
    final viewport = Offset.zero & tester.binding.renderViews.single.size;
    final visibleTarget = tester.getRect(warehouse).intersect(viewport);
    expect(visibleTarget.isEmpty, isFalse);

    await tester.tapAt(visibleTarget.center);
    await tester.tapAt(visibleTarget.center);
    await tester.pump();

    expect(find.byType(GameTravelMotion), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(find.byType(GameTravelMotion), findsNothing);
    expect(find.byType(GameActionFeedback), findsOneWidget);

    final currentVisibleTarget = tester.getRect(warehouse).intersect(viewport);
    expect(currentVisibleTarget.isEmpty, isFalse);
    await tester.tapAt(currentVisibleTarget.center);
    await tester.pump();
    expect(find.byKey(const ValueKey('cargo-1-0')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('game-moves')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(sounds, [(GameActionFeedbackKind.correct, 1)]);

    await tester.pump(const Duration(milliseconds: 720));
    expect(find.byType(GameActionFeedback), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('game-moves')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'gameplay ignores cargo reselection while feedback is resolving',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final first = productCatalog[0];
      final second = productCatalog[1];
      final level = LevelData(
        number: 1,
        world: 1,
        moves: 4,
        items: [first, second],
        difficulty: 1,
      );
      final shuffled = [...level.items]..shuffle(Random(level.number * 41));
      final selected = shuffled[0];
      final remaining = shuffled[1];
      final sounds = <(GameActionFeedbackKind, int)>[];

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: level,
            store: ProgressStore(),
            adService: _FakeAdService(),
            hapticsEnabled: false,
            onPlacementSound: (kind, intensity) =>
                sounds.add((kind, intensity)),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(ValueKey('cargo-${selected.id}-0')));
      await tester.pump();

      final selectedWarehouse = find.byKey(
        ValueKey('warehouse-${selected.id}'),
      );
      final viewport = Offset.zero & tester.binding.renderViews.single.size;
      final selectedTarget = tester
          .getRect(selectedWarehouse)
          .intersect(viewport);
      expect(selectedTarget.isEmpty, isFalse);

      await tester.tapAt(selectedTarget.center);
      await tester.pump(const Duration(milliseconds: 260));
      await tester.pump();

      expect(find.byType(GameActionFeedback), findsOneWidget);

      final remainingCargo = find.byKey(ValueKey('cargo-${remaining.id}-0'));
      expect(remainingCargo, findsOneWidget);
      await tester.tap(remainingCargo);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 720));
      expect(find.byType(GameActionFeedback), findsNothing);

      final remainingWarehouse = find.byKey(
        ValueKey('warehouse-${remaining.id}'),
      );
      final remainingTarget = tester
          .getRect(remainingWarehouse)
          .intersect(viewport);
      expect(remainingTarget.isEmpty, isFalse);

      await tester.tapAt(remainingTarget.center);
      await tester.pump();

      expect(find.byType(GameTravelMotion), findsNothing);
      expect(remainingCargo, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('game-moves')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(sounds, [(GameActionFeedbackKind.correct, 1)]);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeAdService extends AdService {
  @override
  void preload() {}

  @override
  void dispose() {}
}
