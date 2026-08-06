import 'package:flutter/material.dart';

import '../../core/logging/log_viewer_screen.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../game/level_data.dart';
import '../levels/level_select_screen.dart';
import '../progress/progress_hub_screen.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.onToggleLanguage});

  final ProgressStore store;
  final VoidCallback onToggleLanguage;

  Future<void> _claimDailyReward(BuildContext context) async {
    final reward = await store.claimDailyReward();
    if (!context.mounted) return;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reward == null
              ? (ar ? 'تم استلام مكافأة اليوم بالفعل' : 'Daily reward already claimed')
              : (ar ? 'حصلت على $reward عملة' : 'You earned $reward coins'),
        ),
      ),
    );
  }

  String _heartTimer(bool ar) {
    final remaining = store.timeUntilNextHeart;
    if (remaining == Duration.zero) return ar ? 'القلوب مكتملة' : 'Hearts full';
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return ar ? 'القلب التالي $minutes:$seconds' : 'Next heart $minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4FF), AppTheme.cream],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final unlocked = store.highestUnlockedLevel.clamp(1, levels.length);
              final worldNumber = ((unlocked - 1) ~/ 25 + 1).clamp(1, gameWorlds.length);
              final world = gameWorlds[worldNumber - 1];
              final currentCity = levels[unlocked - 1].cityName;

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ar ? 'مرحبًا أيها المستخدم' : 'Welcome, player',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      _RoundAction(
                        icon: Icons.storefront_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => ShopScreen(store: store)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundAction(
                        icon: Icons.insights_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => ProgressHubScreen(store: store)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundAction(
                        icon: Icons.article_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const LogViewerScreen()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundAction(icon: Icons.language_rounded, onTap: onToggleLanguage),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ResourcePill(
                          icon: Icons.favorite_rounded,
                          value: '${store.hearts}/${ProgressStore.maxHearts}',
                          label: _heartTimer(ar),
                          accent: AppTheme.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ResourcePill(
                          icon: Icons.monetization_on_rounded,
                          value: '${store.coins}',
                          label: l10n.coins,
                          accent: AppTheme.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ResourcePill(
                          icon: Icons.star_rounded,
                          value: '${store.totalStars}',
                          label: ar ? 'النجوم' : 'Stars',
                          accent: AppTheme.yellow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PlayerLevelCard(store: store, ar: ar),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [world.startColor, world.endColor]),
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: world.startColor.withValues(alpha: .35),
                          blurRadius: 26,
                          offset: const Offset(0, 13),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.appTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    ar ? 'العالم $worldNumber — ${world.name}' : 'World $worldNumber — ${world.name}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    currentCity,
                                    style: const TextStyle(
                                      color: AppTheme.yellow,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Icon(world.icon, color: Colors.white, size: 54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ar ? 'التقدم العالمي' : 'Global progress',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${(store.completionProgress * 100).round()}%',
                              style: const TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: store.completionProgress,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(10),
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(AppTheme.yellow),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${store.completedLevels}/${ProgressStore.totalLevels} ${ar ? 'مدينة' : 'cities'}',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.card_giftcard_rounded,
                          title: ar ? 'المكافأة اليومية' : 'Daily Reward',
                          subtitle: store.canClaimDailyReward ? '+50' : (ar ? 'تم الاستلام' : 'Claimed'),
                          accent: AppTheme.orange,
                          onTap: () => _claimDailyReward(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.task_alt_rounded,
                          title: ar ? 'مهمة اليوم' : 'Daily Mission',
                          subtitle: store.missionClaimed
                              ? (ar ? 'مكتملة' : 'Completed')
                              : '${store.missionWins}/3 • ${store.missionStars}/6',
                          accent: AppTheme.green,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => ProgressHubScreen(store: store)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.local_fire_department_rounded,
                    title: ar ? 'سلسلة الانتصارات' : 'Win Streak',
                    subtitle: ar
                        ? '${store.currentWinStreak} حاليًا • الأفضل ${store.bestWinStreak} • أفضل Combo ${store.bestCombo}'
                        : '${store.currentWinStreak} current • best ${store.bestWinStreak} • combo ${store.bestCombo}',
                    accent: const Color(0xFF7B43C6),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ProgressHubScreen(store: store)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: store.hearts > 0
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => LevelSelectScreen(store: store)),
                            )
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 34),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        store.hearts > 0
                            ? (ar ? 'استكمل الرحلة' : 'CONTINUE JOURNEY')
                            : (ar ? 'لا توجد قلوب' : 'NO HEARTS'),
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Walid Atiya Ata - PMP',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w800),
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

class _PlayerLevelCard extends StatelessWidget {
  const _PlayerLevelCard({required this.store, required this.ar});
  final ProgressStore store;
  final bool ar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF7B43C6), Color(0xFFB778F2)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${store.playerLevel}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ar ? 'مستوى اللاعب' : 'Player Level',
                      style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${store.xpIntoCurrentLevel}/500 XP',
                      style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                LinearProgressIndicator(
                  value: store.playerLevelProgress,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: const Color(0xFFE9E1F5),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF7B43C6)),
                ),
                const SizedBox(height: 7),
                Text(
                  ar ? 'كل 500 XP تفتح مستوى جديد' : 'Every 500 XP unlocks a new player level',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: AppTheme.navy),
          ),
        ),
      );
}

class _ResourcePill extends StatelessWidget {
  const _ResourcePill({required this.icon, required this.value, required this.label, required this.accent});
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: accent),
            Text(
              value,
              style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.muted, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900)),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black26),
              ],
            ),
          ),
        ),
      );
}
