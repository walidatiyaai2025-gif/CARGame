import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum GamePanelState { ready, loading, error }

class GamePanel extends StatefulWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.onTap,
    this.state = GamePanelState.ready,
    this.errorMessage,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.clipBehavior = Clip.antiAlias,
    this.enabled = true,
    this.minHeight,
  });

  final Widget child;
  final VoidCallback? onTap;
  final GamePanelState state;
  final String? errorMessage;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final Clip clipBehavior;
  final bool enabled;
  final double? minHeight;

  @override
  State<GamePanel> createState() => _GamePanelState();
}

class _GamePanelState extends State<GamePanel> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _interactive =>
      widget.enabled &&
      widget.state == GamePanelState.ready &&
      widget.onTap != null;

  bool get _desktopHoverSupported =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  void _setPressed(bool value) {
    if (_pressed == value || !_interactive) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (!_desktopHoverSupported || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor =
        widget.backgroundColor ?? theme.colorScheme.surface.withValues(alpha: .96);
    final border =
        widget.borderColor ?? theme.colorScheme.outlineVariant.withValues(alpha: .55);
    final scale = _pressed ? .985 : (_hovered && _interactive ? 1.008 : 1.0);
    final depth = _pressed ? 3.0 : (_hovered && _interactive ? 14.0 : 9.0);
    final offsetY = _pressed ? 2.0 : 0.0;

    Widget content = switch (widget.state) {
      GamePanelState.ready => widget.child,
      GamePanelState.loading => const _GamePanelSkeleton(),
      GamePanelState.error => _GamePanelError(
        message: widget.errorMessage ?? 'Unable to load this content.',
      ),
    };

    content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
      child: Padding(padding: widget.padding, child: content),
    );

    final panel = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, offsetY, 0)..scale(scale, scale),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.gradient == null ? baseColor : null,
        gradient: widget.gradient,
        borderRadius: widget.borderRadius,
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: .10),
            blurRadius: depth * 2.2,
            offset: Offset(0, depth),
          ),
          const BoxShadow(
            color: Color(0x8AFFFFFF),
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: _hovered ? .24 : .16),
            Colors.transparent,
            Colors.black.withValues(alpha: .025),
          ],
          stops: const [0, .42, 1],
        ),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        clipBehavior: widget.clipBehavior,
        child: content,
      ),
    );

    if (!_interactive) {
      return Semantics(
        container: true,
        label: widget.semanticLabel,
        enabled: widget.enabled,
        child: panel,
      );
    }

    return Semantics(
      button: true,
      enabled: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) {
          _setHovered(false);
          _setPressed(false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: widget.onTap,
          child: panel,
        ),
      ),
    );
  }
}

class _GamePanelSkeleton extends StatefulWidget {
  const _GamePanelSkeleton();

  @override
  State<_GamePanelSkeleton> createState() => _GamePanelSkeletonState();
}

class _GamePanelSkeletonState extends State<_GamePanelSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reducedMotion && !_controller.isAnimating) {
      _controller.repeat();
    }

    return Semantics(
      liveRegion: true,
      label: 'Loading',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = reducedMotion ? .35 : _controller.value;
            final color = Color.lerp(
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).colorScheme.surfaceContainerLow,
              value,
            )!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SkeletonBar(widthFactor: .55, color: color),
                const SizedBox(height: 10),
                _SkeletonBar(widthFactor: .92, color: color),
                const SizedBox(height: 7),
                _SkeletonBar(widthFactor: .72, color: color),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.widthFactor, required this.color});

  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

class _GamePanelError extends StatelessWidget {
  const _GamePanelError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: message,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
