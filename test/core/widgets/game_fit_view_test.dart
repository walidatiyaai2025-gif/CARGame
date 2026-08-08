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
            child: SizedBox(
              width: 360,
              height: 900,
              child: ColoredBox(color: Colors.blue),
            ),
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

    expect(
      Directionality.of(tester.element(find.text('مرحبا'))),
      TextDirection.rtl,
    );
  });

  testWidgets('keeps bounded content stable on a tablet viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1366));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: GameFitView(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                key: Key('tablet-content'),
                width: 720,
                height: 980,
                child: ColoredBox(color: Colors.green),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsNothing);
    expect(find.byKey(const Key('tablet-content')), findsOneWidget);
  });

  testWidgets('survives large text, cutouts and keyboard insets', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const media = MediaQueryData(
      size: Size(412, 915),
      padding: EdgeInsets.only(top: 44, bottom: 34),
      viewPadding: EdgeInsets.only(top: 44, bottom: 34),
      viewInsets: EdgeInsets.only(bottom: 280),
      textScaler: TextScaler.linear(2),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: media,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: GameFitView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Large accessible heading'),
                      SizedBox(height: 16),
                      Text(
                        'This bounded content remains visible when text is enlarged.',
                      ),
                      SizedBox(height: 320),
                      TextField(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Large accessible heading'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
