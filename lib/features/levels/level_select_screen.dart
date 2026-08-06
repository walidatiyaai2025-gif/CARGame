import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../game/city_catalog.dart';
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
        title: Text(isArabic ? 'خريطة العالم' : 'World Map'),
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
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _GlobalHeader(
                isArabic: isArabic,
                completed: store.completedLevels,
                total: ProgressStore.totalLevels,
                stars: store.totalStars,
                maximumStars: store.maximumStars,
              ),
              const SizedBox(height: 18),
              for (final world in gameWorlds) ...[
                _WorldSection(
                  world: world,
                  levels: levels.where((level) => level.world == world.number).toList(),
                  store: store,
                  isArabic: isArabic,
                  levelLabel: l10n.level,
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalHeader extends StatelessWidget {
  const _GlobalHeader({
    required this.isArabic,
    required this.completed,
    required this.total,
    required this.stars,
    required this.maximumStars,
  });

  final bool isArabic;
  final int completed;
  final int total;
  final int stars;
  final int maximumStars;

  @override
  Widget build(BuildContext context) {
    final progress = completed / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142A47), Color(0xFF2D5D8F)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0x33142A47), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.public_rounded, color: AppTheme.yellow, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'رحلة المدن العالمية' : 'Global City Journey',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isArabic
                          ? '$completed مدينة مكتملة من $total'
                          : '$completed of $total cities completed',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.star_rounded, color: AppTheme.yellow),
                  Text(
                    '$stars/$maximumStars',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ],
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

class _WorldSection extends StatelessWidget {
  const _WorldSection({
    required this.world,
    required this.levels,
    required this.store,
    required this.isArabic,
    required this.levelLabel,
  });

  final GameWorld world;
  final List<LevelData> levels;
  final ProgressStore store;
  final bool isArabic;
  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    final firstLevel = levels.first.number;
    final lastLevel = levels.last.number;
    final unlocked = store.highestUnlockedLevel >= firstLevel;
    final completedInWorld = levels
        .where((level) => level.number < store.highestUnlockedLevel)
        .length;
    final starsInWorld = levels.fold<int>(
      0,
      (sum, level) => sum + store.starsForLevel(level.number),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 18, offset: Offset(0, 9)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [world.startColor, world.endColor]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(world.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isArabic ? 'العالم' : 'World'} ${world.number}: ${world.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        unlocked
                            ? '$completedInWorld/25 ${isArabic ? 'مدينة' : 'cities'} • ⭐ $starsInWorld/75'
                            : (isArabic ? 'أكمل العالم السابق لفتحه' : 'Complete the previous world to unlock'),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Icon(
                  unlocked ? Icons.map_rounded : Icons.lock_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          if (unlocked)
            Padding(
              padding: const EdgeInsets.all(14),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: levels.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: .82,
                ),
                itemBuilder: (context, index) {
                  final level = levels[index];
                  final cityUnlocked = level.number <= store.highestUnlockedLevel;
                  final stars = store.starsForLevel(level.number);
                  return _CityCard(
                    level: level,
                    unlocked: cityUnlocked,
                    stars: stars,
                    world: world,
                    levelLabel: levelLabel,
                    onTap: cityUnlocked
                        ? () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GameScreen(level: level, store: store),
                              ),
                            );
                          }
                        : null,
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_clock_rounded, color: Colors.black38),
                  const SizedBox(width: 8),
                  Text(
                    '${isArabic ? 'المراحل' : 'Levels'} $firstLevel–$lastLevel',
                    style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.world,
    required this.levelLabel,
    required this.onTap,
  });

  final LevelData level;
  final bool unlocked;
  final int stars;
  final GameWorld world;
  final String levelLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final boss = level.isBossCity;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: unlocked
                ? LinearGradient(
                    colors: boss
                        ? const [Color(0xFFFFD86F), Color(0xFFFF9B36)]
                        : [Colors.white, world.startColor.withValues(alpha: .10)],
                  )
                : const LinearGradient(colors: [Color(0xFFE6E9ED), Color(0xFFD5DAE0)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: boss
                  ? AppTheme.orange
                  : unlocked
                      ? world.startColor.withValues(alpha: .45)
                      : Colors.black12,
              width: boss ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: unlocked ? world.startColor : Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked
                      ? boss
                          ? Icons.workspace_premium_rounded
                          : Icons.location_city_rounded
                      : Icons.lock_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                level.cityName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: unlocked ? AppTheme.navy : Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$levelLabel ${level.number}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 9),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Icon(
                    index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: index < stars ? AppTheme.yellow : Colors.black12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
