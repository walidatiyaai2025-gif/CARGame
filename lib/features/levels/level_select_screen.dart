import 'package:flutter/material.dart';

import '../../core/motion/ambient_motion_background.dart';
import '../../core/navigation/game_navigator.dart';
import '../../core/settings/app_settings_store.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../game/city_catalog.dart';
import '../game/level_data.dart';
import 'city_briefing_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({
    super.key,
    required this.store,
    required this.settings,
  });

  final ProgressStore store;
  final AppSettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final skin = gameSkinById(store.selectedTheme);
        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          appBar: AppBar(
            title: Text(isArabic ? 'خريطة العالم' : 'World Map'),
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.white.withValues(alpha: .92),
            foregroundColor: AppTheme.navy,
            titleTextStyle: const TextStyle(
              color: AppTheme.navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: AmbientMotionBackground(
                  startColor: skin.primary,
                  endColor: skin.secondary,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: .18),
                          const Color(0xFFF4F7FB).withValues(alpha: .58),
                          const Color(0xFFF4F7FB).withValues(alpha: .92),
                        ],
                        stops: const [0, .40, 1],
                      ),
                    ),
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 34),
                children: [
                  _GlobalHeader(isArabic: isArabic, store: store, skin: skin),
                  const SizedBox(height: 16),
                  for (final world in gameWorlds) ...[
                    _WorldSection(
                      world: world,
                      levels: levels
                          .where((level) => level.world == world.number)
                          .toList(),
                      store: store,
                      settings: settings,
                      isArabic: isArabic,
                      skin: skin,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ],
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
  Widget build(BuildContext context) {
    final currentWorld = ((store.highestUnlockedLevel - 1) ~/ 25 + 1).clamp(
      1,
      gameWorlds.length,
    );
    final nextLevel = store.highestUnlockedLevel.clamp(
      1,
      ProgressStore.totalLevels,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B1120),
            Color.lerp(const Color(0xFF0B1120), skin.primary, .46)!,
            Color.lerp(skin.primary, skin.secondary, .52)!,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: skin.primary.withValues(alpha: .25),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -42,
            top: -30,
            child: Opacity(
              opacity: .12,
              child: const ThreeDGameIcon(
                type: ThreeDIconType.city,
                size: 210,
              ),
            ),
          ),
          PositionedDirectional(
            start: -28,
            bottom: -52,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF59F0A8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            isArabic ? 'شبكة المسارات' : 'ROUTE NETWORK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _HeaderBadge(
                      icon: Icons.public_rounded,
                      label: '${isArabic ? 'العالم' : 'WORLD'} $currentWorld',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const ThreeDGameIcon(
                        type: ThreeDIconType.city,
                        size: 58,
                        animate: true,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'رحلة المدن العالمية'
                                : 'Global City Journey',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isArabic
                                ? 'جهّز المسار التالي ووسّع شبكة الشحن العالمية'
                                : 'Clear the next route and expand your cargo network',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _NetworkStat(
                        value: '${store.completedLevels}',
                        label: isArabic ? 'مكتملة' : 'CLEARED',
                        icon: Icons.flag_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NetworkStat(
                        value: '${store.totalStars}',
                        label: isArabic ? 'نجمة' : 'STARS',
                        icon: Icons.star_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NetworkStat(
                        value: '$nextLevel',
                        label: isArabic ? 'التالي' : 'NEXT',
                        icon: Icons.route_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isArabic
                            ? '${store.completedLevels}/${ProgressStore.totalLevels} مدينة مكتملة'
                            : '${store.completedLevels}/${ProgressStore.totalLevels} cities completed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${(store.completionProgress * 100).round()}%',
                      style: TextStyle(
                        color: skin.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: store.completionProgress,
                    minHeight: 9,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(skin.accent),
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

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _NetworkStat extends StatelessWidget {
  const _NetworkStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white70, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
              ],
            ),
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
    required this.settings,
    required this.isArabic,
    required this.skin,
  });

  final GameWorld world;
  final List<LevelData> levels;
  final ProgressStore store;
  final AppSettingsStore settings;
  final bool isArabic;
  final GameSkin skin;

  static const String _briefingRoutePrefix = '/briefing/level/';

  @override
  Widget build(BuildContext context) {
    final unlocked = store.highestUnlockedLevel >= levels.first.number;
    final completed = levels
        .where((level) => level.number < store.highestUnlockedLevel)
        .length;
    final stars = levels.fold<int>(
      0,
      (sum, level) => sum + store.starsForLevel(level.number),
    );
    final progress = (completed / levels.length).clamp(0.0, 1.0);
    final worldComplete = completed >= levels.length;
    final startLevel = levels.first.number;
    final endLevel = levels.last.number;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .82)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C0B1120),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(world.startColor, skin.primary, .16)!,
                  Color.lerp(world.endColor, skin.secondary, .16)!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: unlocked
                          ? const ThreeDGameIcon(
                              type: ThreeDIconType.city,
                              size: 43,
                            )
                          : const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 25,
                            ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${isArabic ? 'العالم' : 'WORLD'} ${world.number}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              if (unlocked)
                                _WorldStatusBadge(
                                  label: worldComplete
                                      ? (isArabic ? 'مكتمل' : 'CLEARED')
                                      : (isArabic ? 'نشط' : 'ACTIVE'),
                                  complete: worldComplete,
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            world.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _WorldIndex(number: world.number, unlocked: unlocked),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _WorldMeta(
                        icon: Icons.route_rounded,
                        label: '$startLevel–$endLevel',
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _WorldMeta(
                        icon: Icons.flag_rounded,
                        label: unlocked ? '$completed/25' : '--/25',
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _WorldMeta(
                        icon: Icons.star_rounded,
                        label: unlocked ? '$stars/75' : '--/75',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: unlocked ? progress : 0,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      worldComplete ? const Color(0xFF59F0A8) : skin.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF9FBFE), Color(0xFFF1F5FA)],
                ),
              ),
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
                  final extent = width < 340 ? 120.0 : 126.0;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: levels.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      mainAxisExtent: extent,
                    ),
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final cityUnlocked =
                          level.number <= store.highestUnlockedLevel;
                      return _CityCard(
                        level: level,
                        unlocked: cityUnlocked,
                        current: level.number == store.highestUnlockedLevel,
                        stars: store.starsForLevel(level.number),
                        world: world,
                        skin: skin,
                        isArabic: isArabic,
                        onTap: cityUnlocked
                            ? () {
                                GameNavigator.push<void>(
                                  context,
                                  name: '$_briefingRoutePrefix${level.number}',
                                  guardKey: 'briefing:${level.number}',
                                  builder: (_) => CityBriefingScreen(
                                    level: level,
                                    store: store,
                                    settings: settings,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9EDF3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: AppTheme.muted,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'أكمل العالم السابق لفتح شبكة المدن التالية'
                          : 'Complete the previous world to unlock this route network',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                      ),
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

class _WorldStatusBadge extends StatelessWidget {
  const _WorldStatusBadge({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: complete
          ? const Color(0xFF59F0A8).withValues(alpha: .20)
          : Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: complete ? const Color(0x6659F0A8) : Colors.white24,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: complete ? const Color(0xFFB8FFD8) : Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: .5,
      ),
    ),
  );
}

class _WorldIndex extends StatelessWidget {
  const _WorldIndex({required this.number, required this.unlocked});

  final int number;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: unlocked ? .16 : .10),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white24),
    ),
    child: Text(
      number.toString().padLeft(2, '0'),
      style: TextStyle(
        color: unlocked ? Colors.white : Colors.white54,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: .4,
      ),
    ),
  );
}

class _WorldMeta extends StatelessWidget {
  const _WorldMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 5),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.level,
    required this.unlocked,
    required this.current,
    required this.stars,
    required this.world,
    required this.skin,
    required this.isArabic,
    required this.onTap,
  });

  final LevelData level;
  final bool unlocked;
  final bool current;
  final int stars;
  final GameWorld world;
  final GameSkin skin;
  final bool isArabic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final boss = level.isBossCity;
    final accent = boss
        ? AppTheme.orange
        : Color.lerp(world.startColor, skin.primary, .20)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: unlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      accent.withValues(alpha: boss ? .16 : .07),
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFE7EAF0), Color(0xFFDDE1E7)],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unlocked
                  ? accent.withValues(alpha: current ? .95 : .72)
                  : Colors.black12,
              width: current ? 2.4 : (boss ? 2.2 : 1.2),
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: .15),
                      blurRadius: 11,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                end: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: unlocked
                        ? accent.withValues(alpha: .12)
                        : Colors.black.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    current
                        ? (isArabic ? 'التالي' : 'NEXT')
                        : '#${level.number}',
                    style: TextStyle(
                      color: unlocked ? accent : Colors.black38,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 94,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (unlocked)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: .10),
                              border: Border.all(
                                color: accent.withValues(alpha: .24),
                              ),
                            ),
                            child: ThreeDGameIcon(
                              type: boss
                                  ? ThreeDIconType.boss
                                  : ThreeDIconType.city,
                              size: boss ? 47 : 43,
                              animate: boss,
                              semanticLabel: level.cityName,
                            ),
                          )
                        else
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .13),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white54),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        const SizedBox(height: 6),
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
                          boss
                              ? (isArabic ? 'مركز رئيسي' : 'HUB CITY')
                              : '${isArabic ? 'مرحلة' : 'Level'} ${level.number}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: boss && unlocked ? accent : AppTheme.muted,
                            fontSize: 8,
                            height: 1,
                            fontWeight: boss ? FontWeight.w900 : FontWeight.w600,
                            letterSpacing: boss ? .3 : 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: index < stars
                                  ? const ThreeDGameIcon(
                                      type: ThreeDIconType.star,
                                      size: 13,
                                    )
                                  : Icon(
                                      Icons.star_outline_rounded,
                                      size: 12,
                                      color: Colors.black.withValues(alpha: .12),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
