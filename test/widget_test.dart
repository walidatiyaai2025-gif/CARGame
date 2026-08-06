import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen starts', (tester) async {
    final store = ProgressStore();
    final settings = AppSettingsStore();

    await tester.pumpWidget(
      CargoSortApp(
        store: store,
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cargo Sort'), findsOneWidget);
  });
}
