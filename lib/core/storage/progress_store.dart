import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore extends ChangeNotifier {
  static const _levelKey = 'highest_unlocked_level';
  static const _coinsKey = 'coins';
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  int highestUnlockedLevel = 1;
  int coins = 100;

  Future<void> load() async {
    highestUnlockedLevel = await _prefs.getInt(_levelKey) ?? 1;
    coins = await _prefs.getInt(_coinsKey) ?? 100;
  }

  Future<void> completeLevel(int level, int reward) async {
    coins += reward;
    if (level >= highestUnlockedLevel && highestUnlockedLevel < 5) {
      highestUnlockedLevel = level + 1;
    }
    await _prefs.setInt(_levelKey, highestUnlockedLevel);
    await _prefs.setInt(_coinsKey, coins);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (coins < amount) return false;
    coins -= amount;
    await _prefs.setInt(_coinsKey, coins);
    notifyListeners();
    return true;
  }
}
