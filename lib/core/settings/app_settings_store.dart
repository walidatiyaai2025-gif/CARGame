import 'package:flutter/foundation.dart';

import '../storage/recovering_preferences.dart';

class AppSettingsStore extends ChangeNotifier {
  static const _soundKey = 'settings_sound';
  static const _musicKey = 'settings_music';
  static const _vibrationKey = 'settings_vibration';

  final RecoveringPreferences _prefs = RecoveringPreferences();

  bool soundEnabled = true;
  bool musicEnabled = true;
  bool vibrationEnabled = true;

  Future<void> load() async {
    soundEnabled = await _prefs.getBool(_soundKey) ?? true;
    musicEnabled = await _prefs.getBool(_musicKey) ?? true;
    vibrationEnabled = await _prefs.getBool(_vibrationKey) ?? true;
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    soundEnabled = value;
    notifyListeners();
    await _prefs.setBool(_soundKey, value);
  }

  Future<void> setMusic(bool value) async {
    musicEnabled = value;
    notifyListeners();
    await _prefs.setBool(_musicKey, value);
  }

  Future<void> setVibration(bool value) async {
    vibrationEnabled = value;
    notifyListeners();
    await _prefs.setBool(_vibrationKey, value);
  }
}
