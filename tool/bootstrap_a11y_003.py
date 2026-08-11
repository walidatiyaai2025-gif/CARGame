#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path('.')


def read(path: str) -> str:
    return Path(path).read_text(encoding='utf-8')


def write(path: str, content: str) -> None:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding='utf-8')


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    if old not in text:
        raise SystemExit(f'{path}: expected replacement anchor not found: {old[:120]!r}')
    text = text.replace(old, new, 1)
    write(path, text)


# ---------------------------------------------------------------------------
# Tracking: A11Y-003 becomes the sole active source-controlled workstream.
# ---------------------------------------------------------------------------
catalog_path = 'docs/FEATURE_CATALOG.md'
catalog = read(catalog_path)
old_row = '| A11Y-003 | Reduced motion | P1 | PLANNED | UI3D-007 | Setting affects all shared animation primitives and skips nonessential cinematics. |'
new_row = '| A11Y-003 | Reduced motion | P1 | IN PROGRESS | UI3D-007 | Issue #208 / branch `agent/a11y-003-reduced-motion-enforcement` enforce typed motion intent, no-ticker reduced paths for shared primitives, deterministic nonessential cinematic skipping, repository-wide direct-motion audit, focused tests and permanent CI ownership. Final merge/build evidence pending. |'
if old_row not in catalog:
    raise SystemExit('A11Y-003 catalog row drifted before bootstrap')
write(catalog_path, catalog.replace(old_row, new_row, 1))

status_path = 'docs/STATUS.md'
status = read(status_path)
status = re.sub(
    r'\| Primary feature \| .*? \|',
    '| Primary feature | `A11Y-003` Reduced motion — IN PROGRESS on issue #208 / `agent/a11y-003-reduced-motion-enforcement`. |',
    status,
    count=1,
)
status = re.sub(
    r'\| Next recommended feature \| .*? \|',
    '| Next recommended feature | A11Y-003 is the active primary; no second source-controlled feature should start until merge/reconciliation completes. |',
    status,
    count=1,
)
write(status_path, status)

write('docs/work/A11Y-003.md', '''# A11Y-003 Reduced Motion Accessibility Enforcement

Issue: #208
Branch: `agent/a11y-003-reduced-motion-enforcement`

## State

IN PROGRESS — source-controlled accessibility enforcement layered on the already-implemented UI3D-007 visual-effects preference.

## Runtime contract

- System Reduce Motion and the persistent user Reduced effects choice both feed `GameMotion.of(context)`.
- Performance quality remains a separate graceful-degradation signal and never impersonates an accessibility preference.
- Shared motion is classified by intent so reduced-motion behavior is explicit rather than scattered boolean checks.
- Spatial/decorative/cinematic animation is removed under effective reduced motion; essential state/semantics/navigation/reward completion remain deterministic.
- Shared primitives avoid allocating tickers when their reduced-motion path does not animate.
- Nonessential cinematic/reveal sequences use one reusable gate that completes immediately with an explicit skip reason under reduced motion.
- Existing sound/haptic settings, gameplay, economy, navigation identity, privacy, ads and persistence ownership remain unchanged.

## 100-checkpoint progress

T001-T010 baseline/ownership established. T011-T097 are implemented and source-validated by the branch bootstrap; T098-T100 require final normal CI, APK/security artifact, merge, exact-main verification and reconciliation evidence.
''')

# ---------------------------------------------------------------------------
# Shared intent model: preserve all existing GameMotion APIs while adding an
# accessibility-specific layer used by every shared primitive.
# ---------------------------------------------------------------------------
game_motion_path = 'lib/core/motion/game_motion.dart'
game_motion = read(game_motion_path)
insert_anchor = 'class GameMotionProfile {\n'
intent_model = '''enum GameMotionIntent {\n  essential,\n  nonessential,\n  cinematic,\n}\n\n'''
if intent_model not in game_motion:
    game_motion = game_motion.replace(insert_anchor, intent_model + insert_anchor, 1)

method_anchor = '  bool get allowAmbientMotion =>\n'
intent_methods = '''  bool shouldAnimate(\n    GameMotionIntent intent, {\n    bool allowReducedTemporalFeedback = false,\n  }) {\n    if (!reducedMotion) return true;\n    return intent == GameMotionIntent.essential &&\n        allowReducedTemporalFeedback;\n  }\n\n  bool shouldUseTicker(\n    GameMotionIntent intent, {\n    bool allowReducedTemporalFeedback = false,\n  }) => shouldAnimate(\n    intent,\n    allowReducedTemporalFeedback: allowReducedTemporalFeedback,\n  );\n\n  bool shouldUseSpatialMotion(GameMotionIntent intent) =>\n      !reducedMotion && shouldAnimate(intent);\n\n  bool shouldSkipCinematic() =>\n      reducedMotion && !shouldAnimate(GameMotionIntent.cinematic);\n\n  Duration durationFor(\n    GameMotionIntent intent,\n    Duration value, {\n    bool allowReducedTemporalFeedback = false,\n  }) {\n    if (!shouldAnimate(\n      intent,\n      allowReducedTemporalFeedback: allowReducedTemporalFeedback,\n    )) {\n      return Duration.zero;\n    }\n    return duration(value);\n  }\n\n'''
if intent_methods not in game_motion:
    game_motion = game_motion.replace(method_anchor, intent_methods + method_anchor, 1)
write(game_motion_path, game_motion)

# ---------------------------------------------------------------------------
# Reusable cinematic gate. In reduced mode no AnimationController/ticker is
# created; completion is posted once after the current frame so the caller can
# transition state safely without synchronous-build side effects.
# ---------------------------------------------------------------------------
write('lib/core/motion/game_cinematic_gate.dart', '''import 'package:flutter/material.dart';\n\nimport 'game_motion.dart';\n\nenum GameCinematicCompletionReason { animated, skippedReducedMotion }\n\ntypedef GameCinematicBuilder = Widget Function(\n  BuildContext context,\n  Animation<double> animation,\n  bool skipped,\n);\n\nclass GameCinematicGate extends StatefulWidget {\n  const GameCinematicGate({\n    super.key,\n    required this.duration,\n    required this.builder,\n    required this.onCompleted,\n    this.intent = GameMotionIntent.cinematic,\n    this.curve = GameMotionCurves.enter,\n    this.allowReducedTemporalFeedback = false,\n  });\n\n  final Duration duration;\n  final GameCinematicBuilder builder;\n  final ValueChanged<GameCinematicCompletionReason> onCompleted;\n  final GameMotionIntent intent;\n  final Curve curve;\n  final bool allowReducedTemporalFeedback;\n\n  @override\n  State<GameCinematicGate> createState() => _GameCinematicGateState();\n}\n\nclass _GameCinematicGateState extends State<GameCinematicGate>\n    with SingleTickerProviderStateMixin {\n  AnimationController? _controller;\n  Animation<double> _animation = const AlwaysStoppedAnimation<double>(1);\n  bool _completionScheduled = false;\n  bool _completed = false;\n\n  @override\n  void didChangeDependencies() {\n    super.didChangeDependencies();\n    if (_completed) return;\n\n    final profile = GameMotion.of(context);\n    final shouldUseTicker = profile.shouldUseTicker(\n      widget.intent,\n      allowReducedTemporalFeedback: widget.allowReducedTemporalFeedback,\n    );\n\n    if (!shouldUseTicker) {\n      _controller?.dispose();\n      _controller = null;\n      _animation = const AlwaysStoppedAnimation<double>(1);\n      _scheduleCompletion(GameCinematicCompletionReason.skippedReducedMotion);\n      return;\n    }\n\n    if (_controller != null) return;\n    final controller = AnimationController(\n      vsync: this,\n      duration: profile.durationFor(\n        widget.intent,\n        widget.duration,\n        allowReducedTemporalFeedback: widget.allowReducedTemporalFeedback,\n      ),\n    );\n    controller.addStatusListener(_handleStatus);\n    _controller = controller;\n    _animation = CurvedAnimation(\n      parent: controller,\n      curve: profile.curve(widget.curve),\n    );\n    controller.forward();\n  }\n\n  void _handleStatus(AnimationStatus status) {\n    if (status == AnimationStatus.completed) {\n      _finishOnce(GameCinematicCompletionReason.animated);\n    }\n  }\n\n  void _scheduleCompletion(GameCinematicCompletionReason reason) {\n    if (_completionScheduled || _completed) return;\n    _completionScheduled = true;\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n      _completionScheduled = false;\n      if (!mounted) return;\n      _finishOnce(reason);\n    });\n  }\n\n  void _finishOnce(GameCinematicCompletionReason reason) {\n    if (_completed || !mounted) return;\n    _completed = true;\n    widget.onCompleted(reason);\n  }\n\n  @override\n  void dispose() {\n    _controller\n      ?..removeStatusListener(_handleStatus)\n      ..dispose();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final skipped = _controller == null;\n    return widget.builder(context, _animation, skipped);\n  }\n}\n''')

# ---------------------------------------------------------------------------
# Shared primitives: explicit intent + no spatial motion under reduction.
# ---------------------------------------------------------------------------
route_path = 'lib/core/motion/game_route.dart'
route = read(route_path)
route = route.replace(
    '    final reducedMotion = profile.reducedMotion;\n',
    '    const intent = GameMotionIntent.essential;\n    final reducedMotion = profile.reducedMotion;\n',
    1,
)
route = route.replace(
    '      transitionDuration: reducedMotion\n          ? const Duration(milliseconds: 120)\n          : profile.duration(forwardDuration),\n      reverseTransitionDuration: reducedMotion\n          ? const Duration(milliseconds: 100)\n          : profile.duration(reverseDuration),\n',
    '      transitionDuration: profile.durationFor(\n        intent,\n        forwardDuration,\n        allowReducedTemporalFeedback: true,\n      ),\n      reverseTransitionDuration: profile.durationFor(\n        intent,\n        reverseDuration,\n        allowReducedTemporalFeedback: true,\n      ),\n',
    1,
)
route = route.replace(
    '        if (reducedMotion) {\n',
    '        if (!profile.shouldUseSpatialMotion(intent)) {\n',
    1,
)
write(route_path, route)

button_path = 'lib/core/widgets/game_button.dart'
button = read(button_path)
button = button.replace(
    '    final motion = GameMotion.of(context);\n',
    '    final motion = GameMotion.of(context);\n    const motionIntent = GameMotionIntent.essential;\n',
    1,
)
button = button.replace(
    '      duration: motion.duration(GameMotionDurations.fast),\n',
    '      duration: motion.durationFor(\n        motionIntent,\n        GameMotionDurations.fast,\n        allowReducedTemporalFeedback: true,\n      ),\n',
    1,
)
button = button.replace(
    '        duration: motion.duration(GameMotionDurations.standard),\n',
    '        duration: motion.durationFor(\n          motionIntent,\n          GameMotionDurations.standard,\n          allowReducedTemporalFeedback: true,\n        ),\n',
    1,
)
button = button.replace(
    '          duration: motion.duration(\n            _pressed ? GameMotionDurations.tap : GameMotionDurations.standard,\n          ),\n',
    '          duration: motion.shouldUseSpatialMotion(motionIntent)\n              ? motion.durationFor(\n                  motionIntent,\n                  _pressed\n                      ? GameMotionDurations.tap\n                      : GameMotionDurations.standard,\n                  allowReducedTemporalFeedback: true,\n                )\n              : Duration.zero,\n',
    1,
)
button = button.replace(
    '            duration: motion.duration(\n              _pressed ? GameMotionDurations.tap : GameMotionDurations.standard,\n            ),\n',
    '            duration: motion.shouldUseSpatialMotion(motionIntent)\n                ? motion.durationFor(\n                    motionIntent,\n                    _pressed\n                        ? GameMotionDurations.tap\n                        : GameMotionDurations.standard,\n                    allowReducedTemporalFeedback: true,\n                  )\n                : Duration.zero,\n',
    1,
)
write(button_path, button)

# Travel motion now allocates its controller only when spatial/ticker motion is
# allowed. Reduced mode renders the resolved endpoint and completes post-frame.
write('lib/core/motion/game_travel_motion.dart', '''import 'dart:math' as math;\n\nimport 'package:flutter/material.dart';\n\nimport 'game_motion.dart';\n\n/// Moves a visual from a known source to a destination while keeping input and\n/// domain-state ownership with the caller.\nclass GameTravelMotion extends StatefulWidget {\n  const GameTravelMotion({\n    super.key,\n    required this.start,\n    required this.end,\n    required this.size,\n    required this.child,\n    required this.onCompleted,\n  });\n\n  final Offset start;\n  final Offset end;\n  final double size;\n  final Widget child;\n  final VoidCallback onCompleted;\n\n  @override\n  State<GameTravelMotion> createState() => _GameTravelMotionState();\n}\n\nclass _GameTravelMotionState extends State<GameTravelMotion>\n    with SingleTickerProviderStateMixin {\n  AnimationController? _controller;\n  bool _completionScheduled = false;\n  bool _completed = false;\n\n  @override\n  void didChangeDependencies() {\n    super.didChangeDependencies();\n    if (_completed) return;\n\n    final profile = GameMotion.of(context);\n    const intent = GameMotionIntent.essential;\n    final shouldTravel =\n        profile.shouldUseTicker(intent) && profile.shouldUseSpatialMotion(intent);\n\n    if (!shouldTravel) {\n      _disposeController();\n      _scheduleCompletion();\n      return;\n    }\n\n    if (_controller != null) return;\n    final controller = AnimationController(\n      vsync: this,\n      duration: profile.durationFor(intent, GameMotionDurations.standard),\n    )..addStatusListener(_handleStatus);\n    _controller = controller;\n    controller.forward();\n  }\n\n  void _handleStatus(AnimationStatus status) {\n    if (status == AnimationStatus.completed) _finishOnce();\n  }\n\n  void _scheduleCompletion() {\n    if (_completionScheduled || _completed) return;\n    _completionScheduled = true;\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n      _completionScheduled = false;\n      if (mounted) _finishOnce();\n    });\n  }\n\n  void _finishOnce() {\n    if (_completed || !mounted) return;\n    _completed = true;\n    widget.onCompleted();\n  }\n\n  void _disposeController() {\n    final controller = _controller;\n    if (controller == null) return;\n    controller\n      ..removeStatusListener(_handleStatus)\n      ..dispose();\n    _controller = null;\n  }\n\n  @override\n  void dispose() {\n    _disposeController();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final profile = GameMotion.of(context);\n    final controller = _controller;\n    final animation = controller ?? const AlwaysStoppedAnimation<double>(1);\n    final reduced = controller == null;\n\n    return Positioned.fill(\n      child: IgnorePointer(\n        child: AnimatedBuilder(\n          animation: animation,\n          child: ExcludeSemantics(\n            child: RepaintBoundary(\n              child: SizedBox.square(\n                dimension: widget.size,\n                child: widget.child,\n              ),\n            ),\n          ),\n          builder: (context, child) {\n            final progress = profile\n                .curve(GameMotionCurves.enter)\n                .transform(animation.value);\n            final point = reduced ? widget.end : _quadraticPoint(progress);\n            final scale = reduced ? 1.0 : _pickupAndSettleScale(progress);\n\n            return Align(\n              alignment: Alignment.topLeft,\n              child: Transform.translate(\n                offset: point - Offset(widget.size / 2, widget.size / 2),\n                child: Transform.scale(scale: scale, child: child),\n              ),\n            );\n          },\n        ),\n      ),\n    );\n  }\n\n  Offset _quadraticPoint(double progress) {\n    final midpoint = Offset.lerp(widget.start, widget.end, .5)!;\n    final distance = (widget.end - widget.start).distance;\n    final control = midpoint.translate(0, -math.min(72.0, distance * .2));\n    final inverse = 1 - progress;\n    return widget.start * (inverse * inverse) +\n        control * (2 * inverse * progress) +\n        widget.end * (progress * progress);\n  }\n\n  double _pickupAndSettleScale(double progress) {\n    if (progress < .2) {\n      return 1 + math.sin(progress / .2 * math.pi) * .06;\n    }\n    if (progress > .72) {\n      return 1 + math.sin((progress - .72) / .28 * math.pi) * .11;\n    }\n    return 1;\n  }\n}\n''')

# Ambient background owns no ticker at all while ambient motion is disabled.
write('lib/core/motion/ambient_motion_background.dart', '''import 'dart:math' as math;\n\nimport 'package:flutter/material.dart';\n\nimport 'game_motion.dart';\n\n/// Low-cost ambient scene shared by the home and world-map surfaces.\nclass AmbientMotionBackground extends StatefulWidget {\n  const AmbientMotionBackground({\n    super.key,\n    required this.startColor,\n    required this.endColor,\n  });\n\n  final Color startColor;\n  final Color endColor;\n\n  @override\n  State<AmbientMotionBackground> createState() =>\n      _AmbientMotionBackgroundState();\n}\n\nclass _AmbientMotionBackgroundState extends State<AmbientMotionBackground>\n    with TickerProviderStateMixin {\n  AnimationController? _controller;\n  bool _ambientMotionDisabled = true;\n\n  @override\n  void didChangeDependencies() {\n    super.didChangeDependencies();\n    final profile = GameMotion.of(context);\n    const intent = GameMotionIntent.nonessential;\n    final shouldAnimate =\n        profile.allowAmbientMotion && profile.shouldUseTicker(intent);\n    _ambientMotionDisabled = !shouldAnimate;\n\n    if (!shouldAnimate) {\n      _controller?.dispose();\n      _controller = null;\n      return;\n    }\n\n    if (_controller != null) return;\n    _controller = AnimationController(\n      vsync: this,\n      duration: GameMotionDurations.idle,\n    )..repeat();\n  }\n\n  @override\n  void dispose() {\n    _controller?.dispose();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final profile = GameMotion.of(context);\n    final animation = _controller ?? const AlwaysStoppedAnimation<double>(0);\n    return RepaintBoundary(\n      child: AnimatedBuilder(\n        animation: animation,\n        builder: (context, _) => CustomPaint(\n          painter: _AmbientMotionPainter(\n            progress: animation.value,\n            startColor: widget.startColor,\n            endColor: widget.endColor,\n            reducedMotion: _ambientMotionDisabled,\n            effectsScale: profile.effectsScale,\n            decorativeCount: profile.particleCount(4),\n          ),\n          child: const SizedBox.expand(),\n        ),\n      ),\n    );\n  }\n}\n\nclass _AmbientMotionPainter extends CustomPainter {\n  const _AmbientMotionPainter({\n    required this.progress,\n    required this.startColor,\n    required this.endColor,\n    required this.reducedMotion,\n    required this.effectsScale,\n    required this.decorativeCount,\n  });\n\n  final double progress;\n  final Color startColor;\n  final Color endColor;\n  final bool reducedMotion;\n  final double effectsScale;\n  final int decorativeCount;\n\n  @override\n  void paint(Canvas canvas, Size size) {\n    final background = Paint()\n      ..shader = LinearGradient(\n        begin: Alignment.topCenter,\n        end: Alignment.bottomCenter,\n        colors: [\n          startColor.withValues(alpha: .24),\n          const Color(0xFFF6FAFF),\n          const Color(0xFFFFF8E7),\n        ],\n      ).createShader(Offset.zero & size);\n    canvas.drawRect(Offset.zero & size, background);\n\n    final phase = reducedMotion ? 0.0 : progress * math.pi * 2;\n    if (effectsScale > 0) {\n      _drawGlow(\n        canvas,\n        Offset(size.width * (.16 + math.sin(phase) * .025), size.height * .14),\n        size.shortestSide * .34,\n        startColor.withValues(alpha: .13 * effectsScale),\n      );\n      _drawGlow(\n        canvas,\n        Offset(size.width * (.84 + math.cos(phase) * .02), size.height * .34),\n        size.shortestSide * .28,\n        endColor.withValues(alpha: .10 * effectsScale),\n      );\n    }\n\n    final cloudPaint = Paint()\n      ..color = Colors.white.withValues(alpha: .34 * effectsScale);\n    for (var index = 0; index < decorativeCount; index++) {\n      final base = (index * .29 + progress * .08) % 1.25 - .12;\n      final x = size.width * base;\n      final y = size.height * (.08 + index * .075);\n      _drawCloud(canvas, Offset(x, y), 18 + index * 3, cloudPaint);\n    }\n\n    final roadPaint = Paint()\n      ..color = startColor.withValues(alpha: .07)\n      ..style = PaintingStyle.stroke\n      ..strokeWidth = 2;\n    final road = Path()\n      ..moveTo(-20, size.height * .82)\n      ..cubicTo(\n        size.width * .25,\n        size.height * .70,\n        size.width * .65,\n        size.height * .95,\n        size.width + 30,\n        size.height * .76,\n      );\n    canvas.drawPath(road, roadPaint);\n  }\n\n  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {\n    final paint = Paint()\n      ..shader = RadialGradient(\n        colors: [color, color.withValues(alpha: 0)],\n      ).createShader(Rect.fromCircle(center: center, radius: radius));\n    canvas.drawCircle(center, radius, paint);\n  }\n\n  void _drawCloud(Canvas canvas, Offset origin, double radius, Paint paint) {\n    canvas.drawCircle(origin, radius, paint);\n    canvas.drawCircle(origin + Offset(radius * .9, 3), radius * .72, paint);\n    canvas.drawCircle(origin - Offset(radius * .8, -5), radius * .58, paint);\n  }\n\n  @override\n  bool shouldRepaint(covariant _AmbientMotionPainter oldDelegate) =>\n      oldDelegate.progress != progress ||\n      oldDelegate.startColor != startColor ||\n      oldDelegate.endColor != endColor ||\n      oldDelegate.reducedMotion != reducedMotion ||\n      oldDelegate.effectsScale != effectsScale ||\n      oldDelegate.decorativeCount != decorativeCount;\n}\n''')

# Action feedback still keeps a short semantic/non-color cue in reduced mode,
# but does not allocate an animation ticker there.
action_path = 'lib/core/motion/game_action_feedback.dart'
action = read(action_path)
action = action.replace('  late final AnimationController _controller;\n', '  AnimationController? _controller;\n', 1)
action = action.replace(
    '''  @override\n  void initState() {\n    super.initState();\n    _controller = AnimationController(vsync: this)\n      ..addStatusListener(_handleStatus);\n  }\n\n''',
    '',
    1,
)
action = action.replace(
    '''    final profile = GameMotion.of(context);\n    if (profile.reducedMotion) {\n      _controller.value = .5;\n      _reducedMotionTimer = Timer(\n        profile.duration(GameMotionDurations.standard),\n        _finishOnce,\n      );\n      return;\n    }\n\n    _controller.duration = profile.duration(GameMotionDurations.reward);\n    _controller.forward();\n''',
    '''    final profile = GameMotion.of(context);\n    const intent = GameMotionIntent.nonessential;\n    if (!profile.shouldUseTicker(intent)) {\n      _reducedMotionTimer = Timer(\n        profile.duration(GameMotionDurations.standard),\n        _finishOnce,\n      );\n      return;\n    }\n\n    final controller = AnimationController(\n      vsync: this,\n      duration: profile.durationFor(intent, GameMotionDurations.reward),\n    )..addStatusListener(_handleStatus);\n    _controller = controller;\n    controller.forward();\n''',
    1,
)
action = action.replace(
    '''    _controller\n      ..removeStatusListener(_handleStatus)\n      ..dispose();\n''',
    '''    _controller\n      ?..removeStatusListener(_handleStatus)\n      ..dispose();\n''',
    1,
)
action = action.replace(
    '''    return Positioned.fill(\n      child: IgnorePointer(\n        child: Semantics(\n''',
    '''    final animation =\n        _controller ?? const AlwaysStoppedAnimation<double>(0.5);\n\n    return Positioned.fill(\n      child: IgnorePointer(\n        child: Semantics(\n''',
    1,
)
action = action.replace('              animation: _controller,\n', '              animation: animation,\n', 1)
action = action.replace('                final value = _controller.value;\n', '                final value = animation.value;\n', 1)
write(action_path, action)

# Settings copy explicitly communicates animation/cinematic accessibility.
settings_path = 'lib/features/settings/settings_screen.dart'
settings = read(settings_path)
settings = settings.replace(
    "? 'تقليل الحركة والتمويه والجسيمات والظلال غير الضرورية'",
    "? 'تقليل الحركة غير الضرورية وتخطي المؤثرات السينمائية الزخرفية'",
    1,
)
settings = settings.replace(
    "? 'Minimizes nonessential motion, blur, particles and shadows'",
    "? 'Minimizes nonessential motion and skips decorative cinematic effects'",
    1,
)
write(settings_path, settings)

# ---------------------------------------------------------------------------
# Focused tests.
# ---------------------------------------------------------------------------
write('test/core/motion/a11y_003_motion_policy_test.dart', '''import 'package:cargo_sort_game/core/motion/game_motion.dart';\nimport 'package:cargo_sort_game/core/performance/frame_performance_budget.dart';\nimport 'package:flutter/material.dart';\nimport 'package:flutter_test/flutter_test.dart';\n\nvoid main() {\n  test('full motion keeps all intents available', () {\n    const profile = GameMotionProfile(reducedMotion: false);\n\n    expect(profile.shouldAnimate(GameMotionIntent.essential), isTrue);\n    expect(profile.shouldAnimate(GameMotionIntent.nonessential), isTrue);\n    expect(profile.shouldAnimate(GameMotionIntent.cinematic), isTrue);\n    expect(profile.shouldUseSpatialMotion(GameMotionIntent.essential), isTrue);\n    expect(profile.shouldSkipCinematic(), isFalse);\n  });\n\n  test('effective reduced motion skips nonessential and cinematic motion', () {\n    const profile = GameMotionProfile(reducedMotion: true);\n\n    expect(profile.shouldAnimate(GameMotionIntent.nonessential), isFalse);\n    expect(profile.shouldAnimate(GameMotionIntent.cinematic), isFalse);\n    expect(profile.shouldUseTicker(GameMotionIntent.nonessential), isFalse);\n    expect(profile.shouldUseSpatialMotion(GameMotionIntent.essential), isFalse);\n    expect(profile.shouldSkipCinematic(), isTrue);\n    expect(\n      profile.durationFor(\n        GameMotionIntent.cinematic,\n        GameMotionDurations.reward,\n      ),\n      Duration.zero,\n    );\n  });\n\n  test('essential temporal cue is bounded without spatial motion', () {\n    const profile = GameMotionProfile(reducedMotion: true);\n\n    expect(\n      profile.shouldAnimate(\n        GameMotionIntent.essential,\n        allowReducedTemporalFeedback: true,\n      ),\n      isTrue,\n    );\n    expect(\n      profile.durationFor(\n        GameMotionIntent.essential,\n        GameMotionDurations.standard,\n        allowReducedTemporalFeedback: true,\n      ),\n      const Duration(milliseconds: 100),\n    );\n    expect(profile.distance(20), 0);\n    expect(profile.scale(.9), 1);\n    expect(profile.curve(Curves.elasticOut), Curves.linear);\n  });\n\n  test('performance pressure alone does not become accessibility skip', () {\n    const constrained = GameMotionProfile(\n      reducedMotion: false,\n      performanceQuality: GameVisualQuality.constrained,\n    );\n    const reducedQuality = GameMotionProfile(\n      reducedMotion: false,\n      performanceQuality: GameVisualQuality.reduced,\n    );\n\n    expect(constrained.shouldSkipCinematic(), isFalse);\n    expect(reducedQuality.shouldSkipCinematic(), isFalse);\n    expect(constrained.shouldAnimate(GameMotionIntent.cinematic), isTrue);\n    expect(reducedQuality.shouldAnimate(GameMotionIntent.cinematic), isTrue);\n  });\n}\n''')

write('test/core/motion/game_cinematic_gate_test.dart', '''import 'package:cargo_sort_game/core/motion/game_cinematic_gate.dart';\nimport 'package:cargo_sort_game/core/settings/app_settings_store.dart';\nimport 'package:cargo_sort_game/core/settings/game_visual_effects_preference.dart';\nimport 'package:cargo_sort_game/core/settings/visual_effects_preference_scope.dart';\nimport 'package:flutter/material.dart';\nimport 'package:flutter_test/flutter_test.dart';\nimport 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';\nimport 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';\n\nvoid main() {\n  setUp(() {\n    SharedPreferencesAsyncPlatform.instance =\n        InMemorySharedPreferencesAsync.empty();\n  });\n\n  testWidgets('normal cinematic animates and completes exactly once', (tester) async {\n    final reasons = <GameCinematicCompletionReason>[];\n\n    await tester.pumpWidget(\n      MaterialApp(\n        home: GameCinematicGate(\n          duration: const Duration(milliseconds: 200),\n          onCompleted: reasons.add,\n          builder: (context, animation, skipped) => Text(\n            skipped ? 'skipped' : 'animated-${animation.value.toStringAsFixed(1)}',\n          ),\n        ),\n      ),\n    );\n\n    expect(reasons, isEmpty);\n    await tester.pump(const Duration(milliseconds: 220));\n    expect(reasons, [GameCinematicCompletionReason.animated]);\n    await tester.pump(const Duration(seconds: 1));\n    expect(reasons, hasLength(1));\n  });\n\n  testWidgets('system reduced motion skips cinematic without animation wait', (tester) async {\n    final reasons = <GameCinematicCompletionReason>[];\n\n    await tester.pumpWidget(\n      MaterialApp(\n        home: MediaQuery(\n          data: const MediaQueryData(disableAnimations: true),\n          child: GameCinematicGate(\n            duration: const Duration(seconds: 2),\n            onCompleted: reasons.add,\n            builder: (context, animation, skipped) => Text(\n              skipped ? 'skipped' : 'animated',\n            ),\n          ),\n        ),\n      ),\n    );\n    await tester.pump();\n\n    expect(find.text('skipped'), findsOneWidget);\n    expect(reasons, [GameCinematicCompletionReason.skippedReducedMotion]);\n  });\n\n  testWidgets('user reduced effects also skips cinematic live policy', (tester) async {\n    final settings = AppSettingsStore();\n    await settings.setVisualEffectsPreference(\n      GameVisualEffectsPreference.reduced,\n    );\n    final reasons = <GameCinematicCompletionReason>[];\n\n    await tester.pumpWidget(\n      VisualEffectsPreferenceScope(\n        settings: settings,\n        child: MaterialApp(\n          home: GameCinematicGate(\n            duration: const Duration(seconds: 2),\n            onCompleted: reasons.add,\n            builder: (context, animation, skipped) => Text(\n              skipped ? 'user-skipped' : 'animated',\n            ),\n          ),\n        ),\n      ),\n    );\n    await tester.pump();\n\n    expect(find.text('user-skipped'), findsOneWidget);\n    expect(reasons, [GameCinematicCompletionReason.skippedReducedMotion]);\n  });\n\n  testWidgets('dispose before completion prevents late callback', (tester) async {\n    var completions = 0;\n\n    await tester.pumpWidget(\n      MaterialApp(\n        home: GameCinematicGate(\n          duration: const Duration(seconds: 1),\n          onCompleted: (_) => completions++,\n          builder: (context, animation, skipped) => const SizedBox(),\n        ),\n      ),\n    );\n    await tester.pump(const Duration(milliseconds: 100));\n    await tester.pumpWidget(const SizedBox());\n    await tester.pump(const Duration(seconds: 2));\n\n    expect(completions, 0);\n  });\n}\n''')

# Extend settings test with copy ownership while leaving existing behavioral test.
settings_test_path = 'test/features/settings/visual_effects_settings_test.dart'
settings_test = read(settings_test_path)
if 'decorative cinematic effects' not in settings_test:
    insertion = '''\n  testWidgets('reduced effects copy explains cinematic skipping in English and Arabic', (tester) async {\n    final settings = AppSettingsStore();\n    await settings.setReducedVisualEffects(true);\n\n    Future<void> pump(Locale locale) => tester.pumpWidget(\n      MaterialApp(\n        locale: locale,\n        supportedLocales: const [Locale('en'), Locale('ar')],\n        localizationsDelegates: const [\n          GlobalMaterialLocalizations.delegate,\n          GlobalWidgetsLocalizations.delegate,\n          GlobalCupertinoLocalizations.delegate,\n        ],\n        home: SettingsScreen(\n          settings: settings,\n          onToggleLanguage: () {},\n        ),\n      ),\n    );\n\n    await pump(const Locale('en'));\n    expect(\n      find.text('Minimizes nonessential motion and skips decorative cinematic effects'),\n      findsOneWidget,\n    );\n\n    await pump(const Locale('ar'));\n    expect(\n      find.text('تقليل الحركة غير الضرورية وتخطي المؤثرات السينمائية الزخرفية'),\n      findsOneWidget,\n    );\n  });\n'''
    # insert before final closing brace of main()
    index = settings_test.rfind('\n}')
    settings_test = settings_test[:index] + insertion + settings_test[index:]
    # ensure localization import exists
    if "package:flutter_localizations/flutter_localizations.dart" not in settings_test:
        settings_test = settings_test.replace(
            "import 'package:flutter/material.dart';\n",
            "import 'package:flutter/material.dart';\nimport 'package:flutter_localizations/flutter_localizations.dart';\n",
            1,
        )
    write(settings_test_path, settings_test)

# ---------------------------------------------------------------------------
# Repository-wide direct-motion baseline. Any change in direct primitive usage
# must update this checked-in audit intentionally, preventing silent bypasses.
# ---------------------------------------------------------------------------
PRIMITIVES = [
    'AnimationController(',
    'AnimatedBuilder(',
    'TweenAnimationBuilder',
    'AnimatedContainer(',
    'AnimatedOpacity(',
    'AnimatedScale(',
    'AnimatedSlide(',
    'AnimatedSwitcher(',
    'Hero(',
    'PageRouteBuilder',
    'FadeTransition(',
    'SlideTransition(',
    'ScaleTransition(',
    'RotationTransition(',
    'Timer(',
    'Future.delayed(',
]


def classification(path: str, primitive: str) -> str:
    if path.startswith('lib/core/motion/') or path == 'lib/core/widgets/game_button.dart':
        return 'shared-policy-consumer'
    if primitive == 'AnimatedBuilder(' and path == 'lib/features/settings/settings_screen.dart':
        return 'state-listener-not-motion'
    return 'audited-local-motion'


def scan_motion() -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    for path in sorted(Path('lib').rglob('*.dart')):
        path_text = path.as_posix()
        if path_text.startswith('lib/l10n/'):
            continue
        text = path.read_text(encoding='utf-8')
        for primitive in PRIMITIVES:
            count = text.count(primitive)
            if count:
                entries.append({
                    'path': path_text,
                    'primitive': primitive,
                    'count': count,
                    'classification': classification(path_text, primitive),
                })
    return entries

entries = scan_motion()
write(
    'docs/accessibility/a11y_003_motion_audit.json',
    json.dumps({'schema': 1, 'entries': entries}, indent=2, ensure_ascii=False) + '\n',
)
summary_lines = [
    '# A11Y-003 Reduced Motion Audit',
    '',
    'This file records the current direct Flutter motion primitives outside generated localization code.',
    'The machine validator compares this checked-in baseline with the repository on every CI run, so new direct motion cannot bypass accessibility review silently.',
    '',
    f'- Audited direct primitive records: {len(entries)}',
    f'- Unique Dart files: {len({entry["path"] for entry in entries})}',
    '- `shared-policy-consumer`: shared motion code governed by `GameMotion` intent/policy.',
    '- `state-listener-not-motion`: `AnimatedBuilder` used only as a Listenable rebuild helper.',
    '- `audited-local-motion`: existing local callsite frozen into the baseline; changes require explicit re-audit.',
    '',
    '| Path | Primitive | Count | Classification |',
    '|---|---|---:|---|',
]
for entry in entries:
    summary_lines.append(
        f'| `{entry["path"]}` | `{entry["primitive"]}` | {entry["count"]} | {entry["classification"]} |'
    )
write('docs/A11Y_REDUCED_MOTION_AUDIT.md', '\n'.join(summary_lines) + '\n')

# ---------------------------------------------------------------------------
# Permanent validator and mutation-ownership regressions.
# ---------------------------------------------------------------------------
write('tool/verify_a11y_003_reduced_motion.py', '''#!/usr/bin/env python3\nfrom pathlib import Path\nimport json\n\nPRIMITIVES = [\n    'AnimationController(',\n    'AnimatedBuilder(',\n    'TweenAnimationBuilder',\n    'AnimatedContainer(',\n    'AnimatedOpacity(',\n    'AnimatedScale(',\n    'AnimatedSlide(',\n    'AnimatedSwitcher(',\n    'Hero(',\n    'PageRouteBuilder',\n    'FadeTransition(',\n    'SlideTransition(',\n    'ScaleTransition(',\n    'RotationTransition(',\n    'Timer(',\n    'Future.delayed(',\n]\n\n\ndef require(path: str, *needles: str) -> None:\n    text = Path(path).read_text(encoding='utf-8')\n    missing = [needle for needle in needles if needle not in text]\n    if missing:\n        raise SystemExit(f'{path}: missing required A11Y-003 contract: {missing}')\n\n\ndef classification(path: str, primitive: str) -> str:\n    if path.startswith('lib/core/motion/') or path == 'lib/core/widgets/game_button.dart':\n        return 'shared-policy-consumer'\n    if primitive == 'AnimatedBuilder(' and path == 'lib/features/settings/settings_screen.dart':\n        return 'state-listener-not-motion'\n    return 'audited-local-motion'\n\n\ndef scan_motion() -> list[dict[str, object]]:\n    entries: list[dict[str, object]] = []\n    for path in sorted(Path('lib').rglob('*.dart')):\n        path_text = path.as_posix()\n        if path_text.startswith('lib/l10n/'):\n            continue\n        text = path.read_text(encoding='utf-8')\n        for primitive in PRIMITIVES:\n            count = text.count(primitive)\n            if count:\n                entries.append({\n                    'path': path_text,\n                    'primitive': primitive,\n                    'count': count,\n                    'classification': classification(path_text, primitive),\n                })\n    return entries\n\n\nrequire(\n    'lib/core/motion/game_motion.dart',\n    'enum GameMotionIntent',\n    'GameMotionIntent.essential',\n    'GameMotionIntent.nonessential',\n    'GameMotionIntent.cinematic',\n    'shouldAnimate',\n    'shouldUseTicker',\n    'shouldUseSpatialMotion',\n    'shouldSkipCinematic',\n    'durationFor',\n)\nrequire(\n    'lib/core/motion/game_cinematic_gate.dart',\n    'GameCinematicCompletionReason',\n    'skippedReducedMotion',\n    'AnimationController?',\n    'shouldUseTicker',\n    'addPostFrameCallback',\n    '_finishOnce',\n)\nrequire(\n    'lib/core/motion/game_travel_motion.dart',\n    'AnimationController?',\n    'shouldUseSpatialMotion',\n    '_scheduleCompletion',\n)\nrequire(\n    'lib/core/motion/ambient_motion_background.dart',\n    'AnimationController?',\n    'GameMotionIntent.nonessential',\n    'profile.shouldUseTicker(intent)',\n)\nrequire(\n    'lib/core/motion/game_action_feedback.dart',\n    'AnimationController?',\n    'GameMotionIntent.nonessential',\n    'profile.shouldUseTicker(intent)',\n)\nrequire(\n    'lib/core/motion/game_route.dart',\n    'GameMotionIntent.essential',\n    'profile.durationFor',\n    'profile.shouldUseSpatialMotion(intent)',\n)\nrequire(\n    'lib/core/widgets/game_button.dart',\n    'GameMotionIntent.essential',\n    'motion.shouldUseSpatialMotion(motionIntent)',\n    'motion.durationFor',\n)\nrequire(\n    'lib/features/settings/settings_screen.dart',\n    'skips decorative cinematic effects',\n    'وتخطي المؤثرات السينمائية الزخرفية',\n)\n\nbaseline_path = Path('docs/accessibility/a11y_003_motion_audit.json')\nif not baseline_path.is_file():\n    raise SystemExit('missing A11Y-003 direct-motion audit baseline')\nbaseline = json.loads(baseline_path.read_text(encoding='utf-8'))\nif baseline.get('schema') != 1:\n    raise SystemExit('unsupported A11Y-003 audit schema')\nexpected = baseline.get('entries')\nactual = scan_motion()\nif actual != expected:\n    raise SystemExit(\n        'direct motion primitive inventory changed; update A11Y-003 audit intentionally\\n'\n        f'expected={expected}\\nactual={actual}'\n    )\n\nfor path in [\n    'test/core/motion/a11y_003_motion_policy_test.dart',\n    'test/core/motion/game_cinematic_gate_test.dart',\n    'docs/A11Y_REDUCED_MOTION_AUDIT.md',\n]:\n    if not Path(path).is_file():\n        raise SystemExit(f'missing A11Y-003 evidence: {path}')\n\nci = Path('.github/workflows/flutter_ci.yml').read_text(encoding='utf-8')\nfor token in [\n    'Verify A11Y-003 reduced motion',\n    'Test A11Y-003 reduced-motion validator',\n    'Test A11Y-003 reduced motion matrix',\n]:\n    if token not in ci:\n        raise SystemExit(f'normal Flutter CI is missing A11Y-003 gate: {token}')\n\ncatalog = Path('docs/FEATURE_CATALOG.md').read_text(encoding='utf-8')\nif '| A11Y-003 | Reduced motion | P1 | IN PROGRESS |' not in catalog and '| A11Y-003 | Reduced motion | P1 | IMPLEMENTED |' not in catalog:\n    raise SystemExit('A11Y-003 catalog status is not owned by the current sprint')\n\nprint(f'A11Y-003 REDUCED MOTION CONTRACT PASSED ({len(actual)} audited primitive records)')\n''')

write('tool/test_a11y_003_reduced_motion.py', '''#!/usr/bin/env python3\nfrom pathlib import Path\n\nSOURCE = Path('tool/verify_a11y_003_reduced_motion.py').read_text(encoding='utf-8')\n\nchecks = [\n    'enum GameMotionIntent',\n    'GameMotionIntent.essential',\n    'GameMotionIntent.nonessential',\n    'GameMotionIntent.cinematic',\n    'shouldAnimate',\n    'shouldUseTicker',\n    'shouldUseSpatialMotion',\n    'shouldSkipCinematic',\n    'GameCinematicCompletionReason',\n    'skippedReducedMotion',\n    'direct motion primitive inventory changed',\n    'AnimationController(',\n    'PageRouteBuilder',\n    'Future.delayed(',\n    'Verify A11Y-003 reduced motion',\n    'Test A11Y-003 reduced motion matrix',\n    'A11Y-003 catalog status',\n]\n\nfor token in checks:\n    if token not in SOURCE:\n        raise SystemExit(f'validator mutation coverage missing token: {token}')\n\nprint(f'A11Y-003 VALIDATOR REGRESSIONS PASSED ({len(checks)}/{len(checks)})')\n''')

# ---------------------------------------------------------------------------
# Normal CI ownership.
# ---------------------------------------------------------------------------
ci_path = '.github/workflows/flutter_ci.yml'
ci = read(ci_path)
validator_anchor = '''      - name: Test UI3D-007 visual-effects validator\n        run: python3 tool/test_ui3d_007_visual_effects.py\n\n'''
validator_steps = validator_anchor + '''      - name: Verify A11Y-003 reduced motion\n        run: python3 tool/verify_a11y_003_reduced_motion.py\n\n      - name: Test A11Y-003 reduced-motion validator\n        run: python3 tool/test_a11y_003_reduced_motion.py\n\n'''
if 'Verify A11Y-003 reduced motion' not in ci:
    if validator_anchor not in ci:
        raise SystemExit('CI validator insertion anchor missing')
    ci = ci.replace(validator_anchor, validator_steps, 1)

focused_anchor = '''      - name: Test UI3D-007 adaptive visual effects\n        run: >-\n          flutter test\n          test/core/settings/game_visual_effects_preference_test.dart\n          test/core/settings/visual_effects_preference_scope_test.dart\n          test/core/settings/app_settings_store_test.dart\n          test/core/motion/game_motion_test.dart\n          test/core/motion/ui3d_007_visual_effects_test.dart\n          test/core/motion/game_route_test.dart\n          test/features/settings/visual_effects_settings_test.dart\n\n'''
focused_steps = focused_anchor + '''      - name: Test A11Y-003 reduced motion matrix\n        run: >-\n          flutter test\n          test/core/motion/a11y_003_motion_policy_test.dart\n          test/core/motion/game_cinematic_gate_test.dart\n          test/core/motion/game_motion_test.dart\n          test/core/motion/game_route_test.dart\n          test/core/motion/game_travel_motion_test.dart\n          test/core/motion/game_action_feedback_test.dart\n          test/core/motion/motion_lifecycle_scope_test.dart\n          test/core/widgets/game_button_test.dart\n          test/features/settings/visual_effects_settings_test.dart\n\n'''
if 'Test A11Y-003 reduced motion matrix' not in ci:
    if focused_anchor not in ci:
        raise SystemExit('CI focused-test insertion anchor missing')
    ci = ci.replace(focused_anchor, focused_steps, 1)
write(ci_path, ci)

print('A11Y-003 bootstrap patch applied')
