import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';

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
              ? (ar ? 'أكمل جميع أهداف اليوم أولًا' : 'Complete all daily goals first')
              : (ar ? 'تم استلام $reward عملة' : 'Claimed $reward coins'),
        ),
      ),
    );
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
            _HeroStats(store: store, ar: ar),
            const SizedBox(height: 18),
            Text(ar ? 'مهمة اليوم' : 'Daily Mission', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _MissionTile(label: ar ? 'اربح 3 مدن' : 'Win 3 cities', value: store.missionWins, target: 3, icon: Icons.flag_rounded),
            _MissionTile(label: ar ? 'اجمع 6 نجوم' : 'Earn 6 stars', value: store.missionStars, target: 6, icon: Icons.star_rounded),
            _MissionTile(label: ar ? 'اجمع 150 عملة' : 'Earn 150 coins', value: store.missionCoins, target: 150, icon: Icons.monetization_on_rounded),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: store.dailyMissionComplete && !store.missionClaimed ? () => _claimMission(context) : null,
              icon: const Icon(Icons.redeem_rounded),
              label: Text(store.missionClaimed ? (ar ? 'تم الاستلام' : 'Claimed') : (ar ? 'استلم 200 عملة' : 'Claim 200 Coins')),
            ),
            const SizedBox(height: 22),
            Text(ar ? 'الإنجازات' : 'Achievements', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _Achievement(title: ar ? 'أول انتصار' : 'First Win', unlocked: store.wins >= 1, icon: Icons.emoji_events_rounded),
            _Achievement(title: ar ? 'خبير المدن' : 'City Expert', unlocked: store.completedLevels >= 25, icon: Icons.location_city_rounded),
            _Achievement(title: ar ? 'جامع النجوم' : 'Star Collector', unlocked: store.totalStars >= 100, icon: Icons.auto_awesome_rounded),
            _Achievement(title: ar ? 'لاعب مثالي' : 'Perfect Player', unlocked: store.perfectWins >= 10, icon: Icons.workspace_premium_rounded),
            _Achievement(title: ar ? 'سيد العالم' : 'World Master', unlocked: store.completedLevels >= 150, icon: Icons.public_rounded),
          ],
        ),
      ),
    );
  }
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
            Row(children: [
              Expanded(child: _Stat(label: ar ? 'مباريات' : 'Games', value: '${store.gamesPlayed}')),
              Expanded(child: _Stat(label: ar ? 'انتصارات' : 'Wins', value: '${store.wins}')),
              Expanded(child: _Stat(label: ar ? 'خسائر' : 'Losses', value: '${store.losses}')),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _Stat(label: ar ? 'نسبة الفوز' : 'Win Rate', value: '${(store.winRate * 100).round()}%')),
              Expanded(child: _Stat(label: ar ? 'النجوم' : 'Stars', value: '${store.totalStars}')),
              Expanded(child: _Stat(label: ar ? 'عملات مكتسبة' : 'Coins Earned', value: '${store.lifetimeCoinsEarned}')),
            ]),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]);
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.label, required this.value, required this.target, required this.icon});
  final String label;
  final int value;
  final int target;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final progress = (value / target).clamp(0, 1).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(icon, color: AppTheme.orange),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${value.clamp(0, target)}/$target')]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
          ])),
        ]),
      ),
    );
  }
}

class _Achievement extends StatelessWidget {
  const _Achievement({required this.title, required this.unlocked, required this.icon});
  final String title;
  final bool unlocked;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: unlocked ? AppTheme.orange.withValues(alpha: .16) : Colors.black12,
            child: Icon(unlocked ? icon : Icons.lock_rounded, color: unlocked ? AppTheme.orange : Colors.black38),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: unlocked ? AppTheme.navy : Colors.black38)),
          trailing: Icon(unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded, color: unlocked ? AppTheme.green : Colors.black26),
        ),
      );
}
