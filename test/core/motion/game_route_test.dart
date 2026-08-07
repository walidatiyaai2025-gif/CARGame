import 'package:cargo_sort_game/core/motion/game_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds a named route and reaches the destination', (
    tester,
  ) async {
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
    await tester.pump();
    await tester.pump(GameRoute.forwardDuration);
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
    PageRouteBuilder<void>? route;
    BuildContext? routeContext;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              routeContext = context;
              return TextButton(
                onPressed: () {
                  final builtRoute = GameRoute.build<void>(
                    context: context,
                    builder: (_) => const Scaffold(body: Text('Reduced')),
                  );
                  route = builtRoute as PageRouteBuilder<void>;
                  Navigator.of(context).push(builtRoute);
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(route, isNotNull);
    expect(route!.transitionDuration, const Duration(milliseconds: 120));
    final transition = route!.transitionsBuilder(
      routeContext!,
      const AlwaysStoppedAnimation<double>(0.5),
      const AlwaysStoppedAnimation<double>(0),
      const SizedBox(),
    );
    expect(transition, isA<FadeTransition>());
    expect(transition, isNot(isA<SlideTransition>()));

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Reduced'), findsOneWidget);
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
