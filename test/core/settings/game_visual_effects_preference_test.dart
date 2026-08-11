import 'package:cargo_sort_game/core/settings/game_visual_effects_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visual effects preference wire contract is stable and fail closed', () {
    expect(
      GameVisualEffectsPreference.parse(null),
      GameVisualEffectsPreference.automatic,
    );
    expect(
      GameVisualEffectsPreference.parse('automatic'),
      GameVisualEffectsPreference.automatic,
    );
    expect(
      GameVisualEffectsPreference.parse('reduced'),
      GameVisualEffectsPreference.reduced,
    );
    expect(
      GameVisualEffectsPreference.parse('future-unknown-mode'),
      GameVisualEffectsPreference.automatic,
    );
    expect(GameVisualEffectsPreference.automatic.wireValue, 'automatic');
    expect(GameVisualEffectsPreference.reduced.wireValue, 'reduced');
  });
}
