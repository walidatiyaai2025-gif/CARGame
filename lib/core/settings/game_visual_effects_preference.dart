enum GameVisualEffectsPreference {
  automatic('automatic'),
  reduced('reduced');

  const GameVisualEffectsPreference(this.wireValue);

  final String wireValue;

  static GameVisualEffectsPreference parse(String? value) => switch (value) {
    'reduced' => GameVisualEffectsPreference.reduced,
    _ => GameVisualEffectsPreference.automatic,
  };
}
