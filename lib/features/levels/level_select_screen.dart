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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.levels),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6FAFF), Color(0xFFE9F1FB)],
          ),
        ),
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            itemCount: levels.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _JourneyHeader(
                  title: isArabic ? 'رحلة الشحن' : 'Cargo Journey',
                  subtitle: isArabic
                      ? 'افتح المراحل ورتّب كل الشحنات'
                      : 'Unlock levels and sort every shipment',
                  unlocked: store.highestUnlockedLevel,
                  total: levels.length,
                );
              }

              final level = levels[index - 1];
              final unlocked = level.number <= store.highestUnlockedLevel;
              final completed = level.number < store.highestUnlockedLevel;
              final alignLeft = level.number.isOdd;

              return _JourneyLevelTile(
                level: level,
                unlocked: unlocked,
                completed: completed,
                alignLeft: alignLeft,
                levelLabel: l10n.level,
                movesLabel: l10n.moves,
                lockedLabel: l10n.locked,
                onTap: unlocked
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GameScreen(level: level, store: store),
                          ),
                        )
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({
    required this.title,
    required this.subtitle,
    required this.unlocked,
    required this.total,
  });

  final String title;
  final String subtitle;
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = ((unlocked - 1).clamp(0, total)) / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142A47), Color(0xFF2D5D8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33142A47),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0x22FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppTheme.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyLevelTile extends StatelessWidget {
  const _JourneyLevelTile({
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.alignLeft,
    required this.levelLabel,
    required this.movesLabel,
    required this.lockedLabel,
    required this.onTap,
  });

  final LevelData level;
  final bool unlocked;
  final bool completed;
  final bool alignLeft;
  final String levelLabel;
  final String movesLabel;
  final String lockedLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: completed ? AppTheme.orange : const Color(0xFFD2DCE8),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Align(
            alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * .68,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(28),
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: unlocked
                        ? const LinearGradient(
                            colors: [Colors.white, Color(0xFFF4F8FD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFE7EBF0), Color(0xFFD7DDE5)],
                          ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: completed
                          ? const Color(0xFF52B788)
                          : unlocked
                              ? AppTheme.orange
                              : const Color(0xFFC8D0DA),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: unlocked
                              ? const LinearGradient(
                                  colors: [Color(0xFF1E3A5F), Color(0xFF356B9E)],
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFF9AA6B2), Color(0xFF7D8995)],
                                ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          completed
                              ? Icons.check_rounded
                              : unlocked
                                  ? Icons.local_shipping_rounded
                                  : Icons.lock_rounded,
                          color: completed ? const Color(0xFF8CF0B8) : Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$levelLabel ${level.number}',
                              style: TextStyle(
                                color: unlocked ? AppTheme.navy : Colors.black45,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              unlocked ? '${level.moves} $movesLabel' : lockedLabel,
                              style: TextStyle(
                                color: unlocked ? Colors.black54 : Colors.black38,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        completed
                            ? Icons.stars_rounded
                            : unlocked
                                ? Icons.play_circle_fill_rounded
                                : Icons.lock_clock_rounded,
                        color: completed
                            ? const Color(0xFFFFC83D)
                            : unlocked
                                ? AppTheme.orange
                                : Colors.black26,
                        size: 34,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
