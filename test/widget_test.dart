import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('home screen starts', (tester) async {
    final store = ProgressStore();
    final settings = AppSettingsStore();

    await tester.pumpWidget(CargoSortApp(store: store, settings: settings));

    // The home screen intentionally contains ambient looping motion, so
    // pumpAndSettle would never complete. Pump a bounded startup window instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cargo Sort'), findsOneWidget);
  });
}
