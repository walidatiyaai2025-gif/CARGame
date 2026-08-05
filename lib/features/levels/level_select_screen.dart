import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../game/game_screen.dart';
import '../game/level_data.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key, required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.levels),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) => GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.92,
          ),
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            final unlocked = level.number <= store.highestUnlockedLevel;

            return InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: unlocked
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GameScreen(level: level, store: store),
                        ),
                      )
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: unlocked
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFEFF4FA)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFE1E4E8), Color(0xFFCDD2D8)],
                        ),
                  border: Border.all(
                    color: unlocked ? AppTheme.orange : Colors.black12,
                    width: unlocked ? 2 : 1,
                  ),
                  boxShadow: unlocked
                      ? const [
                          BoxShadow(
                            color: Color(0x24000000),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: unlocked ? AppTheme.navy : Colors.black26,
                        ),
                        child: Icon(
                          unlocked ? Icons.route_rounded : Icons.lock_rounded,
                          size: 38,
                          color: unlocked ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${l10n.level} ${level.number}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: unlocked ? AppTheme.navy : Colors.black45,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            unlocked
                                ? Icons.flag_circle_rounded
                                : Icons.lock_clock_rounded,
                            size: 18,
                            color: unlocked ? AppTheme.orange : Colors.black38,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              unlocked
                                  ? '${level.moves} ${l10n.moves}'
                                  : l10n.locked,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: unlocked
                                        ? Colors.black54
                                        : Colors.black38,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
