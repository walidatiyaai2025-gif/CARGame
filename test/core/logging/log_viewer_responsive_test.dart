import 'package:cargo_sort_game/core/logging/log_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child, {
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('log viewer is overflow-free on a narrow phone', (tester) async {
    await _pumpAtSize(
      tester,
      const LogViewerScreen(),
      size: const Size(360, 640),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Application Logs'), findsOneWidget);
    expect(find.text('Copy complete log'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('log viewer supports large text on a tablet', (tester) async {
    await _pumpAtSize(
      tester,
      const LogViewerScreen(),
      size: const Size(1024, 1366),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Application Logs'), findsOneWidget);
    expect(find.text('Copy complete log'), findsOneWidget);
  });

  testWidgets('fatal error screen is overflow-free on a narrow phone', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      FatalErrorScreen(
        error: StateError('startup failed'),
        stackTrace: StackTrace.fromString('frame one\nframe two'),
      ),
      size: const Size(360, 640),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Application Error'), findsOneWidget);
    expect(find.text('Copy error'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('fatal error screen supports large text on a tablet', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      FatalErrorScreen(
        error: StateError('startup failed'),
        stackTrace: StackTrace.fromString('frame one\nframe two'),
      ),
      size: const Size(1024, 1366),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Application Error'), findsOneWidget);
    expect(find.text('Copy error'), findsOneWidget);
  });
}
