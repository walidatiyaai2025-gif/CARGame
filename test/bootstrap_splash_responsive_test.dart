import 'package:cargo_sort_game/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> pumpSplash(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const BootstrapApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
  }

  Future<void> disposeSplash(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 7));
  }

  Finder splashStatus() => find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    return const <String>{
      'Preparing your cargo journey...',
      'Starting secure services...',
      'Loading player profile...',
      'Opening the warehouse...',
    }.contains(widget.data);
  });

  testWidgets('startup splash is usable on a narrow phone', (tester) async {
    await pumpSplash(tester, size: const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text('CARGO SORT'), findsOneWidget);
    expect(find.text('Version $appVersion ($appBuildNumber)'), findsOneWidget);
    expect(find.text(appAuthor), findsOneWidget);
    expect(splashStatus(), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await disposeSplash(tester);
  });

  testWidgets('startup splash survives large text on a tablet', (
    tester,
  ) async {
    await pumpSplash(
      tester,
      size: const Size(1024, 1366),
      textScale: 1.8,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('CARGO SORT'), findsOneWidget);
    expect(find.text('Version $appVersion ($appBuildNumber)'), findsOneWidget);
    expect(find.text(appAuthor), findsOneWidget);
    expect(splashStatus(), findsOneWidget);

    await tester.ensureVisible(find.text(appAuthor));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await disposeSplash(tester);
  });
}
