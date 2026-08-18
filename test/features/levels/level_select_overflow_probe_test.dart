import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/levels/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('prints compact overflow diagnostics', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = ProgressStore();
    final settings = AppSettingsStore();
    addTearDown(store.dispose);
    addTearDown(settings.dispose);
    await store.load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 640)),
          child: LevelSelectScreen(store: store, settings: settings),
        ),
      ),
    );
    await tester.pump();

    final exception = tester.takeException();
    if (exception != null) {
      debugPrint('WORLD009_OVERFLOW: $exception');
      debugDumpRenderTree();
    }
    expect(exception, isNull);
  });
}
