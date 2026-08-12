import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/application/realtime_3d/cargo_drag_controller.dart';
import '../../core/domain/realtime_3d/cargo_interaction.dart';
import '../../core/domain/realtime_3d/geometry.dart';
import '../../core/settings/visual_effects_preference_scope.dart';
import 'three_js_realtime_3d_scene.dart';

class ThreeJsRealtime3dScreen extends StatefulWidget {
  const ThreeJsRealtime3dScreen({super.key});

  @override
  State<ThreeJsRealtime3dScreen> createState() =>
      _ThreeJsRealtime3dScreenState();
}

class _ThreeJsRealtime3dScreenState extends State<ThreeJsRealtime3dScreen> {
  late final ThreeJsRealtime3dScene _scene;
  late final CargoDragController _dragController;

  bool _draggingCargo = false;
  bool _picking = false;
  bool _dragUpdateInFlight = false;
  ScreenPoint3? _queuedDragPoint;
  String _status = 'Starting native GPU scene…';

  @override
  void initState() {
    super.initState();
    _scene = ThreeJsRealtime3dScene()..addListener(_onSceneStateChanged);
    _dragController = CargoDragController(
      scene: _scene,
      targets: _scene.targets,
      dragLift: 0.42,
    );
  }

  void _onSceneStateChanged() {
    if (!mounted) return;
    if (_scene.setupError != null) {
      setState(() {
        _status =
            'Native renderer unavailable on this device. Use Back for the safe fallback.';
      });
      return;
    }
    if (_scene.isReady && _status == 'Starting native GPU scene…') {
      setState(() {
        _status = 'Drag the blue cargo to the cyan delivery dock.';
      });
    }
  }

  @override
  void dispose() {
    _scene
      ..removeListener(_onSceneStateChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _handlePanStart(DragStartDetails details) async {
    if (!_scene.isReady || _picking || _dragController.isBusy) return;
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
      _status = 'Camera orbit — drag empty space to inspect the native scene.';
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_scene.isReady) return;
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
          'Delivered! Native 3D target accepted this cargo.',
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
      _status = _scene.isReady
          ? 'Drag the blue cargo to the cyan delivery dock.'
          : 'Starting native GPU scene…';
    });
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VisualEffectsPreferenceScope.userReducedEffectsOf(context);
    _scene.setReducedMotion(reducedMotion);

    return Scaffold(
      backgroundColor: const Color(0xFF07182F),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          _scene.setViewport(viewport);
          return Semantics(
            label: 'Native real-time 3D cargo checkpoint',
            value: _status,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xFF07182F),
                    child: _scene.buildSurface(),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('rt3d-native-scene'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    onPanCancel: _handlePanCancel,
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
                        _NativeHudButton(
                          tooltip: 'Back to projected 3D fallback',
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
                              color: const Color(0xE60A2342),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'NATIVE 3D',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'GPU scene • live lights • shadows • cargo interaction',
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
                        const SizedBox(width: 10),
                        _NativeHudButton(
                          tooltip: 'Reset native cargo',
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
                if (!_scene.isReady && _scene.setupError == null)
                  const Center(
                    child: IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            'Starting native 3D renderer…',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_scene.setupError != null)
                  Center(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xF01B2A3B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFF8A80),
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          'Native 3D could not start on this device.\n'
                          'The projected 3D scene remains available as a safe fallback.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                        key: const Key('rt3d-native-status'),
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

class _NativeHudButton extends StatelessWidget {
  const _NativeHudButton({
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
        color: const Color(0xE60A2342),
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
