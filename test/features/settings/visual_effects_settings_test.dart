import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'visual effects setting applies live in ${locale.languageCode}',
      (tester) async {
        final settings = AppSettingsStore();
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SettingsScreen(settings: settings, onToggleLanguage: () {}),
          ),
        );

        final tile = find.byKey(const ValueKey('visual-effects-switch'));
        expect(tile, findsOneWidget);
        expect(settings.reducedVisualEffects, isFalse);

        final switchFinder = find.descendant(
          of: tile,
          matching: find.byType(Switch),
        );
        final adaptiveFinder = find.descendant(
          of: tile,
          matching: find.byType(SwitchListTile),
        );
        expect(adaptiveFinder, findsOneWidget);
        await tester.tap(adaptiveFinder);
        await tester.pump();

        expect(settings.reducedVisualEffects, isTrue);
        expect(
          find.text(
            locale.languageCode == 'ar'
                ? 'المؤثرات المرئية: مخفضة'
                : 'Visual effects: Reduced',
          ),
          findsOneWidget,
        );
        expect(switchFinder, findsWidgets);
      },
    );
  }
}
