import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/settings/game_visual_effects_preference.dart';
import 'package:cargo_sort_game/core/settings/visual_effects_preference_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('scope defaults safely when absent', (tester) async {
    GameVisualEffectsPreference? value;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          value = VisualEffectsPreferenceScope.preferenceOf(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(value, GameVisualEffectsPreference.automatic);
  });

  testWidgets('scope propagates live settings notifications', (tester) async {
    final settings = AppSettingsStore();
    var builds = 0;
    var reduced = false;

    await tester.pumpWidget(
      VisualEffectsPreferenceScope(
        settings: settings,
        child: Builder(
          builder: (context) {
            builds++;
            reduced = VisualEffectsPreferenceScope.userReducedEffectsOf(
              context,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(reduced, isFalse);

    await settings.setVisualEffectsPreference(
      GameVisualEffectsPreference.reduced,
    );
    await tester.pump();
    expect(reduced, isTrue);
    expect(builds, greaterThan(1));
  });
}
