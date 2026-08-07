import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../../core/widgets/game_button.dart';
import '../../core/widgets/game_hero_panel.dart';
import '../../core/widgets/game_panel.dart';
import '../../core/widgets/game_stat_panel.dart';

class ProgressHubScreen extends StatelessWidget {
  const ProgressHubScreen({super.key, required this.store});

  final ProgressStore store;

  Future<void> _claimMission(BuildContext context) async {
    final reward = await store.claimDailyMission();
    if (!context.mounted) return;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reward == null
              ? (ar
                    ? 'أكمل جميع أهداف اليوم أولًا'
                    : 'Complete all daily goals first')
              : (ar ? 'تم استلام $reward عملة' : 'Claimed $reward coins'),
        ),
      ),
    );
  }

  String _heartTimer(bool ar) {
    final remaining = store.timeUntilNextHeart;
    if (remaining == Duration.zero) return ar ? 'القلوب مكتملة' : 'Hearts full';
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return ar
        ? 'القلب التالي خلال $minutes:$seconds'
        : 'Next heart in $minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'تقدم اللاعب' : 'Player Progress')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _LevelHero(store: store, ar: ar),
            const SizedBox(height: 14),
            _HeroStats(store: store, ar: ar),
            const SizedBox(height: 14),
            _StreakMetrics(store: store, ar: ar),
            const SizedBox(height: 14),
            _HeartPanel(store: store, timer: _heartTimer(ar), ar: ar),
            const SizedBox(height: 18),
            Text(
              ar ? 'مهمة اليوم' : 'Daily Mission',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _MissionTile(
              label: ar ? 'اربح 3 مدن' : 'Win 3 cities',
              value: store.missionWins,
              target: 3,
              icon: Icons.flag_rounded,
            ),
            _MissionTile(
              label: ar ? 'اجمع 6 نجوم' : 'Earn 6 stars',
              value: store.missionStars,
              target: 6,
              icon: Icons.star_rounded,
            ),
            _MissionTile(
              label: ar ? 'اجمع 150 عملة' : 'Earn 150 coins',
              value: store.missionCoins,
              target: 150,
              icon: Icons.monetization_on_rounded,
            ),
            const SizedBox(height: 10),
            GameButton(
              semanticLabel: store.missionClaimed
                  ? (ar ? 'تم استلام مكافأة المهمة' : 'Mission reward claimed')
                  : (ar ? 'استلم 200 عملة' : 'Claim 200 Coins'),
              onPressed: store.dailyMissionComplete && !store.missionClaimed
                  ? () => _claimMission(context)
                  : null,
              enabled: store.dailyMissionComplete && !store.missionClaimed,
              expand: true,
              height: 54,
              borderRadius: BorderRadius.circular(18),
              backgroundColor: AppTheme.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ThreeDGameIcon(
                    type: ThreeDIconType.gift,
                    size: 28,
                    semanticLabel: 'Mission reward',
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      store.missionClaimed
                          ? (ar ? 'تم الاستلام' : 'Claimed')
                          : (ar ? 'استلم 200 عملة' : 'Claim 200 Coins'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              ar ? 'الإنجازات' : 'Achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _Achievement(
              title: ar ? 'أول انتصار' : 'First Win',
              unlocked: store.wins >= 1,
              icon: Icons.emoji_events_rounded,
            ),
            _Achievement(
              title: ar ? 'خبير المدن' : 'City Expert',
              unlocked: store.completedLevels >= 25,
              icon: Icons.location_city_rounded,
            ),
            _Achievement(
              title: ar ? 'جامع النجوم' : 'Star Collector',
              unlocked: store.totalStars >= 100,
              icon: Icons.auto_awesome_rounded,
            ),
            _Achievement(
              title: ar ? 'سلسلة نارية' : 'Hot Streak',
              unlocked: store.bestWinStreak >= 10,
              icon: Icons.local_fire_department_rounded,
            ),
            _Achievement(
              title: ar ? 'محترف الكومبو' : 'Combo Master',
              unlocked: store.bestCombo >= 10,
              icon: Icons.bolt_rounded,
            ),
            _Achievement(
              title: ar ? 'لاعب مثالي' : 'Perfect Player',
              unlocked: store.perfectWins >= 10,
              icon: Icons.workspace_premium_rounded,
            ),
            _Achievement(
              title: ar ? 'سيد العالم' : 'World Master',
              unlocked: store.completedLevels >= ProgressStore.totalLevels,
              icon: Icons.public_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero({required this.store, required this.ar});

  final ProgressStore store;
  final bool ar;

  @override
  Widget build(BuildContext context) => GameHeroPanel(
    title: ar ? 'مستوى اللاعب' : 'Player Level',
    subtitle: '${store.xpIntoCurrentLevel}/500 XP',
    semanticLabel: ar
        ? 'مستوى اللاعب ${store.playerLevel}'
        : 'Player level ${store.playerLevel}',
    gradient: const LinearGradient(
      colors: [Color(0xFF7B43C6), Color(0xFFB778F2)],
    ),
    progress: store.playerLevelProgress,
    progressLabel: ar ? 'تقدم المستوى' : 'Level progress',
    leading: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${store.playerLevel}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 27,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.store, required this.ar});

  final ProgressStore store;
  final bool ar;

  @override
  Widget build(BuildContext context) => GameHeroPanel(
    title: ar ? 'ملخص الأداء' : 'Performance Summary',
    subtitle: ar ? 'إحصائيات رحلتك الحالية' : 'Your current journey statistics',
    gradient: AppTheme.heroGradient,
    body: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HeroStat(
                label: ar ? 'مباريات' : 'Games',
                value: '${store.gamesPlayed}',
              ),
            ),
            Expanded(
              child: _HeroStat(
                label: ar ? 'انتصارات' : 'Wins',
                value: '${store.wins}',
              ),
            ),
            Expanded(
              child: _HeroStat(
                label: ar ? 'خسائر' : 'Losses',
                value: '${store.losses}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HeroStat(
                label: ar ? 'نسبة الفوز' : 'Win Rate',
                value: '${(store.winRate * 100).round()}%',
              ),
            ),
            Expanded(
              child: _HeroStat(
                label: ar ? 'النجوم' : 'Stars',
                value: '${store.totalStars}',
              ),
            ),
            Expanded(
              child: _HeroStat(
                label: ar ? 'عملات مكتسبة' : 'Coins Earned',
                value: '${store.lifetimeCoinsEarned}',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StreakMetrics extends StatelessWidget {
  const _StreakMetrics({required this.store, required this.ar});

  final ProgressStore store;
  final bool ar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: GameStatPanel(
          iconData: Icons.local_fire_department_rounded,
          label: ar ? 'السلسلة الحالية' : 'Current streak',
          value: '${store.currentWinStreak}',
          accent: AppTheme.orange,
          compact: true,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GameStatPanel(
          iconData: Icons.emoji_events_rounded,
          label: ar ? 'أفضل سلسلة' : 'Best streak',
          value: '${store.bestWinStreak}',
          accent: AppTheme.green,
          compact: true,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GameStatPanel(
          iconData: Icons.bolt_rounded,
          label: ar ? 'أفضل Combo' : 'Best combo',
          value: '${store.bestCombo}',
          accent: const Color(0xFF7B43C6),
          compact: true,
        ),
      ),
    ],
  );
}

class _HeartPanel extends StatelessWidget {
  const _HeartPanel({
    required this.store,
    required this.timer,
    required this.ar,
  });

  final ProgressStore store;
  final String timer;
  final bool ar;

  @override
  Widget build(BuildContext context) => GamePanel(
    semanticLabel:
        '${store.hearts}/${ProgressStore.maxHearts} ${ar ? 'قلوب' : 'hearts'}',
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        const ThreeDGameIcon(
          type: ThreeDIconType.heart,
          size: 42,
          animate: true,
          semanticLabel: 'Hearts',
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${store.hearts}/${ProgressStore.maxHearts} ${ar ? 'قلوب' : 'hearts'}',
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timer,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Icon(
          store.hearts < ProgressStore.maxHearts
              ? Icons.timer_outlined
              : Icons.check_circle_rounded,
          color: store.hearts < ProgressStore.maxHearts
              ? AppTheme.orange
              : AppTheme.green,
        ),
      ],
    ),
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    ],
  );
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.label,
    required this.value,
    required this.target,
    required this.icon,
  });

  final String label;
  final int value;
  final int target;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final progress = (value / target).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GamePanel(
        semanticLabel: '$label ${value.clamp(0, target)} of $target',
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${value.clamp(0, target)}/$target'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Achievement extends StatelessWidget {
  const _Achievement({
    required this.title,
    required this.unlocked,
    required this.icon,
  });

  final String title;
  final bool unlocked;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GamePanel(
      semanticLabel: unlocked ? '$title unlocked' : '$title locked',
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: unlocked
                ? AppTheme.orange.withValues(alpha: .16)
                : Colors.black12,
            child: Icon(
              unlocked ? icon : Icons.lock_rounded,
              color: unlocked ? AppTheme.orange : Colors.black38,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: unlocked ? AppTheme.navy : Colors.black38,
              ),
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: unlocked ? AppTheme.green : Colors.black26,
          ),
        ],
      ),
    ),
  );
}
