import 'dart:async';

import 'package:cargo_sort_game/core/navigation/game_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(GameNavigator.resetGuards);

  testWidgets('push uses named shared route and returns result', (
    tester,
  ) async {
    String? observedName;
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [_RouteNameObserver((name) => observedName = name)],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await GameNavigator.push<String>(
                context,
                name: '/target',
                builder: (_) => Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => Navigator.of(context).pop('done'),
                      child: const Text('Finish'),
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(observedName, '/target');

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(result, 'done');
  });

  testWidgets('guardKey prevents duplicate concurrent pushes', (tester) async {
    final firstCanClose = Completer<void>();
    var builds = 0;
    var secondCompleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              unawaited(
                GameNavigator.push<void>(
                  context,
                  guardKey: 'journey',
                  builder: (_) {
                    builds++;
                    return _HeldRoute(canClose: firstCanClose.future);
                  },
                ),
              );
              unawaited(
                GameNavigator.push<void>(
                  context,
                  guardKey: 'journey',
                  builder: (_) {
                    builds++;
                    return const Scaffold(body: Text('Duplicate'));
                  },
                ).whenComplete(() {
                  secondCompleted = true;
                }),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(builds, 1);
    expect(find.text('Duplicate'), findsNothing);
    expect(secondCompleted, isTrue);

    firstCanClose.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('replace swaps the active route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => GameNavigator.replace<void, void>(
              context,
              name: '/replacement',
              builder: (_) => const Scaffold(body: Text('Replacement')),
            ),
            child: const Text('Replace'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(find.text('Replacement'), findsOneWidget);
    expect(find.text('Replace'), findsNothing);
  });
}

final class _RouteNameObserver extends NavigatorObserver {
  _RouteNameObserver(this.onName);

  final ValueChanged<String?> onName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onName(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

final class _HeldRoute extends StatefulWidget {
  const _HeldRoute({required this.canClose});

  final Future<void> canClose;

  @override
  State<_HeldRoute> createState() => _HeldRouteState();
}

final class _HeldRouteState extends State<_HeldRoute> {
  @override
  void initState() {
    super.initState();
    unawaited(
      widget.canClose.then((_) {
        if (mounted) Navigator.of(context).pop();
      }),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Held'));
}
