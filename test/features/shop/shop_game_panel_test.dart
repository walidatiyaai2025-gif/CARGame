import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/widgets/game_panel.dart';
import 'package:cargo_sort_game/features/shop/shop_screen.dart';
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

  testWidgets('shop booster offers use the shared GamePanel shell', (
    tester,
  ) async {
    final store = ProgressStore();

    await tester.pumpWidget(MaterialApp(home: ShopScreen(store: store)));
    await tester.pump();

    final list = find.byType(ListView);
    final scrollable = find.byType(Scrollable);
    expect(list, findsOneWidget);
    expect(scrollable, findsOneWidget);
    expect(find.text('Smart Hint Pack'), findsOneWidget);
    expect(find.text('Extra Moves Pack'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Combo Shield'),
      250,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('Combo Shield'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Combo Shield'),
        matching: find.byType(GamePanel),
      ),
      findsOneWidget,
    );
  });
}
