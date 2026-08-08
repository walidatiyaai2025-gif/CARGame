import 'package:cargo_sort_game/core/storage/progress_store.dart';
import 'package:cargo_sort_game/features/shop/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<ProgressStore> _store() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = ProgressStore();
  await store.load();
  return store;
}

Future<void> _pumpShop(
  WidgetTester tester, {
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final store = await _store();
  addTearDown(store.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: textScaler,
            padding: padding,
            viewPadding: padding,
          ),
          child: ShopScreen(store: store),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shop stays overflow-free on a narrow phone with large text', (
    tester,
  ) async {
    await _pumpShop(
      tester,
      size: const Size(360, 640),
      textScaler: const TextScaler.linear(1.6),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Cargo Shop'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Visual Themes'), findsOneWidget);
  });

  testWidgets('shop remains reachable and stable on a tablet', (tester) async {
    await _pumpShop(tester, size: const Size(1024, 1366));

    expect(tester.takeException(), isNull);
    expect(find.text('Available balance'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Visual Themes'), findsOneWidget);
  });

  testWidgets('shop remains overflow-free in RTL on a tall phone', (
    tester,
  ) async {
    await _pumpShop(
      tester,
      size: const Size(412, 915),
      textDirection: TextDirection.rtl,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Visual Themes'), findsOneWidget);
  });

  testWidgets('shop respects cutout safe area and keeps content reachable', (
    tester,
  ) async {
    await _pumpShop(
      tester,
      size: const Size(412, 915),
      padding: const EdgeInsets.only(top: 48, left: 8, right: 8, bottom: 28),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SafeArea), findsWidgets);
    expect(find.byType(ListView), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Visual Themes'), findsOneWidget);
  });
}
