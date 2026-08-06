import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef GameButtonCallback = FutureOr<void> Function();
typedef GameButtonFeedbackHook = FutureOr<void> Function();

class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.loading = false,
    this.enabled = true,
    this.hapticsEnabled = true,
    this.onSound,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.gradient,
    this.backgroundColor,
    this.disabledColor = const Color(0xFF9EA6B0),
    this.shadowColor = const Color(0x55000000),
    this.loadingIndicatorColor = Colors.white,
    this.expand = false,
  });

  final Widget child;
  final GameButtonCallback? onPressed;
  final String? semanticLabel;
  final bool loading;
  final bool enabled;
  final bool hapticsEnabled;
  final GameButtonFeedbackHook? onSound;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color disabledColor;
  final Color shadowColor;
  final Color loadingIndicatorColor;
  final bool expand;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;
  bool _hovered = false;
  bool _running = false;

  bool get _interactive =>
      widget.enabled && !widget.loading && !_running && widget.onPressed != null;

  Future<void> _activate() async {
    if (!_interactive) return;
    setState(() => _running = true);
    try {
      if (widget.hapticsEnabled) {
        await HapticFeedback.selectionClick();
      }
      await widget.onSound?.call();
      await widget.onPressed?.call();
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _pressed = false;
        });
      }
    }
  }

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !_interactive && !_running && !widget.loading;
    final showLoading = widget.loading || _running;
    final hoverSupported = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final translateY = _pressed ? 5.0 : (_hovered && hoverSupported ? -2.0 : 0.0);
    final scale = _pressed ? .975 : (_hovered && hoverSupported ? 1.012 : 1.0);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      height: widget.height,
      width: widget.expand ? double.infinity : null,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: disabled ? widget.disabledColor : widget.backgroundColor,
        gradient: disabled ? null : widget.gradient,
        borderRadius: widget.borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: disabled ? .10 : .24)),
        boxShadow: [
          BoxShadow(
            color: disabled ? Colors.transparent : widget.shadowColor,
            blurRadius: _pressed ? 8 : 20,
            offset: Offset(0, _pressed ? 4 : 11),
          ),
          if (_hovered && hoverSupported && !disabled)
            BoxShadow(
              color: Colors.white.withValues(alpha: .18),
              blurRadius: 13,
              spreadRadius: 1,
            ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: showLoading
            ? SizedBox(
                key: const ValueKey('loading'),
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: widget.loadingIndicatorColor,
                ),
              )
            : KeyedSubtree(key: const ValueKey('content'), child: widget.child),
      ),
    );

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _interactive,
        mouseCursor: _interactive ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onShowHoverHighlight: (value) {
          if (hoverSupported && mounted) setState(() => _hovered = value);
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              unawaited(_activate());
              return null;
            },
          ),
        },
        child: AnimatedScale(
          scale: scale,
          duration: Duration(milliseconds: _pressed ? 70 : 240),
          curve: _pressed ? Curves.easeOut : Curves.elasticOut,
          child: AnimatedSlide(
            offset: Offset(0, translateY / 70),
            duration: Duration(milliseconds: _pressed ? 70 : 240),
            curve: _pressed ? Curves.easeOut : Curves.elasticOut,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: widget.borderRadius,
                onTap: _interactive ? _activate : null,
                onTapDown: (_) => _setPressed(true),
                onTapCancel: () => _setPressed(false),
                onTapUp: (_) => _setPressed(false),
                splashColor: Colors.white.withValues(alpha: .18),
                highlightColor: Colors.white.withValues(alpha: .08),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
