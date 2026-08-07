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

  for (final size in <Size>[const Size(360, 640), const Size(412, 915)]) {
    testWidgets(
      'settings fits ${size.width.toInt()}x${size.height.toInt()} without scrolling',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              settings: AppSettingsStore(),
              onToggleLanguage: () {},
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(GameFitView), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
