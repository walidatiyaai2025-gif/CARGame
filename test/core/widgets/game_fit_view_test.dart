import 'package:cargo_sort_game/core/widgets/game_fit_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scales oversized bounded content without introducing scroll', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameFitView(
            child: SizedBox(width: 360, height: 900, child: ColoredBox(color: Colors.blue)),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);

    final fit = tester.widget<FittedBox>(find.byType(FittedBox));
    expect(fit.fit, BoxFit.scaleDown);
  });

  testWidgets('preserves RTL direction from caller', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: GameFitView(child: Text('مرحبا')),
        ),
      ),
    );

    expect(Directionality.of(tester.element(find.text('مرحبا'))), TextDirection.rtl);
  });
}
