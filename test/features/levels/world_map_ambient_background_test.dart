import 'package:cargo_sort_game/features/levels/world_map_ambient_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders with scrollable world content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            const Positioned.fill(
              child: WorldMapAmbientBackground(
                startColor: Colors.indigo,
                endColor: Colors.teal,
              ),
            ),
            ListView(children: const [SizedBox(height: 1600)]),
          ],
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(WorldMapAmbientBackground), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('honors reduced motion without ticker leaks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: WorldMapAmbientBackground(
            startColor: Colors.indigo,
            endColor: Colors.teal,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
