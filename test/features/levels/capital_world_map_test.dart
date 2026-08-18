import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:cargo_sort_game/features/levels/capital_world_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('geographic projection keeps world coordinates inside the map', () {
    const size = Size(360, 310);

    expect(projectCapital(82, -180, size), const Offset(0, 0));
    expect(projectCapital(-68, 180, size), const Offset(360, 310));

    final cairo = projectCapital(30.04, 31.24, size);
    final tokyo = projectCapital(35.68, 139.69, size);
    expect(cairo.dx, inInclusiveRange(0, size.width));
    expect(cairo.dy, inInclusiveRange(0, size.height));
    expect(tokyo.dx, greaterThan(cairo.dx));
  });

  testWidgets(
    'capital map exposes the current real destination and selects it',
    (tester) async {
      LevelData? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: CapitalWorldMap(
                levels: levels.take(25).toList(),
                highestUnlockedLevel: 1,
                selectedLevel: 1,
                starsForLevel: (_) => 0,
                isArabic: false,
                accent: const Color(0xFFFFC857),
                onSelect: (level) => selected = level,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('Portugal'), findsOneWidget);

      await tester.tap(find.text('Lisbon'));
      await tester.pump();
      expect(selected?.number, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
