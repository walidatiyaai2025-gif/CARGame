import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/three_d_game_icon.dart';
import 'game_panel.dart';

final class GameStatPanel extends StatelessWidget {
  const GameStatPanel({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconData,
    this.accent = AppTheme.orange,
    this.compact = false,
    this.state = GamePanelState.ready,
    this.errorMessage,
    this.semanticLabel,
  }) : assert(icon == null || iconData == null);

  final String value;
  final String label;
  final ThreeDIconType? icon;
  final IconData? iconData;
  final Color accent;
  final bool compact;
  final GamePanelState state;
  final String? errorMessage;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final leading = icon != null
        ? ThreeDGameIcon(
            type: icon!,
            size: compact ? 24 : 30,
            semanticLabel: label,
          )
        : iconData != null
        ? Icon(iconData, color: accent, size: compact ? 20 : 24)
        : null;

    return GamePanel(
      state: state,
      errorMessage: errorMessage,
      semanticLabel: semanticLabel ?? '$label: $value',
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 9 : 12,
      ),
      borderRadius: BorderRadius.circular(compact ? 18 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            SizedBox(height: compact ? 3 : 5),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: AppTheme.navy,
                fontSize: compact ? 16 : 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
