import 'package:cargo_sort_game/core/ads/ad_service.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/theme/three_d_game_icon.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/features/game/game_screen.dart';
import 'package:cargo_sort_game/features/game/level_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _NoopAdService extends AdService {
  @override
  void preload() {}

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gameplay exposes the premium live operations hierarchy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final store = ProgressStore();
    await store.load();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: levels.first,
          store: store,
          adService: _NoopAdService(),
          hapticsEnabled: false,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('MISSION LIVE'), findsOneWidget);
    expect(find.text('CARGO BAY'), findsOneWidget);
    expect(find.text('SORTING DOCKS'), findsOneWidget);
    expect(find.byKey(const ValueKey('game-moves')), findsOneWidget);
    expect(find.byType(ThreeDGameIcon), findsAtLeastNWidgets(3));
    expect(find.byType(GameButton), findsAtLeastNWidgets(3));
    expect(find.byType(AppBar), findsNothing);
  });
}
