import 'package:cargo_sort_game/features/game/cargo_motion_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cargo tile supports pickup and busy states', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CargoMotionTile(
            selected: true,
            busy: false,
            child: SizedBox(key: Key('cargo'), width: 80, height: 80),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('cargo')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('warehouse target supports correct placement settle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WarehouseMotionTarget(
            active: true,
            correct: true,
            child: SizedBox(key: Key('warehouse'), width: 80, height: 80),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('warehouse')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('motion primitives respect reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: CargoMotionTile(
              selected: true,
              busy: false,
              child: SizedBox(width: 60, height: 60),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
  });
}
