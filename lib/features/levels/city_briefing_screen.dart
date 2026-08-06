import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/game_skin.dart';
import '../game/city_catalog.dart';
import '../game/game_screen.dart';
import '../game/level_data.dart';

class CityBriefingScreen extends StatelessWidget {
  const CityBriefingScreen({
    super.key,
    required this.level,
    required this.store,
  });

  final LevelData level;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () => Navigator.pop(context),
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
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .16),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 2),
                            ),
                            child: Icon(
                              level.isBossCity
                                  ? Icons.workspace_premium_rounded
                                  : Icons.location_city_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 12),
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
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isArabic ? 'تجهيزاتك' : 'Your Loadout',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _BoosterCard(
                            icon: Icons.lightbulb_rounded,
                            title: isArabic ? 'تلميح ذكي' : 'Smart Hint',
                            count: store.freeHints,
                            color: const Color(0xFFFFB300),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BoosterCard(
                            icon: Icons.add_circle_rounded,
                            title: isArabic ? 'حركات إضافية' : 'Extra Moves',
                            count: store.extraMovesBoosters,
                            color: const Color(0xFF2D6CDF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BoosterCard(
                            icon: Icons.shield_rounded,
                            title: isArabic ? 'درع الكومبو' : 'Combo Shield',
                            count: store.comboShields,
                            color: const Color(0xFF7B3FF2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isArabic
                          ? 'يمكن تفعيل هذه الأدوات داخل المدينة عند الحاجة.'
                          : 'Boosters can be activated inside the city when needed.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
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
                        onPressed: store.hearts <= 0
                            ? null
                            : () async {
                                await Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) => GameScreen(
                                      level: level,
                                      store: store,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.play_arrow_rounded, size: 30),
                        label: Text(
                          store.hearts <= 0
                              ? (isArabic ? 'لا توجد قلوب' : 'No hearts available')
                              : (isArabic ? 'ابدأ المهمة' : 'Start Mission'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
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
  const _WalletChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 12),
          ],
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
  });

  final bool isArabic;
  final LevelData level;
  final Color accent;

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
              style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
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
                  ? '${level.moves} حركة متاحة'
                  : '${level.moves} moves available',
            ),
            _BriefRow(
              icon: Icons.speed_rounded,
              text: isArabic
                  ? 'درجة الصعوبة ${level.difficulty}'
                  : 'Difficulty ${level.difficulty}',
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
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _BoosterCard extends StatelessWidget {
  const _BoosterCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Column(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'x$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}
