import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/three_d_game_icon.dart';
import 'game_panel.dart';

final class GameActionPanel extends StatelessWidget {
  const GameActionPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.animateIcon = false,
    this.state = GamePanelState.ready,
    this.errorMessage,
    this.semanticLabel,
    this.compact = false,
  });

  final ThreeDIconType icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool animateIcon;
  final GamePanelState state;
  final String? errorMessage;
  final String? semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      onTap: onTap,
      state: state,
      errorMessage: errorMessage,
      semanticLabel: semanticLabel ?? '$title. $subtitle',
      padding: EdgeInsets.all(compact ? 10 : 14),
      borderRadius: BorderRadius.circular(compact ? 20 : 24),
      backgroundColor: Colors.white.withValues(alpha: .94),
      child: Row(
        children: [
          ThreeDGameIcon(
            type: icon,
            size: compact ? 42 : 52,
            animate: animateIcon,
            semanticLabel: title,
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.orange,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
