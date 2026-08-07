import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../../core/widgets/game_panel.dart';

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
            Row(
              children: [
                Expanded(
                  child: _CompactMetric(
                    icon: Icons.local_fire_department_rounded,
                    label: ar ? 'السلسلة الحالية' : 'Current streak',
                    value: '${store.currentWinStreak}',
                    accent: AppTheme.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactMetric(
                    icon: Icons.emoji_events_rounded,
                    label: ar ? 'أفضل سلسلة' : 'Best streak',
                    value: '${store.bestWinStreak}',
                    accent: AppTheme.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactMetric(
                    icon: Icons.bolt_rounded,
                    label: ar ? 'أفضل Combo' : 'Best combo',
                    value: '${store.bestCombo}',
                    accent: const Color(0xFF7B43C6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GamePanel(
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
                          _heartTimer(ar),
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
            ),
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
            FilledButton.icon(
              onPressed: store.dailyMissionComplete && !store.missionClaimed
                  ? () => _claimMission(context)
                  : null,
              icon: const Icon(Icons.redeem_rounded),
              label: Text(
                store.missionClaimed
                    ? (ar ? 'تم الاستلام' : 'Claimed')
                    : (ar ? 'استلم 200 عملة' : 'Claim 200 Coins'),
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
              unlocked: store.completedLevels >= 150,
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF7B43C6), Color(0xFFB778F2)],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: AppTheme.softShadow,
    ),
    child: Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${store.playerLevel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'مستوى اللاعب' : 'Player Level',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: store.playerLevelProgress,
                minHeight: 9,
                borderRadius: BorderRadius.circular(9),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(AppTheme.yellow),
              ),
              const SizedBox(height: 6),
              Text(
                '${store.xpIntoCurrentLevel}/500 XP',
                style: const TextStyle(
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

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.store, required this.ar});
  final ProgressStore store;
  final bool ar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: AppTheme.heroGradient,
      borderRadius: BorderRadius.circular(28),
      boxShadow: AppTheme.softShadow,
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: ar ? 'مباريات' : 'Games',
                value: '${store.gamesPlayed}',
              ),
            ),
            Expanded(
              child: _Stat(
                label: ar ? 'انتصارات' : 'Wins',
                value: '${store.wins}',
              ),
            ),
            Expanded(
              child: _Stat(
                label: ar ? 'خسائر' : 'Losses',
                value: '${store.losses}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: ar ? 'نسبة الفوز' : 'Win Rate',
                value: '${(store.winRate * 100).round()}%',
              ),
            ),
            Expanded(
              child: _Stat(
                label: ar ? 'النجوم' : 'Stars',
                value: '${store.totalStars}',
              ),
            ),
            Expanded(
              child: _Stat(
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

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => GamePanel(
    semanticLabel: '$label: $value',
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    borderRadius: BorderRadius.circular(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accent),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.muted, fontSize: 9),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
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
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: unlocked
            ? AppTheme.orange.withValues(alpha: .16)
            : Colors.black12,
        child: Icon(
          unlocked ? icon : Icons.lock_rounded,
          color: unlocked ? AppTheme.orange : Colors.black38,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: unlocked ? AppTheme.navy : Colors.black38,
        ),
      ),
      trailing: Icon(
        unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
        color: unlocked ? AppTheme.green : Colors.black26,
      ),
    ),
  );
}
