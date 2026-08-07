import 'package:cargo_sort_game/core/storage/recovering_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('future heart timestamp is repaired to current time', () async {
    final delegate = SharedPreferencesAsync();
    final now = DateTime.now().toUtc();
    final future = now.add(const Duration(days: 30)).toIso8601String();
    await delegate.setString('heart_refill_timestamp', future);
    await delegate.setInt('coins', 450);

    final prefs = RecoveringPreferences(delegate: delegate);
    final repaired = await prefs.getString('heart_refill_timestamp');

    expect(repaired, isNotNull);
    expect(repaired, isNot(future));
    expect(await delegate.getInt('coins'), 450);

    final event = prefs.recoveryEvents.single;
    expect(event.key, 'heart_refill_timestamp');
    expect(event.reason, 'future timestamp');

    final repairedAt = DateTime.parse(repaired!);
    final tolerance = now.add(const Duration(minutes: 1));
    expect(repairedAt.isAfter(tolerance), isFalse);
  });
}
