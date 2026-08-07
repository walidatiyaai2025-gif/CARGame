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
    expect(find.textContaining('...'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 7));
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
    expect(find.textContaining('...'), findsOneWidget);

    await tester.ensureVisible(find.text(appAuthor));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 7));
  });
}
