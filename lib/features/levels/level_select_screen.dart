import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../../core/theme/three_d_game_icon.dart';
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
                _GlobalHeader(isArabic: isArabic, store: store, skin: skin),
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
  const _GlobalHeader({required this.isArabic, required this.store, required this.skin});

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
        child: Stack(
          children: [
            PositionedDirectional(
              end: -18,
              top: -15,
              child: Opacity(
                opacity: .13,
                child: ThreeDGameIcon(type: ThreeDIconType.city, size: 150),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    const ThreeDGameIcon(
                      type: ThreeDIconType.city,
                      size: 62,
                      animate: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'رحلة المدن العالمية' : 'Global City Journey',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            isArabic
                                ? '${store.completedLevels} مدينة مكتملة من ${ProgressStore.totalLevels}'
                                : '${store.completedLevels} of ${ProgressStore.totalLevels} cities completed',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ThreeDGameIcon(type: ThreeDIconType.star, size: 38),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${store.totalStars}/${store.maximumStars}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
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
    final stars = levels.fold<int>(0, (sum, level) => sum + store.starsForLevel(level.number));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
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
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: unlocked
                      ? const ThreeDGameIcon(type: ThreeDIconType.city, size: 54)
                      : const Icon(Icons.lock_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isArabic ? 'العالم' : 'World'} ${world.number}: ${world.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        unlocked
                            ? '$completed/25 ${isArabic ? 'مدينة' : 'cities'} • $stars/75'
                            : (isArabic ? 'أكمل العالم السابق لفتحه' : 'Complete the previous world to unlock'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                unlocked
                    ? const ThreeDGameIcon(type: ThreeDIconType.star, size: 34)
                    : const Icon(Icons.lock_rounded, color: Colors.white),
              ],
            ),
          ),
          if (unlocked)
            Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 720
                      ? 6
                      : width >= 520
                          ? 5
                          : width >= 380
                              ? 4
                              : 3;
                  final extent = width < 340 ? 118.0 : 124.0;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: levels.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: extent,
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
                                    builder: (_) => CityBriefingScreen(level: level, store: store),
                                  ),
                                );
                              }
                            : null,
                      );
                    },
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
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: unlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, accent.withValues(alpha: .10)],
                  )
                : const LinearGradient(colors: [Color(0xFFE6E8EC), Color(0xFFD6D9DE)]),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: unlocked ? accent : Colors.black12,
              width: boss ? 2.5 : 1.5,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: .18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 92,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (unlocked)
                      ThreeDGameIcon(
                        type: boss ? ThreeDIconType.boss : ThreeDIconType.city,
                        size: boss ? 50 : 46,
                        animate: boss,
                        semanticLabel: level.cityName,
                      )
                    else
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      level.cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: unlocked ? AppTheme.navy : Colors.black38,
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${isArabic ? 'مرحلة' : 'Level'} ${level.number}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.muted, fontSize: 8.5, height: 1),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: index < stars
                              ? const ThreeDGameIcon(type: ThreeDIconType.star, size: 13)
                              : Icon(Icons.star_outline_rounded, size: 12, color: Colors.black.withValues(alpha: .12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
