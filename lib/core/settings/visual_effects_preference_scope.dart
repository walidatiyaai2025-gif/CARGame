import 'package:flutter/widgets.dart';

import 'app_settings_store.dart';
import 'game_visual_effects_preference.dart';

class VisualEffectsPreferenceScope extends InheritedNotifier<AppSettingsStore> {
  const VisualEffectsPreferenceScope({
    super.key,
    required this.settings,
    required super.child,
  }) : super(notifier: settings);

  final AppSettingsStore settings;

  static GameVisualEffectsPreference preferenceOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<VisualEffectsPreferenceScope>()
          ?.settings
          .visualEffectsPreference ??
      GameVisualEffectsPreference.automatic;

  static bool userReducedEffectsOf(BuildContext context) =>
      preferenceOf(context) == GameVisualEffectsPreference.reduced;
}
