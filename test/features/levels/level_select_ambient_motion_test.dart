import 'package:cargo_sort_game/core/motion/ambient_motion_background.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/levels/level_select_screen.dart';
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

  testWidgets('world map reuses the reduced-motion ambient scene', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: LevelSelectScreen(
            store: ProgressStore(),
            settings: AppSettingsStore(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(AmbientMotionBackground), findsOneWidget);
    expect(find.text('World Map'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
