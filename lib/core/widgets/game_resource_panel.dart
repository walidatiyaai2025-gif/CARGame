import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/three_d_game_icon.dart';
import 'game_panel.dart';

final class GameResourcePanel extends StatelessWidget {
  const GameResourcePanel({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.compact = false,
    this.animateIcon = false,
    this.onTap,
    this.state = GamePanelState.ready,
    this.errorMessage,
    this.semanticLabel,
  });

  final ThreeDIconType icon;
  final String value;
  final String label;
  final bool compact;
  final bool animateIcon;
  final VoidCallback? onTap;
  final GamePanelState state;
  final String? errorMessage;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      onTap: onTap,
      state: state,
      errorMessage: errorMessage,
      semanticLabel: semanticLabel ?? '$label: $value',
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 5 : 7,
      ),
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      backgroundColor: Colors.white.withValues(alpha: .94),
      borderColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThreeDGameIcon(
            type: icon,
            size: compact ? 27 : 32,
            animate: animateIcon,
            semanticLabel: label,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: AppTheme.navy,
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
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
