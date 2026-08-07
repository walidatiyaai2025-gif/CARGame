import 'package:cargo_sort_game/core/ads/banner_ad_footer.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/main.dart';
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

  testWidgets('home screen starts', (tester) async {
    final store = ProgressStore();
    final settings = AppSettingsStore();

    await tester.pumpWidget(CargoSortApp(store: store, settings: settings));

    // The home screen intentionally contains ambient looping motion, so
    // pumpAndSettle would never complete. Pump a bounded startup window instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cargo Sort'), findsOneWidget);
    expect(find.byType(BannerAdFooter), findsOneWidget);
  });

  for (final size in <Size>[const Size(360, 640), const Size(412, 915)]) {
    testWidgets(
      'home fits ${size.width.toInt()}x${size.height.toInt()} without scroll',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          CargoSortApp(store: ProgressStore(), settings: AppSettingsStore()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(ListView), findsNothing);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.text('Cargo Sort'), findsOneWidget);
      },
    );
  }
}
