import 'package:flutter/material.dart';

import 'game_panel.dart';

final class GameHeroPanel extends StatelessWidget {
  const GameHeroPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.body,
    this.progress,
    this.progressLabel,
    this.gradient,
    this.backgroundColor,
    this.semanticLabel,
    this.state = GamePanelState.ready,
    this.errorMessage,
    this.compact = false,
    this.onTap,
  }) : assert(progress == null || (progress >= 0 && progress <= 1));

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? body;
  final double? progress;
  final String? progressLabel;
  final Gradient? gradient;
  final Color? backgroundColor;
  final String? semanticLabel;
  final GamePanelState state;
  final String? errorMessage;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = gradient == null
        ? theme.colorScheme.onSurface
        : Colors.white;
    final secondaryForeground = gradient == null
        ? theme.colorScheme.onSurfaceVariant
        : Colors.white70;

    return GamePanel(
      onTap: onTap,
      state: state,
      errorMessage: errorMessage,
      semanticLabel: semanticLabel ?? title,
      padding: EdgeInsets.all(compact ? 14 : 18),
      borderRadius: BorderRadius.circular(compact ? 24 : 28),
      gradient: gradient,
      backgroundColor: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: compact ? 10 : 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: compact ? 17 : 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryForeground,
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: compact ? 8 : 12),
                trailing!,
              ],
            ],
          ),
          if (body != null) ...[
            SizedBox(height: compact ? 10 : 14),
            body!,
          ],
          if (progress != null) ...[
            SizedBox(height: compact ? 10 : 14),
            Row(
              children: [
                if (progressLabel != null)
                  Expanded(
                    child: Text(
                      progressLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryForeground,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                Text(
                  '${(progress! * 100).round()}%',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: compact ? 8 : 10,
                backgroundColor: gradient == null
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  gradient == null
                      ? theme.colorScheme.primary
                      : Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
