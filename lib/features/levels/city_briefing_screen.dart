import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/game_skin.dart';
import '../game/city_catalog.dart';
import '../game/game_screen.dart';
import '../game/level_data.dart';
import '../game/mission_loadout.dart';

class CityBriefingScreen extends StatefulWidget {
  const CityBriefingScreen({
    super.key,
    required this.level,
    required this.store,
  });

  final LevelData level;
  final ProgressStore store;

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
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            level: widget.level,
            store: widget.store,
            loadout: MissionLoadout(
              smartHint: _hint,
              extraMoves: _moves,
              comboShield: _shield,
            ),
          ),
        ),
      );
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message.toString())),
        );
      }
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _starting ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Spacer(),
                    _WalletChip(
                      icon: Icons.favorite_rounded,
                      value: '${store.hearts}',
                      color: const Color(0xFFE64A62),
                    ),
                    const SizedBox(width: 8),
                    _WalletChip(
                      icon: Icons.monetization_on_rounded,
                      value: '${store.coins}',
                      color: const Color(0xFFFFA000),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: skin.heroGradient,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: skin.primary.withValues(alpha: .28),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            level.isBossCity
                                ? Icons.workspace_premium_rounded
                                : Icons.location_city_rounded,
                            color: Colors.white,
                            size: 62,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            level.cityName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${world.name} • ${isArabic ? 'المرحلة' : 'Level'} ${level.number}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                              (index) => Icon(
                                index < previousStars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: index < previousStars
                                    ? skin.accent
                                    : Colors.white38,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _MissionCard(
                      isArabic: isArabic,
                      level: level,
                      accent: skin.primary,
                      selectedCount:
                          (_hint ? 1 : 0) + (_moves ? 1 : 0) + (_shield ? 1 : 0),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isArabic ? 'اختر تجهيزات المهمة' : 'Choose Mission Loadout',
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'لن يتم استهلاك أي أداة إلا بعد الضغط على ابدأ المهمة.'
                          : 'Nothing is consumed until you press Start Mission.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SelectableBoosterCard(
                            icon: Icons.lightbulb_rounded,
                            title: isArabic ? 'تلميح ذكي' : 'Smart Hint',
                            subtitle: isArabic ? 'تلميح مجاني داخل الجولة' : 'One free in-game hint',
                            count: store.freeHints,
                            selected: _hint,
                            color: const Color(0xFFFFB300),
                            onTap: store.freeHints <= 0
                                ? null
                                : () => setState(() => _hint = !_hint),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SelectableBoosterCard(
                            icon: Icons.add_circle_rounded,
                            title: isArabic ? 'حركات إضافية' : 'Extra Moves',
                            subtitle: isArabic ? '+5 حركات عند البداية' : '+5 starting moves',
                            count: store.extraMovesBoosters,
                            selected: _moves,
                            color: const Color(0xFF2D6CDF),
                            onTap: store.extraMovesBoosters <= 0
                                ? null
                                : () => setState(() => _moves = !_moves),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SelectableBoosterCard(
                            icon: Icons.shield_rounded,
                            title: isArabic ? 'درع الكومبو' : 'Combo Shield',
                            subtitle: isArabic ? 'يحمي أول خطأ' : 'Protects first mistake',
                            count: store.comboShields,
                            selected: _shield,
                            color: const Color(0xFF7B3FF2),
                            onTap: store.comboShields <= 0
                                ? null
                                : () => setState(() => _shield = !_shield),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 58,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: skin.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: store.hearts <= 0 || _starting ? null : _startMission,
                        icon: _starting
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.play_arrow_rounded, size: 30),
                        label: Text(
                          store.hearts <= 0
                              ? (isArabic ? 'لا توجد قلوب' : 'No hearts available')
                              : (isArabic ? 'ابدأ المهمة' : 'Start Mission'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
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
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accent.withValues(alpha: .18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              level.isBossCity
                  ? (isArabic ? 'مهمة مدينة الزعيم' : 'Boss City Mission')
                  : (isArabic ? 'تفاصيل المهمة' : 'Mission Brief'),
              style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _BriefRow(
              icon: Icons.inventory_2_rounded,
              text: isArabic
                  ? 'رتّب ${level.items.length} شحنة'
                  : 'Sort ${level.items.length} cargo items',
            ),
            _BriefRow(
              icon: Icons.touch_app_rounded,
              text: isArabic
                  ? '${level.moves} حركة أساسية'
                  : '${level.moves} base moves',
            ),
            _BriefRow(
              icon: Icons.speed_rounded,
              text: isArabic
                  ? 'درجة الصعوبة ${level.difficulty}'
                  : 'Difficulty ${level.difficulty}',
            ),
            _BriefRow(
              icon: Icons.backpack_rounded,
              text: isArabic
                  ? '$selectedCount أداة مختارة'
                  : '$selectedCount boosters selected',
            ),
          ],
        ),
      );
}

class _BriefRow extends StatelessWidget {
  const _BriefRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 21, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class _SelectableBoosterCard extends StatelessWidget {
  const _SelectableBoosterCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null ? .45 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: .14) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: selected ? color : color.withValues(alpha: .22), width: selected ? 2.5 : 1),
              ),
              child: Column(
                children: [
                  Icon(selected ? Icons.check_circle_rounded : icon, color: color, size: 34),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8, color: Colors.black54),
                  ),
                  const SizedBox(height: 5),
                  Text('x$count', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ),
      );
}
