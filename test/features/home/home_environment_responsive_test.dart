import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/theme/app_theme.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/features/home/home_screen.dart';
import 'package:cargo_sort_game/l10n/app_localizations.dart';
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

  Future<void> pumpHome(
    WidgetTester tester, {
    required Size size,
    TextScaler textScaler = TextScaler.noScaling,
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: padding,
            viewPadding: padding,
            viewInsets: viewInsets,
            textScaler: textScaler,
          ),
          child: HomeScreen(
            store: ProgressStore(),
            settings: AppSettingsStore(),
            onToggleLanguage: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('home survives large text on a tablet', (tester) async {
    await pumpHome(
      tester,
      size: const Size(1024, 1366),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Cargo Sort'), findsOneWidget);
    expect(find.byType(GameButton), findsOneWidget);
  });

  testWidgets('home respects a top cutout without overflow', (tester) async {
    await pumpHome(
      tester,
      size: const Size(390, 844),
      padding: const EdgeInsets.only(top: 48),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Cargo Sort'), findsOneWidget);
    expect(find.byType(GameButton), findsOneWidget);
  });

  testWidgets('home stays bounded with keyboard inset', (tester) async {
    await pumpHome(
      tester,
      size: const Size(390, 844),
      viewInsets: const EdgeInsets.only(bottom: 300),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Cargo Sort'), findsOneWidget);
    expect(find.byType(GameButton), findsOneWidget);
  });
}
