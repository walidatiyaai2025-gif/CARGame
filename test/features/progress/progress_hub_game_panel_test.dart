import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/core/widgets/game_panel.dart';
import 'package:cargo_sort_game/features/progress/progress_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('progress hub adopts GamePanel while preserving long-form scrolling', (
    tester,
  ) async {
    final store = ProgressStore();

    await tester.pumpWidget(
      MaterialApp(home: ProgressHubScreen(store: store)),
    );
    await tester.pump();

    final scrollable = find.byType(Scrollable);

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(GamePanel), findsWidgets);
    expect(find.text('Daily Mission'), findsOneWidget);
    expect(find.text('Win 3 cities'), findsOneWidget);
    expect(find.text('Earn 6 stars'), findsOneWidget);
    expect(find.text('Earn 150 coins'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Perfect Player'),
      300,
      scrollable: scrollable,
    );

    expect(find.text('Perfect Player'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
