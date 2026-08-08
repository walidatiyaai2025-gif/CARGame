import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/widgets/game_fit_view.dart';
import 'package:cargo_sort_game/features/settings/settings_screen.dart';
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

  Future<void> pumpSettings(
    WidgetTester tester, {
    required Size size,
    TextScaler textScaler = TextScaler.noScaling,
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: textScaler,
              padding: padding,
              viewPadding: padding,
              viewInsets: viewInsets,
            ),
            child: SettingsScreen(
              settings: AppSettingsStore(),
              onToggleLanguage: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final size in <Size>[
    const Size(360, 640),
    const Size(412, 915),
    const Size(800, 1280),
  ]) {
    testWidgets(
      'settings fits ${size.width.toInt()}x${size.height.toInt()} without scrolling',
      (tester) async {
        await pumpSettings(tester, size: size);

        expect(find.byType(GameFitView), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('settings tolerates large text on a compact phone', (tester) async {
    await pumpSettings(
      tester,
      size: const Size(360, 640),
      textScaler: const TextScaler.linear(2),
    );

    expect(find.byType(GameFitView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings respects cutout safe area without overflow', (tester) async {
    await pumpSettings(
      tester,
      size: const Size(360, 640),
      padding: const EdgeInsets.only(top: 44, left: 8, right: 8, bottom: 24),
    );

    expect(find.byType(SafeArea), findsWidgets);
    expect(find.byType(GameFitView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings remains bounded when keyboard inset reduces viewport', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      size: const Size(360, 640),
      viewInsets: const EdgeInsets.only(bottom: 280),
    );

    expect(find.byType(GameFitView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings remains overflow-free in RTL layout', (tester) async {
    await pumpSettings(
      tester,
      size: const Size(412, 915),
      textDirection: TextDirection.rtl,
    );

    final fitView = find.byType(GameFitView);
    expect(fitView, findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(Directionality.of(tester.element(fitView)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
