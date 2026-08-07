import 'package:cargo_sort_game/core/motion/game_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds a named route and reaches the destination', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              GameRoute.build<void>(
                context: context,
                name: '/next',
                builder: (_) => const Scaffold(body: Text('Next screen')),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Next screen'), findsOneWidget);
  });

  testWidgets('uses slide transition in normal motion mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              GameRoute.build<void>(
                context: context,
                builder: (_) => const Scaffold(body: Text('Destination')),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.byType(SlideTransition), findsWidgets);
    expect(find.byType(FadeTransition), findsWidgets);
  });

  testWidgets('removes slide transition when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                GameRoute.build<void>(
                  context: context,
                  builder: (_) => const Scaffold(body: Text('Reduced')),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Reduced'), findsOneWidget);
    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(SlideTransition), findsNothing);
  });

  testWidgets('supports RTL navigation without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                GameRoute.build<void>(
                  context: context,
                  builder: (_) => const Scaffold(body: Text('RTL target')),
                ),
              ),
              child: const Text('Open RTL'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open RTL'));
    await tester.pumpAndSettle();
    expect(find.text('RTL target'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
