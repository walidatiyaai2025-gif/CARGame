import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/progress/progress_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();
  return ProgressStore(preferences)..initialize();
}

Future<void> _pumpProgress(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(size);
  final store = await _store();

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: ProgressHubScreen(store: store),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(() async {
    await TestWidgetsFlutterBinding.ensureInitialized().setSurfaceSize(null);
  });

  testWidgets('progress hub stays overflow-free on a narrow phone', (tester) async {
    await _pumpProgress(
      tester,
      size: const Size(360, 640),
      locale: const Locale('en'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Player Progress'), findsOneWidget);
    expect(find.text('Daily Mission'), findsOneWidget);
  });

  testWidgets('progress hub supports Arabic RTL on a tall phone', (tester) async {
    await _pumpProgress(
      tester,
      size: const Size(412, 915),
      locale: const Locale('ar'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('تقدم اللاعب'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('تقدم اللاعب'))), TextDirection.rtl);
  });

  testWidgets('progress hub survives large text on a tablet', (tester) async {
    await _pumpProgress(
      tester,
      size: const Size(1024, 1366),
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Achievements'), findsOneWidget);
  });
}
