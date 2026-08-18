import 'package:flutter/material.dart';

import '../../core/motion/ambient_motion_background.dart';
import '../../core/navigation/game_navigator.dart';
import '../../core/settings/app_settings_store.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../../core/widgets/game_button.dart';
import '../game/city_catalog.dart';
import '../game/level_data.dart';
import 'capital_world_map.dart';
import 'city_briefing_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({
    super.key,
    required this.store,
    required this.settings,
  });

  final ProgressStore store;
  final AppSettingsStore settings;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const String _briefingRoutePrefix = '/briefing/level/';

  late int _chapter;
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _chapter = _worldForLevel(widget.store.highestUnlockedLevel);
    _selectedLevel = widget.store.highestUnlockedLevel.clamp(
      1,
      ProgressStore.totalLevels,
    );
  }

  int _worldForLevel(int levelNumber) {
    return (((levelNumber.clamp(1, ProgressStore.totalLevels) - 1) ~/ 25) + 1)
        .clamp(1, 6);
  }

  List<LevelData> _levelsForChapter(int chapter) {
    return levels.where((level) => level.world == chapter).toList();
  }

  void _selectChapter(int chapter) {
    final nextChapter = chapter.clamp(1, 6);
    final chapterLevels = _levelsForChapter(nextChapter);
    final highest = widget.store.highestUnlockedLevel;
    final candidate = chapterLevels
        .where((level) => level.number <= highest)
        .fold<LevelData?>(
          null,
          (latest, level) =>
              level.number > (latest?.number ?? 0) ? level : latest,
        );

    setState(() {
      _chapter = nextChapter;
      _selectedLevel = (candidate ?? chapterLevels.first).number;
    });
  }

  void _selectLevel(LevelData level) {
    setState(() => _selectedLevel = level.number);
  }

  Future<void> _openBriefing(LevelData level) async {
    if (level.number > widget.store.highestUnlockedLevel) return;
    await GameNavigator.push<void>(
      context,
      name: '$_briefingRoutePrefix${level.number}',
      guardKey: 'briefing:${level.number}',
      builder: (_) => CityBriefingScreen(
        level: level,
        store: widget.store,
        settings: widget.settings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final skin = gameSkinById(widget.store.selectedTheme);
        final chapterLevels = _levelsForChapter(_chapter);
        final selected = chapterLevels.firstWhere(
          (level) => level.number == _selectedLevel,
          orElse: () => chapterLevels.first,
        );
        final route = capitalRouteForWorld(_chapter);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          appBar: AppBar(
            title: Text(isArabic ? 'خريطة العالم' : 'World Map'),
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.white.withValues(alpha: .94),
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
                          Colors.white.withValues(alpha: .10),
                          const Color(0xFFF4F7FB).withValues(alpha: .52),
                          const Color(0xFFF4F7FB).withValues(alpha: .94),
                        ],
                        stops: const [0, .45, 1],
                      ),
                    ),
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 34),
                children: [
                  _CapitalChallengeHeader(
                    isArabic: isArabic,
                    store: widget.store,
                    skin: skin,
                    route: route,
                    chapter: _chapter,
                  ),
                  const SizedBox(height: 14),
                  CapitalWorldMap(
                    levels: chapterLevels,
                    highestUnlockedLevel: widget.store.highestUnlockedLevel,
                    selectedLevel: selected.number,
                    starsForLevel: widget.store.starsForLevel,
                    isArabic: isArabic,
                    accent: skin.accent,
                    onSelect: _selectLevel,
                  ),
                  const SizedBox(height: 12),
                  _ChapterNavigator(
                    chapter: _chapter,
                    isArabic: isArabic,
                    route: route,
                    onPrevious: _chapter > 1
                        ? () => _selectChapter(_chapter - 1)
                        : null,
                    onNext: _chapter < 6
                        ? () => _selectChapter(_chapter + 1)
                        : null,
                    onChapter: _selectChapter,
                  ),
                  const SizedBox(height: 12),
                  _SelectedCapitalCard(
                    level: selected,
                    unlocked:
                        selected.number <= widget.store.highestUnlockedLevel,
                    current:
                        selected.number == widget.store.highestUnlockedLevel,
                    stars: widget.store.starsForLevel(selected.number),
                    isArabic: isArabic,
                    skin: skin,
                    onStart: () => _openBriefing(selected),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CapitalChallengeHeader extends StatelessWidget {
  const _CapitalChallengeHeader({
    required this.isArabic,
    required this.store,
    required this.skin,
    required this.route,
    required this.chapter,
  });

  final bool isArabic;
  final ProgressStore store;
  final GameSkin skin;
  final CapitalRoute route;
  final int chapter;

  @override
  Widget build(BuildContext context) {
    final nextLevel = store.highestUnlockedLevel.clamp(
      1,
      ProgressStore.totalLevels,
    );
    final nextStage = capitalStageForLevel(nextLevel);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF071928),
            Color.lerp(const Color(0xFF071928), skin.primary, .42)!,
            Color.lerp(skin.primary, skin.secondary, .48)!,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .48)),
        boxShadow: [
          BoxShadow(
            color: skin.primary.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -34,
            top: -34,
            child: Opacity(
              opacity: .12,
              child: const Icon(
                Icons.public_rounded,
                color: Colors.white,
                size: 180,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              isArabic
                                  ? '150 دولة وعاصمة'
                                  : '150 COUNTRIES & CAPITALS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${isArabic ? 'المسار' : 'ROUTE'} $chapter/6',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic ? 'تحدي عواصم العالم' : 'World Capitals Challenge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  route.name(isArabic),
                  style: TextStyle(
                    color: skin.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  route.subtitle(isArabic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderStat(
                        icon: Icons.flag_rounded,
                        value: '${store.completedLevels}',
                        label: isArabic ? 'مكتملة' : 'CLEARED',
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _HeaderStat(
                        icon: Icons.star_rounded,
                        value: '${store.totalStars}',
                        label: isArabic ? 'نجمة' : 'STARS',
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _HeaderStat(
                        icon: Icons.location_on_rounded,
                        value: '$nextLevel',
                        label: nextStage.capital(isArabic),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: store.completionProgress,
                    minHeight: 7,
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

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
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

class _ChapterNavigator extends StatelessWidget {
  const _ChapterNavigator({
    required this.chapter,
    required this.isArabic,
    required this.route,
    required this.onPrevious,
    required this.onNext,
    required this.onChapter,
  });

  final int chapter;
  final bool isArabic;
  final CapitalRoute route;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onChapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180B1120),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _ChapterArrow(
            icon: isArabic
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
            onTap: onPrevious,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  route.name(isArabic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 1; index <= 6; index++)
                      GestureDetector(
                        onTap: () => onChapter(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: index == chapter ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == chapter
                                ? const Color(0xFF2D6CDF)
                                : const Color(0xFFD4DAE3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ChapterArrow(
            icon: isArabic
                ? Icons.arrow_back_ios_new_rounded
                : Icons.arrow_forward_ios_rounded,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _ChapterArrow extends StatelessWidget {
  const _ChapterArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFFF0F2F5) : const Color(0xFFECF4FF),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.black26 : const Color(0xFF2D6CDF),
        ),
      ),
    );
  }
}

class _SelectedCapitalCard extends StatelessWidget {
  const _SelectedCapitalCard({
    required this.level,
    required this.unlocked,
    required this.current,
    required this.stars,
    required this.isArabic,
    required this.skin,
    required this.onStart,
  });

  final LevelData level;
  final bool unlocked;
  final bool current;
  final int stars;
  final bool isArabic;
  final GameSkin skin;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final stage = level.capitalStage;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x200B1120),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      skin.primary.withValues(alpha: .16),
                      skin.accent.withValues(alpha: .18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: skin.primary.withValues(alpha: .16),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_city_rounded,
                      color: AppTheme.navy,
                      size: 27,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stage.countryCode,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stage.capital(isArabic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontSize: 21,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (current)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF22A8E8,
                              ).withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isArabic ? 'الحالية' : 'CURRENT',
                              style: const TextStyle(
                                color: Color(0xFF137FB4),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stage.country(isArabic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      children: [
                        _StageMeta(
                          icon: Icons.flag_rounded,
                          text:
                              '${isArabic ? 'مرحلة' : 'Level'} ${level.number}',
                        ),
                        _StageMeta(
                          icon: Icons.inventory_2_rounded,
                          text:
                              '${level.items.length} ${isArabic ? 'منتج' : 'cargo'}',
                        ),
                        _StageMeta(
                          icon: Icons.house_rounded,
                          text:
                              '${level.houseCount} ${isArabic ? 'بيوت' : 'houses'}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              for (var index = 0; index < 3; index++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 3),
                  child: index < stars
                      ? const ThreeDGameIcon(
                          type: ThreeDIconType.star,
                          size: 20,
                        )
                      : const Icon(
                          Icons.star_outline_rounded,
                          size: 20,
                          color: Color(0xFFD2D7DF),
                        ),
                ),
              const Spacer(),
              Text(
                unlocked
                    ? '${isArabic ? 'الصعوبة' : 'Difficulty'} ${level.difficulty}/10'
                    : (isArabic ? 'مرحلة مقفلة' : 'Locked stage'),
                style: TextStyle(
                  color: unlocked ? AppTheme.muted : const Color(0xFF9A5360),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GameButton(
            semanticLabel: unlocked
                ? (isArabic
                      ? 'ابدأ مرحلة ${stage.capitalAr}'
                      : 'Start ${stage.capitalEn} stage')
                : (isArabic ? 'المرحلة مقفلة' : 'Stage locked'),
            onPressed: unlocked ? onStart : null,
            enabled: unlocked,
            height: 56,
            expand: true,
            gradient: unlocked
                ? LinearGradient(
                    colors: [
                      const Color(0xFF20B45A),
                      Color.lerp(const Color(0xFF20B45A), skin.primary, .24)!,
                    ],
                  )
                : null,
            backgroundColor: unlocked ? null : const Color(0xFFE5E8ED),
            foregroundColor: unlocked ? Colors.white : Colors.black38,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded),
                const SizedBox(width: 7),
                Text(
                  unlocked
                      ? (isArabic ? 'ابدأ اللعب!' : 'START MISSION')
                      : (isArabic ? 'مقفلة' : 'LOCKED'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

class _StageMeta extends StatelessWidget {
  const _StageMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.muted),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
