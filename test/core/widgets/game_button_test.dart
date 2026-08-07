import 'dart:async';

import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    Widget child, {
    TextDirection direction = TextDirection.ltr,
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );

  testWidgets('runs async action only once while busy', (tester) async {
    final gate = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(
      host(
        GameButton(
          semanticLabel: 'Start',
          hapticsEnabled: false,
          onPressed: () async {
            calls++;
            await gate.future;
          },
          child: const Text('Start'),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.tap(find.byType(GameButton));
    await tester.pump();

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('disabled button ignores taps', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        GameButton(
          semanticLabel: 'Disabled action',
          enabled: false,
          hapticsEnabled: false,
          onPressed: () => calls++,
          child: const Text('Disabled'),
        ),
      ),
    );

    await tester.tap(find.byType(GameButton));
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('supports externally controlled loading state', (tester) async {
    await tester.pumpWidget(
      host(
        const GameButton(
          semanticLabel: 'Loading action',
          loading: true,
          hapticsEnabled: false,
          onPressed: null,
          child: Text('Save'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('renders in RTL without changing child order contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        GameButton(
          semanticLabel: 'Arabic action',
          hapticsEnabled: false,
          onPressed: () {},
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.play_arrow), Text('ابدأ')],
          ),
        ),
        direction: TextDirection.rtl,
      ),
    );

    expect(find.text('ابدأ'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('ابدأ'))),
      TextDirection.rtl,
    );
  });

  testWidgets('invokes optional sound hook before action', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(
      host(
        GameButton(
          hapticsEnabled: false,
          onSound: () => events.add('sound'),
          onPressed: () => events.add('action'),
          child: const Text('Play'),
        ),
      ),
    );

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(events, ['sound', 'action']);
  });

  testWidgets('configured height is a minimum and grows for large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        GameButton(
          height: 68,
          expand: true,
          hapticsEnabled: false,
          onPressed: () {},
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('START MISSION'),
              Text('A deliberately longer accessible destination label'),
            ],
          ),
        ),
        textScaler: const TextScaler.linear(1.8),
      ),
    );

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(GameButton));
    expect(size.height, greaterThanOrEqualTo(68));
    expect(size.height, greaterThan(68));
  });
}
