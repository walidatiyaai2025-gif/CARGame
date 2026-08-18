import 'package:flutter/material.dart';

import '../../core/motion/ambient_motion_background.dart';
import '../../core/navigation/game_navigator.dart';
import '../../core/navigation/game_route_names.dart';
import '../../core/settings/app_settings_store.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../../core/widgets/game_button.dart';
import '../../core/widgets/game_fit_view.dart';
import '../game/city_catalog.dart';
import '../game/game_screen.dart';
import '../game/level_data.dart';
import '../game/mission_loadout.dart';

class CityBriefingScreen extends StatefulWidget {
  const CityBriefingScreen({
    super.key,
    required this.level,
    required this.store,
    required this.settings,
  });

  final LevelData level;
  final ProgressStore store;
  final AppSettingsStore settings;

  @override
  State<CityBriefingScreen> createState() => _CityBriefingScreenState();
}

class _CityBriefingScreenState extends State<CityBriefingScreen> {
  bool _hint = false;
  bool _moves = false;
  bool _shield = false;
  bool _starting = false;

  Future<void> _startMission() async {
    if (_starting || widget.store.hearts <= 0) return;
    setState(() => _starting = true);

    try {
      if (_hint && !await widget.store.useFreeHint()) {
        throw StateError('Smart Hint is no longer available.');
      }
      if (_moves && !await widget.store.useExtraMoves()) {
        throw StateError('Extra Moves is no longer available.');
      }
      if (_shield && !await widget.store.useComboShield()) {
        throw StateError('Combo Shield is no longer available.');
      }

      if (!mounted) return;
      await GameNavigator.replaceNamed<void, void>(
        context,
        name: GameRouteNames.game(widget.level.number),
        builder: (_) => GameScreen(
          level: widget.level,
          store: widget.store,
          hapticsEnabled: widget.settings.vibrationEnabled,
          soundEnabled: widget.settings.soundEnabled,
          loadout: MissionLoadout(
            smartHint: _hint,
            extraMoves: _moves,
            comboShield: _shield,
          ),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final store = widget.store;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final skin = gameSkinById(store.selectedTheme);
    final world = gameWorlds[level.world - 1];
    final route = capitalRouteForWorld(level.world);
    final previousStars = store.starsForLevel(level.number);
    final selectedCount =
        (_hint ? 1 : 0) + (_moves ? 1 : 0) + (_shield ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          Positioned.fill(
            child: AmbientMotionBackground(
              startColor: world.startColor,
              endColor: world.endColor,
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
                      Colors.white.withValues(alpha: .22),
                      const Color(0xFFF4F7FB).withValues(alpha: .64),
                      const Color(0xFFF4F7FB).withValues(alpha: .94),
                    ],
                    stops: const [0, .42, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 390;
                final horizontal = compact ? 12.0 : 18.0;
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        7,
                        horizontal,
                        0,
                      ),
                      child: _MissionCommandBar(
                        enabled: !_starting,
                        hearts: store.hearts,
                        coins: store.coins,
                        worldNumber: level.world,
                        isArabic: isArabic,
                        compact: compact,
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                    Expanded(
                      child: GameFitView(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          9,
                          horizontal,
                          10,
                        ),
                        child: SizedBox(
                          width: constraints.maxWidth - (horizontal * 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DeploymentHero(
                                level: level,
                                worldName: route.name(isArabic),
                                previousStars: previousStars,
                                isArabic: isArabic,
                                compact: compact,
                                skin: skin,
                              ),
                              const SizedBox(height: 10),
                              _MissionTelemetry(
                                isArabic: isArabic,
                                level: level,
                                accent: skin.primary,
                                selectedCount: selectedCount,
                              ),
                              const SizedBox(height: 11),
                              _LoadoutHeader(
                                isArabic: isArabic,
                                selectedCount: selectedCount,
                                accent: skin.primary,
                              ),
                              const SizedBox(height: 9),
                              LayoutBuilder(
                                builder: (context, loadoutConstraints) {
                                  final useSingleColumn =
                                      loadoutConstraints.maxWidth < 300;
                                  final columns = useSingleColumn ? 1 : 3;
                                  final gap = compact ? 7.0 : 10.0;
                                  final width = columns == 1
                                      ? loadoutConstraints.maxWidth
                                      : (loadoutConstraints.maxWidth -
                                                gap * 2) /
                                            3;

                                  return Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: [
                                      SizedBox(
                                        width: width,
                                        child: _SelectableBoosterCard(
                                          type: ThreeDIconType.hint,
                                          title: isArabic
                                              ? 'تلميح ذكي'
                                              : 'Smart Hint',
                                          subtitle: isArabic
                                              ? 'تلميح مجاني داخل الجولة'
                                              : 'One free in-game hint',
                                          count: store.freeHints,
                                          selected: _hint,
                                          color: const Color(0xFFFFB300),
                                          compact: compact,
                                          onTap: store.freeHints <= 0
                                              ? null
                                              : () => setState(
                                                  () => _hint = !_hint,
                                                ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: width,
                                        child: _SelectableBoosterCard(
                                          type: ThreeDIconType.extraMoves,
                                          title: isArabic
                                              ? 'حركات إضافية'
                                              : 'Extra Moves',
                                          subtitle: isArabic
                                              ? '+5 حركات عند البداية'
                                              : '+5 starting moves',
                                          count: store.extraMovesBoosters,
                                          selected: _moves,
                                          color: const Color(0xFF2D6CDF),
                                          compact: compact,
                                          onTap: store.extraMovesBoosters <= 0
                                              ? null
                                              : () => setState(
                                                  () => _moves = !_moves,
                                                ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: width,
                                        child: _SelectableBoosterCard(
                                          type: ThreeDIconType.shield,
                                          title: isArabic
                                              ? 'درع الكومبو'
                                              : 'Combo Shield',
                                          subtitle: isArabic
                                              ? 'يحمي أول خطأ'
                                              : 'Protects first mistake',
                                          count: store.comboShields,
                                          selected: _shield,
                                          color: const Color(0xFF7B3FF2),
                                          compact: compact,
                                          onTap: store.comboShields <= 0
                                              ? null
                                              : () => setState(
                                                  () => _shield = !_shield,
                                                ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 11),
                              _StartMissionButton(
                                enabled: store.hearts > 0 && !_starting,
                                loading: _starting,
                                skinColor: skin.primary,
                                accentColor: skin.accent,
                                isArabic: isArabic,
                                cityName: level.cityName,
                                levelNumber: level.number,
                                selectedCount: selectedCount,
                                onPressed: _startMission,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCommandBar extends StatelessWidget {
  const _MissionCommandBar({
    required this.enabled,
    required this.hearts,
    required this.coins,
    required this.worldNumber,
    required this.isArabic,
    required this.compact,
    required this.onBack,
  });

  final bool enabled;
  final int hearts;
  final int coins;
  final int worldNumber;
  final bool isArabic;
  final bool compact;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _GlassBackButton(enabled: enabled, onTap: onBack),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'مركز تجهيز المهمة' : 'MISSION CONTROL',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.navy,
                fontSize: compact ? 15 : 18,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
            Text(
              '${isArabic ? 'المسار' : 'ROUTE'} $worldNumber',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),
      _WalletChip(
        type: ThreeDIconType.heart,
        value: '$hearts',
        semanticLabel: isArabic ? 'القلوب' : 'Hearts',
        compact: compact,
      ),
      const SizedBox(width: 6),
      _WalletChip(
        type: ThreeDIconType.coin,
        value: '$coins',
        semanticLabel: isArabic ? 'العملات' : 'Coins',
        compact: compact,
      ),
    ],
  );
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .94),
    shape: const CircleBorder(),
    elevation: 2,
    shadowColor: Colors.black12,
    child: IconButton(
      onPressed: enabled ? onTap : null,
      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.navy),
    ),
  );
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({
    required this.type,
    required this.value,
    required this.semanticLabel,
    required this.compact,
  });

  final ThreeDIconType type;
  final String value;
  final String semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 7 : 10,
      vertical: compact ? 6 : 7,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white),
      boxShadow: const [
        BoxShadow(
          color: Color(0x160B1120),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThreeDGameIcon(
          type: type,
          size: compact ? 22 : 26,
          semanticLabel: semanticLabel,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.navy,
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _DeploymentHero extends StatelessWidget {
  const _DeploymentHero({
    required this.level,
    required this.worldName,
    required this.previousStars,
    required this.isArabic,
    required this.compact,
    required this.skin,
  });

  final LevelData level;
  final String worldName;
  final int previousStars;
  final bool isArabic;
  final bool compact;
  final GameSkin skin;

  @override
  Widget build(BuildContext context) {
    final boss = level.isBossCity;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B1120),
            Color.lerp(const Color(0xFF0B1120), skin.primary, .52)!,
            Color.lerp(skin.primary, skin.secondary, .52)!,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 28 : 34),
        border: Border.all(color: Colors.white.withValues(alpha: .52)),
        boxShadow: [
          BoxShadow(
            color: skin.primary.withValues(alpha: .26),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: compact ? -24 : -14,
            top: compact ? -28 : -34,
            child: Opacity(
              opacity: .12,
              child: ThreeDGameIcon(
                type: boss ? ThreeDIconType.boss : ThreeDIconType.city,
                size: compact ? 170 : 215,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 15 : 19),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
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
                                boss
                                    ? (isArabic ? 'مركز رئيسي' : 'HUB CITY')
                                    : (isArabic
                                          ? 'توجيه قبل الانطلاق'
                                          : 'DEPLOYMENT BRIEF'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '#${level.number}',
                                style: TextStyle(
                                  color: skin.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        level.localizedCityName(isArabic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 27 : 34,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${level.localizedCountryName(isArabic)} • $worldName • ${isArabic ? 'المرحلة' : 'Level'} ${level.number}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var index = 0; index < 3; index++)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
                              child: Opacity(
                                opacity: index < previousStars ? 1 : .24,
                                child: ThreeDGameIcon(
                                  type: ThreeDIconType.star,
                                  size: compact ? 25 : 29,
                                ),
                              ),
                            ),
                          const SizedBox(width: 5),
                          Text(
                            previousStars == 0
                                ? (isArabic ? 'أفضل نتيجة —' : 'BEST —')
                                : '${isArabic ? 'أفضل نتيجة' : 'BEST'} $previousStars/3',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: compact ? 78 : 102,
                  height: compact ? 92 : 112,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: ThreeDGameIcon(
                    type: boss ? ThreeDIconType.boss : ThreeDIconType.city,
                    size: compact ? 72 : 94,
                    animate: true,
                    semanticLabel: level.localizedDestinationLabel(isArabic),
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

class _MissionTelemetry extends StatelessWidget {
  const _MissionTelemetry({
    required this.isArabic,
    required this.level,
    required this.accent,
    required this.selectedCount,
  });

  final bool isArabic;
  final LevelData level;
  final Color accent;
  final int selectedCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: accent.withValues(alpha: .16)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x100B1120),
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.radar_rounded, color: accent, size: 19),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.isBossCity
                        ? (isArabic
                              ? 'تفاصيل مهمة الزعيم'
                              : 'Boss Mission Brief')
                        : (isArabic ? 'تفاصيل المهمة' : 'Mission Brief'),
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    isArabic
                        ? 'بيانات التشغيل قبل بدء الجولة'
                        : 'Pre-deployment operating data',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MissionMetric(
                icon: Icons.inventory_2_rounded,
                value: '${level.items.length}',
                label: isArabic ? 'شحنات' : 'Cargo',
                accent: accent,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _MissionMetric(
                icon: Icons.touch_app_rounded,
                value: '${level.moves}',
                label: isArabic ? 'حركات' : 'Moves',
                accent: accent,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _MissionMetric(
                icon: Icons.speed_rounded,
                value: '${level.difficulty}',
                label: isArabic ? 'صعوبة' : 'Difficulty',
                accent: accent,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _MissionMetric(
                icon: Icons.backpack_rounded,
                value: '$selectedCount',
                label: isArabic ? 'أدوات' : 'Boosters',
                accent: accent,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MissionMetric extends StatelessWidget {
  const _MissionMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FB),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: accent.withValues(alpha: .08)),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LoadoutHeader extends StatelessWidget {
  const _LoadoutHeader({
    required this.isArabic,
    required this.selectedCount,
    required this.accent,
  });

  final bool isArabic;
  final int selectedCount;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'اختر تجهيزات المهمة' : 'Choose Mission Loadout',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              isArabic
                  ? 'يتم استهلاك الأدوات فقط عند بدء المهمة.'
                  : 'Boosters are consumed only when the mission starts.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: .16)),
        ),
        child: Text(
          '$selectedCount/3',
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _SelectableBoosterCard extends StatelessWidget {
  const _SelectableBoosterCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.selected,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  final ThreeDIconType type;
  final String title;
  final String subtitle;
  final int count;
  final bool selected;
  final Color color;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? .42 : 1,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          constraints: BoxConstraints(minHeight: compact ? 126 : 146),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 9,
            vertical: compact ? 9 : 12,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, color.withValues(alpha: .18)],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFF9FBFE)],
                  ),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: .20),
              width: selected ? 2.2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .20),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0F0B1120),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                end: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'x$count',
                    style: TextStyle(
                      color: color,
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
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: compact ? 46 : 54,
                              height: compact ? 46 : 54,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .08),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: ThreeDGameIcon(
                                type: type,
                                size: compact ? 43 : 51,
                                animate: selected,
                              ),
                            ),
                            if (selected)
                              PositionedDirectional(
                                end: -3,
                                top: -3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontSize: 10,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 8,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
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
    ),
  );
}

class _StartMissionButton extends StatelessWidget {
  const _StartMissionButton({
    required this.enabled,
    required this.loading,
    required this.skinColor,
    required this.accentColor,
    required this.isArabic,
    required this.cityName,
    required this.levelNumber,
    required this.selectedCount,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final Color skinColor;
  final Color accentColor;
  final bool isArabic;
  final String cityName;
  final int levelNumber;
  final int selectedCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GameButton(
    semanticLabel: enabled
        ? (isArabic ? 'ابدأ مهمة $cityName' : 'Start mission $cityName')
        : (isArabic ? 'لا توجد قلوب' : 'No hearts'),
    onPressed: enabled ? onPressed : null,
    enabled: enabled,
    loading: loading,
    expand: true,
    height: 70,
    borderRadius: BorderRadius.circular(24),
    gradient: LinearGradient(
      colors: enabled
          ? [skinColor, Color.lerp(skinColor, const Color(0xFF0B1120), .24)!]
          : const [Color(0xFFB8BEC7), Color(0xFF8C939D)],
    ),
    shadowColor: skinColor.withValues(alpha: .38),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enabled
                    ? (isArabic ? 'ابدأ المهمة' : 'START MISSION')
                    : (isArabic ? 'لا توجد قلوب' : 'NO HEARTS'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
              Text(
                '$cityName • #$levelNumber',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.backpack_rounded, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                '$selectedCount/3',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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
