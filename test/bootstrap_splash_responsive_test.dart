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

  Future<void> drainBootstrapTimers(WidgetTester tester) async {
    // Bootstrap intentionally owns bounded startup timers (minimum splash,
    // optional local-service timeouts, and background ads initialization).
    // Advance fake time through those lifetimes before ending the widget test
    // so responsive assertions do not leave legitimate startup timers pending.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 25));
  }

  testWidgets('startup splash is overflow-free on a narrow phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const BootstrapApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.text('CARGO SORT'), findsOneWidget);
    expect(find.text('Version $appVersion ($appBuildNumber)'), findsOneWidget);
    expect(find.text(appAuthor), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await drainBootstrapTimers(tester);
  });

  testWidgets('startup splash supports large text on a tablet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1366));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(const BootstrapApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.text('CARGO SORT'), findsOneWidget);
    expect(find.text('SORT • SHIP • CONQUER'), findsOneWidget);
    expect(find.text('Version $appVersion ($appBuildNumber)'), findsOneWidget);
    expect(find.text(appAuthor), findsOneWidget);

    await drainBootstrapTimers(tester);
  });
}
