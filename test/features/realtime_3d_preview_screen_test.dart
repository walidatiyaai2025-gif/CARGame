import 'package:cargo_sort_game/features/realtime_3d/realtime_3d_preview_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> withTargetPlatform(
    TargetPlatform platform,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body();
    } finally {
      // Flutter verifies foundation debug globals before test tearDown callbacks,
      // so the override must be restored inside the test body itself.
      debugDefaultTargetPlatformOverride = null;
    }
  }

  testWidgets('non-Android platforms keep the projected fallback reachable', (
    tester,
  ) async {
    await withTargetPlatform(TargetPlatform.linux, () async {
      await tester.pumpWidget(const MaterialApp(home: Realtime3dPreviewScreen()));
      await tester.pump();

      expect(
        find.byKey(const Key('rt3d-projected-fallback-view')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('rt3d-native-filament-view')), findsNothing);
      expect(find.byKey(const Key('rt3d-camera-presets')), findsNothing);
      expect(find.textContaining('Projected fallback'), findsOneWidget);
    });
  });

  testWidgets('Android Visual Lab exposes accessible deterministic cameras', (
    tester,
  ) async {
    await withTargetPlatform(TargetPlatform.android, () async {
      await tester.pumpWidget(const MaterialApp(home: Realtime3dPreviewScreen()));
      await tester.pump();

      expect(find.byKey(const Key('rt3d-native-filament-view')), findsOneWidget);
      expect(find.byKey(const Key('rt3d-camera-presets')), findsOneWidget);
      expect(find.byKey(const Key('rt3d-camera-overview')), findsOneWidget);
      expect(find.byKey(const Key('rt3d-camera-warehouse')), findsOneWidget);
      expect(find.byKey(const Key('rt3d-camera-docks')), findsOneWidget);
      expect(find.bySemanticsLabel('Overview camera'), findsOneWidget);
      expect(find.bySemanticsLabel('Warehouse camera'), findsOneWidget);
      expect(find.bySemanticsLabel('Docks camera'), findsOneWidget);
    });
  });

  testWidgets('camera HUD selection updates owner-visible camera status', (
    tester,
  ) async {
    await withTargetPlatform(TargetPlatform.android, () async {
      await tester.pumpWidget(const MaterialApp(home: Realtime3dPreviewScreen()));
      await tester.pump();

      await tester.tap(find.byKey(const Key('rt3d-camera-warehouse')));
      await tester.pump();

      expect(find.textContaining('Warehouse camera selected'), findsOneWidget);
      expect(find.textContaining('bloom • Warehouse'), findsOneWidget);
    });
  });
}
