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
      appBar: AppBar(title: Text(l10n.levels), centerTitle: true),
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
          builder: (context, _) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: _JourneyHeader(
                    title: isArabic ? 'رحلة الشحن العالمية' : 'Global Cargo Journey',
                    subtitle: isArabic
                        ? '150 مرحلة داخل 6 عوالم احترافية'
                        : '150 levels across 6 professional worlds',
                    unlocked: store.highestUnlockedLevel,
                    total: levels.length,
                  ),
                ),
              ),
              ...gameWorlds.expand(
                (world) => [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                    sliver: SliverToBoxAdapter(
                      child: _WorldHeader(
                        world: world,
                        completed: store.highestUnlockedLevel > world.number * 25,
                        unlocked: store.highestUnlockedLevel >= ((world.number - 1) * 25 + 1),
                        isArabic: isArabic,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: .88,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final levelNumber = (world.number - 1) * 25 + index + 1;
                          final level = levels[levelNumber - 1];
                          final unlocked = level.number <= store.highestUnlockedLevel;
                          final completed = level.number < store.highestUnlockedLevel;
                          final isBoss = level.number % 25 == 0;

                          return _LevelCard(
                            level: level,
                            world: world,
                            unlocked: unlocked,
                            completed: completed,
                            isBoss: isBoss,
                            levelLabel: l10n.level,
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
                        childCount: 25,
                      ),
                    ),
                  ),
                ],
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({required this.title, required this.subtitle, required this.unlocked, required this.total});

  final String title;
  final String subtitle;
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = ((unlocked - 1).clamp(0, total)) / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142A47), Color(0xFF2D5D8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Color(0x33142A47), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(color: Color(0x22FFFFFF), shape: BoxShape.circle),
                child: const Icon(Icons.public_rounded, color: AppTheme.orange, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Text('${(progress * 100).round()}%', style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w900, fontSize: 20)),
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

class _WorldHeader extends StatelessWidget {
  const _WorldHeader({required this.world, required this.completed, required this.unlocked, required this.isArabic});

  final GameWorld world;
  final bool completed;
  final bool unlocked;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final start = (world.number - 1) * 25 + 1;
    final end = world.number * 25;
    return AnimatedOpacity(
      opacity: unlocked ? 1 : .55,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [world.startColor, world.endColor]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: world.startColor.withValues(alpha: .28), blurRadius: 18, offset: const Offset(0, 9))],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(18)),
              child: Icon(world.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'العالم ${world.number} — ${world.name}' : 'World ${world.number} — ${world.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text('$start–$end • ${world.subtitle}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(completed ? Icons.workspace_premium_rounded : unlocked ? Icons.lock_open_rounded : Icons.lock_rounded, color: Colors.white, size: 30),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.world,
    required this.unlocked,
    required this.completed,
    required this.isBoss,
    required this.levelLabel,
    required this.lockedLabel,
    required this.onTap,
  });

  final LevelData level;
  final GameWorld world;
  final bool unlocked;
  final bool completed;
  final bool isBoss;
  final String levelLabel;
  final String lockedLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: unlocked
                ? LinearGradient(colors: [Colors.white, world.endColor.withValues(alpha: .13)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : const LinearGradient(colors: [Color(0xFFE4E8ED), Color(0xFFD2D8DF)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isBoss
                  ? AppTheme.orange
                  : completed
                      ? const Color(0xFF52B788)
                      : unlocked
                          ? world.startColor
                          : Colors.black12,
              width: isBoss ? 3 : 2,
            ),
            boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 7))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: unlocked
                        ? LinearGradient(colors: [world.startColor, world.endColor])
                        : const LinearGradient(colors: [Color(0xFF9AA6B2), Color(0xFF7D8995)]),
                  ),
                  child: Icon(
                    completed
                        ? Icons.check_rounded
                        : isBoss
                            ? Icons.local_fire_department_rounded
                            : unlocked
                                ? Icons.inventory_2_rounded
                                : Icons.lock_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 9),
                Text('$levelLabel ${level.number}', maxLines: 1, style: TextStyle(color: unlocked ? AppTheme.navy : Colors.black45, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  unlocked ? (isBoss ? 'BOSS' : '★' * level.difficulty.clamp(1, 3)) : lockedLabel,
                  style: TextStyle(color: isBoss ? AppTheme.orange : unlocked ? world.startColor : Colors.black38, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
