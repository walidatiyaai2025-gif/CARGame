import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../../core/widgets/game_button.dart';

class GameplayResultDebrief extends StatelessWidget {
  const GameplayResultDebrief({
    super.key,
    required this.won,
    required this.worldReward,
    required this.isArabic,
    required this.busy,
    required this.cityName,
    required this.worldName,
    required this.levelNumber,
    required this.stars,
    required this.reward,
    required this.xp,
    required this.bestCombo,
    required this.bonusCoins,
    required this.bonusXp,
    required this.skin,
    required this.onPrimary,
    this.onWatchRewarded,
  });

  final bool won;
  final bool worldReward;
  final bool isArabic;
  final bool busy;
  final String cityName;
  final String worldName;
  final int levelNumber;
  final int stars;
  final int reward;
  final int xp;
  final int bestCombo;
  final int bonusCoins;
  final int bonusXp;
  final GameSkin skin;
  final FutureOr<void> Function()? onPrimary;
  final VoidCallback? onWatchRewarded;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reducedMotion = media.disableAnimations;

    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: media.viewInsets.bottom + 14,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: media.size.height * .88,
            ),
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: .9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33051020),
                      blurRadius: 34,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DebriefHero(
                          won: won,
                          worldReward: worldReward,
                          isArabic: isArabic,
                          cityName: cityName,
                          worldName: worldName,
                          levelNumber: levelNumber,
                          skin: skin,
                          animate: !reducedMotion,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (won) ...[
                                _StarsRow(stars: stars),
                                const SizedBox(height: 14),
                                _SectionHeader(
                                  eyebrow: isArabic
                                      ? 'حصيلة العملية'
                                      : 'OPERATION PAYOUT',
                                  title: isArabic
                                      ? 'بيان المكافآت'
                                      : 'REWARD MANIFEST',
                                  icon: Icons.inventory_2_rounded,
                                ),
                                const SizedBox(height: 10),
                                _RewardGrid(
                                  reward: reward,
                                  xp: xp,
                                  bestCombo: bestCombo,
                                  bonusCoins: bonusCoins,
                                  bonusXp: bonusXp,
                                  isArabic: isArabic,
                                  accent: skin.accent,
                                ),
                              ] else ...[
                                _SectionHeader(
                                  eyebrow: isArabic
                                      ? 'خطة الاسترداد'
                                      : 'RECOVERY PLAN',
                                  title: isArabic
                                      ? 'خيارات الاستمرار'
                                      : 'RECOVERY OPTIONS',
                                  icon: Icons.route_rounded,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isArabic
                                      ? 'انتهت الحركات، لكن مسار الشحنة ما زال محفوظًا. استمر بخمس حركات إضافية أو أعد المهمة من البداية.'
                                      : 'Moves are exhausted, but the cargo route is still intact. Continue with five extra moves or restart the mission cleanly.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF657286),
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              if (!won) ...[
                                GameButton(
                                  semanticLabel: isArabic
                                      ? 'شاهد إعلانًا وخذ خمس حركات'
                                      : 'Watch ad for five moves',
                                  onPressed: busy ? null : onWatchRewarded,
                                  enabled: !busy,
                                  expand: true,
                                  height: 52,
                                  borderRadius: BorderRadius.circular(18),
                                  backgroundColor: Colors.white,
                                  foregroundColor: skin.primary,
                                  border: Border.all(
                                    color: skin.primary.withValues(alpha: .25),
                                  ),
                                  shadowColor: skin.primary.withValues(alpha: .08),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.ondemand_video_rounded),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          isArabic
                                              ? 'استمرار سريع — +5 حركات'
                                              : 'QUICK CONTINUE — +5 MOVES',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: .2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              GameButton(
                                semanticLabel: won
                                    ? (isArabic
                                          ? 'التالي والعودة للخريطة'
                                          : 'Next and back to map')
                                    : (isArabic ? 'إعادة المحاولة' : 'Retry'),
                                onPressed: busy ? null : onPrimary,
                                enabled: !busy,
                                loading: busy,
                                expand: true,
                                height: 56,
                                borderRadius: BorderRadius.circular(20),
                                gradient: won
                                    ? skin.heroGradient
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFFE85363),
                                          Color(0xFFB72F48),
                                        ],
                                      ),
                                shadowColor: won
                                    ? skin.primary.withValues(alpha: .34)
                                    : const Color(0x55B72F48),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      won
                                          ? Icons.arrow_forward_rounded
                                          : Icons.restart_alt_rounded,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        won
                                            ? (isArabic
                                                  ? 'التالي — العودة إلى شبكة المسارات'
                                                  : 'NEXT — RETURN TO ROUTE NETWORK')
                                            : (isArabic
                                                  ? 'إعادة تشغيل المهمة'
                                                  : 'RESTART MISSION'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DebriefHero extends StatelessWidget {
  const _DebriefHero({
    required this.won,
    required this.worldReward,
    required this.isArabic,
    required this.cityName,
    required this.worldName,
    required this.levelNumber,
    required this.skin,
    required this.animate,
  });

  final bool won;
  final bool worldReward;
  final bool isArabic;
  final String cityName;
  final String worldName;
  final int levelNumber;
  final GameSkin skin;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final gradient = won
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF091321),
              skin.primary,
              skin.secondary,
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF20111A), Color(0xFF79283A), Color(0xFFB23B50)],
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -42,
            end: -28,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _HeaderPill(
                    icon: won
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    text: isArabic ? 'تقرير المهمة' : 'MISSION DEBRIEF',
                  ),
                  const Spacer(),
                  _HeaderPill(
                    icon: Icons.tag_rounded,
                    text: '${isArabic ? 'مرحلة' : 'LEVEL'} $levelNumber',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .18),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: won
                        ? ThreeDGameIcon(
                            type: worldReward
                                ? ThreeDIconType.boss
                                : ThreeDIconType.chest,
                            size: 66,
                            animate: animate,
                            semanticLabel: worldReward
                                ? 'World reward'
                                : 'Mission reward',
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              ThreeDGameIcon(
                                type: ThreeDIconType.heart,
                                size: 62,
                                animate: false,
                                semanticLabel: 'Mission failed',
                              ),
                              const Icon(
                                Icons.close_rounded,
                                size: 38,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          won
                              ? worldReward
                                    ? (isArabic
                                          ? 'اكتمل العالم'
                                          : 'WORLD COMPLETE')
                                    : (isArabic
                                          ? 'تم تأمين المسار'
                                          : 'ROUTE SECURED')
                              : (isArabic
                                    ? 'المهمة متوقفة'
                                    : 'MISSION INTERRUPTED'),
                          style: TextStyle(
                            color: won ? skin.accent : const Color(0xFFFFD5DA),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cityName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          worldName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .35,
          ),
        ),
      ],
    ),
  );
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars of 3 stars',
    child: ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < stars
                    ? const Color(0xFFFFF3C5)
                    : const Color(0xFFE9EDF3),
                border: Border.all(
                  color: index < stars
                      ? AppTheme.yellow.withValues(alpha: .45)
                      : const Color(0xFFD7DEE8),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                color: index < stars ? AppTheme.yellow : const Color(0xFF9BA7B8),
                size: 34,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0F8),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppTheme.navy, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: Color(0xFF8390A2),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RewardGrid extends StatelessWidget {
  const _RewardGrid({
    required this.reward,
    required this.xp,
    required this.bestCombo,
    required this.bonusCoins,
    required this.bonusXp,
    required this.isArabic,
    required this.accent,
  });

  final int reward;
  final int xp;
  final int bestCombo;
  final int bonusCoins;
  final int bonusXp;
  final bool isArabic;
  final Color accent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 380;
      final items = <Widget>[
        _RewardMetric(
          icon: ThreeDIconType.coin,
          label: isArabic ? 'عملات' : 'COINS',
          value: '+$reward',
          accent: accent,
        ),
        _RewardMetric(
          icon: ThreeDIconType.star,
          label: 'XP',
          value: '+$xp',
          accent: accent,
        ),
        _RewardMetric(
          icon: null,
          fallbackIcon: Icons.local_fire_department_rounded,
          label: isArabic ? 'أفضل كومبو' : 'BEST COMBO',
          value: 'x$bestCombo',
          accent: accent,
        ),
        if (bonusCoins > 0)
          _RewardMetric(
            icon: ThreeDIconType.gift,
            label: isArabic ? 'مكافأة' : 'BONUS',
            value: '+$bonusCoins',
            accent: accent,
          ),
        if (bonusXp > 0)
          _RewardMetric(
            icon: ThreeDIconType.star,
            label: isArabic ? 'XP إضافي' : 'BONUS XP',
            value: '+$bonusXp',
            accent: accent,
          ),
      ];

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: narrow ? 2 : 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: narrow ? 1.42 : 1.25,
        children: items,
      );
    },
  );
}

class _RewardMetric extends StatelessWidget {
  const _RewardMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.fallbackIcon,
  });

  final ThreeDIconType? icon;
  final IconData? fallbackIcon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E7EF)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: icon != null
              ? ThreeDGameIcon(type: icon!, size: 34, animate: false)
              : Icon(fallbackIcon, color: accent, size: 28),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8B96A6),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
