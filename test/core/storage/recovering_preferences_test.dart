import 'dart:convert';

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
    expect(prefs.recovered, isTrue);

    final event = prefs.recoveryEvents.single;
    expect(event.key, 'heart_refill_timestamp');
    expect(event.reason, 'future timestamp');

    final repairedAt = DateTime.parse(repaired!);
    final tolerance = now.add(const Duration(minutes: 1));
    expect(repairedAt.isAfter(tolerance), isFalse);
  });

  test('first repair stores versioned pre-repair snapshot', () async {
    final delegate = SharedPreferencesAsync();
    await delegate.setInt('coins', -25);
    await delegate.setInt('stats_wins', 7);

    final prefs = RecoveringPreferences(delegate: delegate);
    expect(await prefs.getInt('coins'), 0);

    final backupText = await delegate.getString(RecoveringPreferences.backupKey);
    expect(backupText, isNotNull);
    final backup = jsonDecode(backupText!) as Map<String, dynamic>;
    expect(backup['schemaVersion'], 1);
    expect(backup['capturedAt'], isA<String>());

    final values = backup['values'] as Map<String, dynamic>;
    expect(values['coins'], -25);
    expect(values['stats_wins'], 7);
    expect(values.containsKey(RecoveringPreferences.backupKey), isFalse);
    expect(await delegate.getInt('stats_wins'), 7);
  });

  test('multiple repairs preserve the original single backup', () async {
    final delegate = SharedPreferencesAsync();
    await delegate.setInt('coins', -25);
    await delegate.setInt('hearts', 99);

    final prefs = RecoveringPreferences(delegate: delegate);
    expect(await prefs.getInt('coins'), 0);
    final firstBackup = await delegate.getString(RecoveringPreferences.backupKey);

    expect(await prefs.getInt('hearts'), 5);
    final secondBackup = await delegate.getString(
      RecoveringPreferences.backupKey,
    );

    expect(secondBackup, firstBackup);
    expect(prefs.recoveryEvents, hasLength(2));

    final backup = jsonDecode(firstBackup!) as Map<String, dynamic>;
    final values = backup['values'] as Map<String, dynamic>;
    expect(values['coins'], -25);
    expect(values['hearts'], 99);
  });

  test('backup snapshot failure does not block repair', () async {
    final delegate = SharedPreferencesAsync();
    await delegate.setInt('coins', -25);
    await delegate.setInt('stats_wins', 7);

    final prefs = RecoveringPreferences(
      delegate: delegate,
      snapshotProvider: () async => throw StateError('snapshot unavailable'),
    );

    expect(await prefs.getInt('coins'), 0);
    expect(await delegate.getInt('coins'), 0);
    expect(await delegate.getInt('stats_wins'), 7);
    expect(await delegate.containsKey(RecoveringPreferences.backupKey), isFalse);
    expect(prefs.recoveryEvents, hasLength(1));
    expect(prefs.recoveryEvents.single.key, 'coins');
    expect(prefs.recoveryEvents.single.reason, 'out-of-range int -25 -> 0');
  });
}
