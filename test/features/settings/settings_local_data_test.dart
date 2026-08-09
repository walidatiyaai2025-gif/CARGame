import 'dart:convert';

import 'package:cargo_sort_game/core/logging/app_logger.dart';
import 'package:cargo_sort_game/core/privacy/local_data_controller.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await AppLogger.instance.clear();
  });

  tearDown(() async {
    await AppLogger.instance.clear();
  });

  testWidgets('privacy sheet copies a versioned local data export', (
    tester,
  ) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('coins', 456);

    final controller = LocalDataController(
      now: () => DateTime.utc(2026, 8, 10, 2, 3, 4),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settings: AppSettingsStore(),
          onToggleLanguage: () {},
          localDataController: controller,
        ),
      ),
    );
    await _openPrivacySheet(tester);

    final exportButton = find.byKey(
      const ValueKey('privacy-export-data-button'),
    );
    expect(exportButton, findsOneWidget);
    await tester.ensureVisible(exportButton);
    await tester.tap(exportButton);
    await tester.pump();

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final decoded = jsonDecode(clipboard!.text!) as Map<String, dynamic>;
    expect(decoded['schemaVersion'], LocalDataController.exportSchemaVersion);
    expect(decoded['networkTransfer'], isFalse);
    expect(
      (decoded['sharedPreferences'] as Map<String, dynamic>)['coins'],
      456,
    );
    expect(find.text('Local data export copied as JSON.'), findsOneWidget);
  });

  testWidgets(
    'delete requires confirmation and clears local first-party data',
    (tester) async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('coins', 999);
      await prefs.setBool('settings_sound', false);
      await prefs.setString('storage_recovery_backup_v1', 'backup');
      await AppLogger.instance.info('Delete from settings');

      var rehydrateCalls = 0;
      final controller = LocalDataController();
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settings: AppSettingsStore(),
            onToggleLanguage: () {},
            localDataController: controller,
            onLocalDataDeleted: () async {
              rehydrateCalls++;
            },
          ),
        ),
      );
      await _openPrivacySheet(tester);

      final deleteButton = find.byKey(
        const ValueKey('privacy-delete-data-button'),
      );
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete local data?'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('privacy-delete-cancel-button')),
      );
      await tester.pumpAndSettle();
      expect(await prefs.getInt('coins'), 999);
      expect(rehydrateCalls, 0);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('privacy-delete-confirm-button')),
      );
      await tester.pumpAndSettle();

      expect(await prefs.getKeys(), isEmpty);
      expect(AppLogger.instance.entries, isEmpty);
      expect(rehydrateCalls, 1);
    },
  );
}

Future<void> _openPrivacySheet(WidgetTester tester) async {
  final privacyButtonFinder = find.ancestor(
    of: find.text('Privacy'),
    matching: find.byType(GameButton),
  );
  expect(privacyButtonFinder, findsOneWidget);
  final privacyButton = tester.widget<GameButton>(privacyButtonFinder);
  privacyButton.onPressed!.call();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
