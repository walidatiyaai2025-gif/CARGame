import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/widgets/game_panel.dart';
import 'package:cargo_sort_game/features/progress/progress_hub_screen.dart';
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

  testWidgets(
    'progress hub adopts GamePanel while preserving long-form scrolling',
    (tester) async {
      final store = ProgressStore();

      await tester.pumpWidget(
        MaterialApp(home: ProgressHubScreen(store: store)),
      );
      await tester.pump();

      final list = find.byType(ListView);
      final scrollable = find.byType(Scrollable);
      expect(list, findsOneWidget);
      expect(scrollable, findsOneWidget);
      expect(find.byType(GamePanel), findsAtLeastNWidgets(4));
      expect(find.text('Daily Mission'), findsOneWidget);
      expect(find.text('Win 3 cities'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Earn 150 coins'),
        250,
        scrollable: scrollable,
      );
      await tester.pump();

      expect(find.text('Earn 6 stars'), findsOneWidget);
      expect(find.text('Earn 150 coins'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Earn 150 coins'),
          matching: find.byType(GamePanel),
        ),
        findsOneWidget,
      );
    },
  );
}
