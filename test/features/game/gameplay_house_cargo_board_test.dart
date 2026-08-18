import 'package:cargo_sort_game/features/game/gameplay_house_cargo_board.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('level one renders nine cargo items across three houses', (
    tester,
  ) async {
    final level = generateLevel(1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 720,
            child: GameplayHouseCargoBoard(
              items: level.items,
              houseAssignments: level.houseAssignments,
              houseCount: level.houseCount,
              selectedIndex: null,
              travellingIndex: null,
              onTap: (_, __, ___) {},
              compact: false,
              isArabic: false,
              accent: const Color(0xFF2D6CDF),
              levelNumber: level.number,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CARGO BAY • HOUSES'), findsOneWidget);
    expect(find.text('3 HOUSES'), findsOneWidget);
    expect(find.text('HOUSE 1'), findsOneWidget);
    expect(find.text('HOUSE 2'), findsOneWidget);
    expect(find.text('HOUSE 3'), findsOneWidget);

    final houseCounts = <int, int>{1: 0, 2: 0, 3: 0};
    for (final house in level.houseAssignments) {
      houseCounts[house] = houseCounts[house]! + 1;
    }
    expect(houseCounts.values, everyElement(3));
  });

  testWidgets('house cargo tap preserves the flat gameplay item index', (
    tester,
  ) async {
    final level = generateLevel(1);
    int? tappedIndex;
    CargoItem? tappedItem;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 720,
            child: GameplayHouseCargoBoard(
              items: level.items,
              houseAssignments: level.houseAssignments,
              houseCount: level.houseCount,
              selectedIndex: null,
              travellingIndex: null,
              onTap: (item, index, _) {
                tappedItem = item;
                tappedIndex = index;
              },
              compact: false,
              isArabic: false,
              accent: const Color(0xFF2D6CDF),
              levelNumber: level.number,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstKey = ValueKey(
      'house-${level.houseAssignments.first}-cargo-${level.items.first.id}-0',
    );
    await tester.tap(find.byKey(firstKey));
    await tester.pump();

    expect(tappedIndex, 0);
    expect(tappedItem, same(level.items.first));
  });
}
