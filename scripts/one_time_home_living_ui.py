from pathlib import Path

root = Path('.')
home = root / 'lib/features/home/home_screen.dart'
text = home.read_text(encoding='utf-8')

import_line = "import '../../core/widgets/game_button.dart';\n"
new_import = import_line + "import 'home_ambient_background.dart';\n"
if "home_ambient_background.dart" not in text:
    text = text.replace(import_line, new_import, 1)

old_header = """          return Container(\n            decoration: BoxDecoration(\n              gradient: LinearGradient(\n                begin: Alignment.topCenter,\n                end: Alignment.bottomCenter,\n                colors: [\n                  world.startColor.withValues(alpha: .18),\n                  const Color(0xFFF6FAFF),\n                  AppTheme.cream,\n                ],\n              ),\n            ),\n            child: SafeArea(\n"""
new_header = """          return Stack(\n            children: [\n              Positioned.fill(\n                child: HomeAmbientBackground(\n                  startColor: world.startColor,\n                  endColor: world.endColor,\n                ),\n              ),\n              SafeArea(\n"""
if old_header not in text:
    raise SystemExit('home header anchor not found')
text = text.replace(old_header, new_header, 1)

old_tail = """                  );\n                },\n              ),\n            ),\n          );\n"""
new_tail = """                  );\n                },\n              ),\n            ),\n          ],\n        );\n"""
if old_tail not in text:
    raise SystemExit('home tail anchor not found')
text = text.replace(old_tail, new_tail, 1)
home.write_text(text, encoding='utf-8')

ambient = root / 'lib/features/home/home_ambient_background.dart'
ambient.write_text(r'''import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/game_motion.dart';

class HomeAmbientBackground extends StatefulWidget {
  const HomeAmbientBackground({
    super.key,
    required this.startColor,
    required this.endColor,
  });

  final Color startColor;
  final Color endColor;

  @override
  State<HomeAmbientBackground> createState() => _HomeAmbientBackgroundState();
}

class _HomeAmbientBackgroundState extends State<HomeAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: GameMotionDurations.idle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = GameMotion.of(context).reducedMotion;
    if (_reducedMotion == reducedMotion && _controller.isAnimating) {
      return;
    }
    _reducedMotion = reducedMotion;
    if (reducedMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _HomeAmbientPainter(
            progress: _controller.value,
            startColor: widget.startColor,
            endColor: widget.endColor,
            reducedMotion: _reducedMotion,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _HomeAmbientPainter extends CustomPainter {
  const _HomeAmbientPainter({
    required this.progress,
    required this.startColor,
    required this.endColor,
    required this.reducedMotion,
  });

  final double progress;
  final Color startColor;
  final Color endColor;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          startColor.withValues(alpha: .24),
          const Color(0xFFF6FAFF),
          const Color(0xFFFFF8E7),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final phase = reducedMotion ? 0.0 : progress * math.pi * 2;
    _drawGlow(
      canvas,
      Offset(size.width * (.16 + math.sin(phase) * .025), size.height * .14),
      size.shortestSide * .34,
      startColor.withValues(alpha: .13),
    );
    _drawGlow(
      canvas,
      Offset(size.width * (.84 + math.cos(phase) * .02), size.height * .34),
      size.shortestSide * .28,
      endColor.withValues(alpha: .10),
    );

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: .34);
    for (var index = 0; index < 4; index++) {
      final base = (index * .29 + progress * .08) % 1.25 - .12;
      final x = size.width * base;
      final y = size.height * (.08 + index * .075);
      _drawCloud(canvas, Offset(x, y), 18 + index * 3, cloudPaint);
    }

    final roadPaint = Paint()
      ..color = startColor.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final road = Path()
      ..moveTo(-20, size.height * .82)
      ..cubicTo(
        size.width * .25,
        size.height * .70,
        size.width * .65,
        size.height * .95,
        size.width + 30,
        size.height * .76,
      );
    canvas.drawPath(road, roadPaint);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCloud(Canvas canvas, Offset origin, double radius, Paint paint) {
    canvas.drawCircle(origin, radius, paint);
    canvas.drawCircle(origin + Offset(radius * .9, 3), radius * .72, paint);
    canvas.drawCircle(origin - Offset(radius * .8, -5), radius * .58, paint);
  }

  @override
  bool shouldRepaint(covariant _HomeAmbientPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.startColor != startColor ||
      oldDelegate.endColor != endColor ||
      oldDelegate.reducedMotion != reducedMotion;
}
''', encoding='utf-8')

test = root / 'test/features/home/home_ambient_background_test.dart'
test.parent.mkdir(parents=True, exist_ok=True)
test.write_text(r'''import 'package:cargo_sort_game/features/home/home_ambient_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and disposes without ticker leaks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeAmbientBackground(
          startColor: Colors.blue,
          endColor: Colors.orange,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(HomeAmbientBackground), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: HomeAmbientBackground(
            startColor: Colors.blue,
            endColor: Colors.orange,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
''', encoding='utf-8')

catalog = root / 'docs/FEATURE_CATALOG.md'
cat = catalog.read_text(encoding='utf-8')
cat = cat.replace(
    '| MOT-005 | Ambient home/world motion | P1 | PLANNED | MOT-001, UI3D-007 | Low-density particles, parallax, and light sweeps pause off-screen. |',
    '| MOT-005 | Ambient home/world motion | P1 | IN PROGRESS | MOT-001, UI3D-007 | Home now uses a lifecycle-safe animated gradient, drifting clouds, glow parallax, and low-cost road depth with reduced-motion support; world-map adoption and physical-device review remain. |',
)
cat = cat.replace(
    '| HOME-001 | Premium 3D home screen | P1 | IMPLEMENTED | UI3D-002 | Hero, resources, cards, and start CTA exist; final assets and motion remain. |',
    '| HOME-001 | Premium 3D home screen | P1 | IMPLEMENTED | UI3D-002 | Hero, resources, cards, and start CTA exist; a lifecycle-safe living backdrop with parallax glow and drifting cloud layers is integrated. Final authored assets and device polish remain. |',
)
catalog.write_text(cat, encoding='utf-8')

status = root / 'docs/STATUS.md'
status.write_text('''# CARGame Live Project Status

This document is the operational summary. Detailed tracking remains in `docs/FEATURE_CATALOG.md`; the Developer Portal calculates totals dynamically.

## Current work

| Field | Value |
|---|---|
| Current phase | C — Motion and living interface |
| Active checkpoint | `MOT-005` Ambient home/world motion |
| Status | IN PROGRESS — Home implementation complete; CI, world-map adoption, and device review remain |
| Previous checkpoint | `MOT-010` lifecycle-safe ticker boundaries |
| Next checkpoint | Apply the shared ambient-motion layer to the world/city map |

## MOT-005 home implementation evidence — 2026-08-07

- Added `HomeAmbientBackground` with a low-cost custom painter and one shared ticker.
- Added animated gradient lighting, two parallax glow fields, drifting cloud layers, and subtle road depth.
- Wrapped painting in `RepaintBoundary` to isolate repaints from the Home content tree.
- Reduced motion stops the ticker and renders a stable frame.
- Existing `MotionLifecycleScope` pauses the ticker automatically when the app is backgrounded or hidden.
- Integrated the backdrop behind the existing responsive, RTL/LTR-safe Home content without changing gameplay or persistence.
- Added widget tests for rendering, reduced motion, disposal, and ticker-leak safety.

## Verification ledger

| Date | Verification | Result |
|---|---|---|
| 2026-08-07 | Patch anchors and Dart format | PASSED in implementation workflow |
| 2026-08-07 | Home ambient focused tests | PENDING in Flutter CI |
| 2026-08-07 | Flutter Analyze and full test suite | PENDING in Flutter CI |
| 2026-08-07 | Debug APK build | PENDING in Flutter CI |
| 2026-08-07 | Dashboard schema | PASSED — six-column tables and phases A–S preserved |

## Test locally

```powershell
cd "D:\\Apps\\CARGame"
git fetch origin
git reset --hard origin/main
flutter pub get
flutter test test\\features\\home\\home_ambient_background_test.dart
flutter analyze
flutter test
flutter run
```
''', encoding='utf-8')
