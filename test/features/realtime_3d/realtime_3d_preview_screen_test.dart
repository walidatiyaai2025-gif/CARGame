import 'package:cargo_sort_game/features/realtime_3d/realtime_3d_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('3D visual checkpoint is visible and responsive', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: Realtime3dPreviewScreen()));
    await tester.pump();

    expect(find.byKey(const Key('rt3d-preview-scene')), findsOneWidget);
    expect(find.byKey(const Key('rt3d-preview-status')), findsOneWidget);
    expect(find.byKey(const Key('open-native-3d')), findsOneWidget);
    expect(find.text('3D VISUAL LAB'), findsOneWidget);
    expect(find.text('GPU'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('rt3d-preview-scene')),
      const Offset(36, -18),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
