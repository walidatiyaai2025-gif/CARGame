import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../game/city_catalog.dart';
import '../game/level_data.dart';
import 'city_briefing_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key, required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final skin = gameSkinById(store.selectedTheme);
        return Scaffold(
          appBar: AppBar(
            title: Text(isArabic ? 'خريطة العالم' : 'World Map'),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(gradient: skin.backgroundGradient),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _GlobalHeader(
                  isArabic: isArabic,
                  store: store,
                  skin: skin,
                ),
                const SizedBox(height: 18),
                for (final world in gameWorlds) ...[
                  _WorldSection(
                    world: world,
                    levels: levels.where((level) => level.world == world.number).toList(),
                    store: store,
                    isArabic: isArabic,
                    skin: skin,
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlobalHeader extends StatelessWidget {
  const _GlobalHeader({
    required this.isArabic,
    required this.store,
    required this.skin,
  });

  final bool isArabic;
  final ProgressStore store;
  final GameSkin skin;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: skin.heroGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: skin.primary.withValues(alpha: .28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.public_rounded, color: skin.accent, size: 44),
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
                            ? '${store.completedLevels} مدينة مكتملة من ${ProgressStore.totalLevels}'
                            : '${store.completedLevels} of ${ProgressStore.totalLevels} cities completed',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.star_rounded, color: skin.accent),
                    Text(
                      '${store.totalStars}/${store.maximumStars}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: store.completionProgress,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(skin.accent),
              ),
            ),
          ],
        ),
      );
}

class _WorldSection extends StatelessWidget {
  const _WorldSection({
    required this.world,
    required this.levels,
    required this.store,
    required this.isArabic,
    required this.skin,
  });

  final GameWorld world;
  final List<LevelData> levels;
  final ProgressStore store;
  final bool isArabic;
  final GameSkin skin;

  @override
  Widget build(BuildContext context) {
    final unlocked = store.highestUnlockedLevel >= levels.first.number;
    final completed = levels.where((level) => level.number < store.highestUnlockedLevel).length;
    final stars = levels.fold<int>(
      0,
      (sum, level) => sum + store.starsForLevel(level.number),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
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
              gradient: LinearGradient(
                colors: [
                  Color.lerp(world.startColor, skin.primary, .20)!,
                  Color.lerp(world.endColor, skin.secondary, .20)!,
                ],
              ),
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
                            ? '$completed/25 ${isArabic ? 'مدينة' : 'cities'} • ⭐ $stars/75'
                            : (isArabic
                                ? 'أكمل العالم السابق لفتحه'
                                : 'Complete the previous world to unlock'),
                        style: const TextStyle(color: Colors.white70),
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
                  return _CityCard(
                    level: level,
                    unlocked: cityUnlocked,
                    stars: store.starsForLevel(level.number),
                    world: world,
                    skin: skin,
                    isArabic: isArabic,
                    onTap: cityUnlocked
                        ? () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CityBriefingScreen(
                                  level: level,
                                  store: store,
                                ),
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
              child: Text(
                isArabic ? 'هذا العالم ما زال مقفلاً' : 'This world is still locked',
                style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
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
    required this.skin,
    required this.isArabic,
    required this.onTap,
  });

  final LevelData level;
  final bool unlocked;
  final int stars;
  final GameWorld world;
  final GameSkin skin;
  final bool isArabic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final boss = level.isBossCity;
    final accent = boss ? AppTheme.orange : Color.lerp(world.startColor, skin.primary, .18)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: unlocked ? Colors.white : const Color(0xFFE0E3E8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unlocked ? accent : Colors.black12,
              width: boss ? 2.5 : 1.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 102;
              final padding = compact ? 6.0 : 9.0;
              final iconBox = compact ? 36.0 : 42.0;
              final iconSize = compact ? 21.0 : 24.0;
              final gap = compact ? 4.0 : 7.0;
              final cityFont = compact ? 10.0 : 11.0;
              final levelFont = compact ? 8.0 : 9.0;
              final starSize = compact ? 12.0 : 14.0;

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: unlocked ? accent : Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        unlocked
                            ? boss
                                ? Icons.workspace_premium_rounded
                                : Icons.location_city_rounded
                            : Icons.lock_rounded,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(height: gap),
                    Flexible(
                      child: Text(
                        level.cityName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: unlocked ? AppTheme.navy : Colors.black38,
                          fontSize: cityFont,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isArabic ? 'مرحلة' : 'Level'} ${level.number}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: levelFont,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => Icon(
                          index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: starSize,
                          color: index < stars ? skin.accent : Colors.black12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
