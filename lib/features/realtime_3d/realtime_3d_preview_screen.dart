import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/application/realtime_3d/cargo_drag_controller.dart';
import '../../core/domain/realtime_3d/cargo_interaction.dart';
import '../../core/domain/realtime_3d/geometry.dart';
import '../../core/settings/visual_effects_preference_scope.dart';
import 'projected_realtime_3d_scene.dart';
import 'three_js_realtime_3d_screen.dart';

class Realtime3dPreviewScreen extends StatefulWidget {
  const Realtime3dPreviewScreen({super.key});

  @override
  State<Realtime3dPreviewScreen> createState() =>
      _Realtime3dPreviewScreenState();
}

class _Realtime3dPreviewScreenState extends State<Realtime3dPreviewScreen> {
  late final ProjectedRealtime3dScene _scene;
  late final CargoDragController _dragController;

  bool _draggingCargo = false;
  bool _picking = false;
  bool _dragUpdateInFlight = false;
  ScreenPoint3? _queuedDragPoint;
  String _status = 'Drag the blue cargo to the matching delivery dock.';

  @override
  void initState() {
    super.initState();
    _scene = ProjectedRealtime3dScene();
    _dragController = CargoDragController(
      scene: _scene,
      targets: _scene.targets,
      dragLift: 0.42,
    );
  }

  @override
  void dispose() {
    _scene.dispose();
    super.dispose();
  }

  Future<void> _openNative3d() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ThreeJsRealtime3dScreen()),
    );
  }

  Future<void> _handlePanStart(DragStartDetails details) async {
    if (_picking || _dragController.isBusy) return;
    _picking = true;
    final result = await _dragController.beginDrag(
      ScreenPoint3(details.localPosition.dx, details.localPosition.dy),
    );
    _picking = false;
    if (!mounted) return;

    if (result.outcome == CargoInteractionOutcome.picked) {
      setState(() {
        _draggingCargo = true;
        _status = 'Cargo selected — move it onto a delivery dock.';
      });
      return;
    }

    setState(() {
      _draggingCargo = false;
      _status = 'Camera orbit — drag empty space to inspect the 3D scene.';
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_draggingCargo) {
      _scene.orbitBy(details.delta);
      return;
    }

    _queuedDragPoint = ScreenPoint3(
      details.localPosition.dx,
      details.localPosition.dy,
    );
    if (!_dragUpdateInFlight) {
      unawaited(_flushDragUpdates());
    }
  }

  Future<void> _flushDragUpdates() async {
    _dragUpdateInFlight = true;
    try {
      while (true) {
        final point = _queuedDragPoint;
        if (point == null) break;
        _queuedDragPoint = null;
        await _dragController.updateDrag(point);
      }
    } finally {
      _dragUpdateInFlight = false;
    }
  }

  Future<void> _waitForDragUpdates() async {
    while (_dragUpdateInFlight) {
      await Future<void>.delayed(Duration.zero);
    }
    if (_queuedDragPoint != null) {
      await _flushDragUpdates();
    }
  }

  Future<void> _handlePanEnd(DragEndDetails details) async {
    if (!_draggingCargo) return;
    await _waitForDragUpdates();
    final result = await _dragController.endDrag();
    if (!mounted) return;
    setState(() {
      _draggingCargo = false;
      _status = switch (result.outcome) {
        CargoInteractionOutcome.accepted =>
          'Delivered! The dock accepted this cargo.',
        CargoInteractionOutcome.wrongTarget =>
          'Wrong building. Cargo returned to the warehouse.',
        CargoInteractionOutcome.missed =>
          'Missed the delivery dock. Cargo returned safely.',
        _ => 'Interaction resolved. Try another delivery.',
      };
    });
  }

  Future<void> _handlePanCancel() async {
    if (!_draggingCargo) return;
    await _waitForDragUpdates();
    await _dragController.cancelDrag();
    if (!mounted) return;
    setState(() {
      _draggingCargo = false;
      _status = 'Delivery cancelled. Cargo returned to the warehouse.';
    });
  }

  void _resetDemo() {
    _scene.resetCargo();
    setState(() {
      _draggingCargo = false;
      _status = 'Drag the blue cargo to the matching delivery dock.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VisualEffectsPreferenceScope.userReducedEffectsOf(context);
    _scene.setReducedMotion(reducedMotion);

    return Scaffold(
      backgroundColor: const Color(0xFF061A31),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          _scene.setViewport(viewport);
          return Semantics(
            label: 'Interactive 3D cargo visual checkpoint',
            value: _status,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('rt3d-preview-scene'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    onPanCancel: _handlePanCancel,
                    child: ListenableBuilder(
                      listenable: _scene,
                      builder: (context, _) => CustomPaint(
                        painter: Realtime3dPreviewPainter(_scene),
                        size: viewport,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 14,
                  end: 14,
                  top: 12,
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        _RoundHudButton(
                          tooltip: 'Back',
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xD90A2342),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '3D VISUAL LAB',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Projected fallback + native GPU checkpoint',
                                  style: TextStyle(
                                    color: Color(0xFFC2D9EC),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        KeyedSubtree(
                          key: const Key('open-native-3d'),
                          child: _RoundHudButton(
                            tooltip: 'Open native real-time 3D scene',
                            onTap: () => unawaited(_openNative3d()),
                            child: const Text(
                              'GPU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RoundHudButton(
                          tooltip: 'Reset cargo',
                          onTap: _resetDemo,
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 18,
                  end: 18,
                  bottom: 18,
                  child: SafeArea(
                    top: false,
                    child: IgnorePointer(
                      child: Container(
                        key: const Key('rt3d-preview-status'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xE60A2342),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoundHudButton extends StatelessWidget {
  const _RoundHudButton({
    required this.tooltip,
    required this.child,
    required this.onTap,
  });

  final String tooltip;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xD90A2342),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 46, height: 46, child: Center(child: child)),
        ),
      ),
    );
  }
}
