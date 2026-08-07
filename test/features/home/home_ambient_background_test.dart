import 'package:cargo_sort_game/features/home/home_ambient_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and disposes without ticker leaks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeAmbientBackground(
          startColor: Colors.blue,
          endColor: Colors.orange,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(HomeAmbientBackground), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: HomeAmbientBackground(
            startColor: Colors.blue,
            endColor: Colors.orange,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
