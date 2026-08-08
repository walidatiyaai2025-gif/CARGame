import 'package:flutter/material.dart';

import '../../core/navigation/game_navigator.dart';
import '../../core/navigation/game_route_names.dart';
import '../../core/settings/app_settings_store.dart';
import '../../core/storage/progress_store.dart';
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
    final previousStars = store.starsForLevel(level.number);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: skin.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              final horizontal = compact ? 12.0 : 18.0;
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 6, horizontal, 0),
                    child: Row(
                      children: [
                        _GlassBackButton(
                          enabled: !_starting,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        _WalletChip(
                          type: ThreeDIconType.heart,
                          value: '${store.hearts}',
                          semanticLabel: isArabic ? 'القلوب' : 'Hearts',
                        ),
                        const SizedBox(width: 8),
                        _WalletChip(
                          type: ThreeDIconType.coin,
                          value: '${store.coins}',
                          semanticLabel: isArabic ? 'العملات' : 'Coins',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GameFitView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        8,
                        horizontal,
                        10,
                      ),
                      child: SizedBox(
                        width: constraints.maxWidth - (horizontal * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroCard(
                              level: level,
                              worldName: world.name,
                              previousStars: previousStars,
                              isArabic: isArabic,
                              compact: compact,
                              skin: skin,
                            ),
                            const SizedBox(height: 10),
                            _MissionCard(
                              isArabic: isArabic,
                              level: level,
                              accent: skin.primary,
                              selectedCount:
                                  (_hint ? 1 : 0) +
                                  (_moves ? 1 : 0) +
                                  (_shield ? 1 : 0),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isArabic
                                  ? 'اختر تجهيزات المهمة'
                                  : 'Choose Mission Loadout',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isArabic
                                  ? 'يتم استهلاك الأدوات فقط عند بدء المهمة.'
                                  : 'Boosters are consumed only when the mission starts.',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, loadoutConstraints) {
                                final columns =
                                    loadoutConstraints.maxWidth < 360 ? 1 : 3;
                                final gap = 10.0;
                                final width = columns == 1
                                    ? loadoutConstraints.maxWidth
                                    : (loadoutConstraints.maxWidth - gap * 2) /
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
                            const SizedBox(height: 12),
                            _StartMissionButton(
                              enabled: store.hearts > 0 && !_starting,
                              loading: _starting,
                              skinColor: skin.primary,
                              isArabic: isArabic,
                              cityName: level.cityName,
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
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .88),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: enabled ? onTap : null,
      icon: const Icon(Icons.arrow_back_rounded),
    ),
  );
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({
    required this.type,
    required this.value,
    required this.semanticLabel,
  });

  final ThreeDIconType type;
  final String value;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x19000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThreeDGameIcon(type: type, size: 27, semanticLabel: semanticLabel),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
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
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 18 : 22),
    decoration: BoxDecoration(
      gradient: skin.heroGradient,
      borderRadius: BorderRadius.circular(34),
      boxShadow: [
        BoxShadow(
          color: skin.primary.withValues(alpha: .32),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  level.isBossCity
                      ? (isArabic ? 'مدينة الزعيم' : 'BOSS CITY')
                      : (isArabic ? 'المهمة التالية' : 'NEXT MISSION'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                level.cityName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 28 : 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '$worldName • ${isArabic ? 'المرحلة' : 'Level'} ${level.number}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 5),
                    child: Opacity(
                      opacity: index < previousStars ? 1 : .25,
                      child: ThreeDGameIcon(
                        type: ThreeDIconType.star,
                        size: compact ? 27 : 31,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ThreeDGameIcon(
          type: level.isBossCity ? ThreeDIconType.boss : ThreeDIconType.city,
          size: compact ? 94 : 118,
          animate: true,
          semanticLabel: level.cityName,
        ),
      ],
    ),
  );
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
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
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: accent.withValues(alpha: .18)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          level.isBossCity
              ? (isArabic ? 'تفاصيل مهمة الزعيم' : 'Boss Mission Brief')
              : (isArabic ? 'تفاصيل المهمة' : 'Mission Brief'),
          style: TextStyle(
            color: accent,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MissionMetric(
              icon: Icons.inventory_2_rounded,
              value: '${level.items.length}',
              label: isArabic ? 'شحنات' : 'Cargo',
            ),
            _MissionMetric(
              icon: Icons.touch_app_rounded,
              value: '${level.moves}',
              label: isArabic ? 'حركات' : 'Moves',
            ),
            _MissionMetric(
              icon: Icons.speed_rounded,
              value: '${level.difficulty}',
              label: isArabic ? 'صعوبة' : 'Difficulty',
            ),
            _MissionMetric(
              icon: Icons.backpack_rounded,
              value: '$selectedCount',
              label: isArabic ? 'أدوات' : 'Boosters',
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
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FB),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: Colors.black54),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
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
    required this.onTap,
  });

  final ThreeDIconType type;
  final String title;
  final String subtitle;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? .42 : 1,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          constraints: const BoxConstraints(minHeight: 158),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, color.withValues(alpha: .20)],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: .24),
              width: selected ? 2.5 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ThreeDGameIcon(type: type, size: 58, animate: selected),
                  if (selected)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                'x$count',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
    required this.isArabic,
    required this.cityName,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final Color skinColor;
  final bool isArabic;
  final String cityName;
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
    height: 68,
    borderRadius: BorderRadius.circular(24),
    backgroundColor: skinColor,
    disabledColor: skinColor.withValues(alpha: .35),
    shadowColor: skinColor.withValues(alpha: .42),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.play_arrow_rounded, size: 34, color: Colors.white),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                enabled
                    ? (isArabic ? 'ابدأ المهمة' : 'START MISSION')
                    : (isArabic ? 'لا توجد قلوب' : 'NO HEARTS'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                cityName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
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