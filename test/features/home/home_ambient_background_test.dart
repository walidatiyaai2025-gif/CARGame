import 'package:cargo_sort_game/core/motion/ambient_motion_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and disposes without ticker leaks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AmbientMotionBackground(
          startColor: Colors.blue,
          endColor: Colors.orange,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(AmbientMotionBackground), findsOneWidget);
    final animatedBuilder = tester.widget<AnimatedBuilder>(
      find.descendant(
        of: find.byType(AmbientMotionBackground),
        matching: find.byType(AnimatedBuilder),
      ),
    );
    expect(
      (animatedBuilder.animation as AnimationController).isAnimating,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AmbientMotionBackground(
            startColor: Colors.blue,
            endColor: Colors.orange,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final animatedBuilder = tester.widget<AnimatedBuilder>(
      find.descendant(
        of: find.byType(AmbientMotionBackground),
        matching: find.byType(AnimatedBuilder),
      ),
    );
    final controller = animatedBuilder.animation as AnimationController;
    expect(controller.isAnimating, isFalse);
    expect(controller.value, 0);
    expect(tester.takeException(), isNull);
  });
}
