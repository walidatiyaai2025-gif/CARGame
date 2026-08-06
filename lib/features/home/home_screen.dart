import 'package:flutter/material.dart';

import '../../core/logging/log_viewer_screen.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../game/city_catalog.dart';
import '../game/level_data.dart';
import '../levels/level_select_screen.dart';
import '../progress/progress_hub_screen.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.onToggleLanguage,
  });

  final ProgressStore store;
  final VoidCallback onToggleLanguage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _openingJourney = false;

  ProgressStore get store => widget.store;

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

  Future<void> _openJourney() async {
    if (_openingJourney || store.hearts <= 0) return;
    setState(() => _openingJourney = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LevelSelectScreen(store: store),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingJourney = false);
    }
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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 390;
                  final pagePadding = compact ? 12.0 : 18.0;
                  return ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(pagePadding, 10, pagePadding, 24),
                    children: [
                      _Header(
                        ar: ar,
                        compact: compact,
                        onShop: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => ShopScreen(store: store)),
                        ),
                        onProgress: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => ProgressHubScreen(store: store)),
                        ),
                        onLogs: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const LogViewerScreen()),
                        ),
                        onLanguage: widget.onToggleLanguage,
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ResourcePill(
                              icon: Icons.monetization_on_rounded,
                              value: '${store.coins}',
                              label: l10n.coins,
                              accent: AppTheme.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                      _JourneyCard(
                        store: store,
                        world: world,
                        worldNumber: worldNumber,
                        currentCity: currentCity,
                        title: l10n.appTitle,
                        ar: ar,
                        compact: compact,
                      ),
                      const SizedBox(height: 16),
                      if (compact) ...[
                        _FeatureCard(
                          icon: Icons.card_giftcard_rounded,
                          title: ar ? 'المكافأة اليومية' : 'Daily Reward',
                          subtitle: store.canClaimDailyReward ? '+50' : (ar ? 'تم الاستلام' : 'Claimed'),
                          accent: AppTheme.orange,
                          onTap: () => _claimDailyReward(context),
                        ),
                        const SizedBox(height: 10),
                        _FeatureCard(
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
                      ] else
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
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 220,
                            maxWidth: 560,
                            minHeight: 58,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: store.hearts > 0 && !_openingJourney ? _openJourney : null,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(58),
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 14 : 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_openingJourney)
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  else
                                    const Icon(Icons.play_arrow_rounded, size: 30),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        store.hearts > 0
                                            ? (ar ? 'استكمل الرحلة' : 'CONTINUE JOURNEY')
                                            : (ar ? 'لا توجد قلوب' : 'NO HEARTS'),
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: compact ? 17 : 19,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.ar,
    required this.compact,
    required this.onShop,
    required this.onProgress,
    required this.onLogs,
    required this.onLanguage,
  });

  final bool ar;
  final bool compact;
  final VoidCallback onShop;
  final VoidCallback onProgress;
  final VoidCallback onLogs;
  final VoidCallback onLanguage;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _RoundAction(icon: Icons.storefront_rounded, onTap: onShop, compact: compact),
      _RoundAction(icon: Icons.insights_rounded, onTap: onProgress, compact: compact),
      _RoundAction(icon: Icons.article_outlined, onTap: onLogs, compact: compact),
      _RoundAction(icon: Icons.language_rounded, onTap: onLanguage, compact: compact),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'مرحبًا أيها المستخدم' : 'Welcome, player',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.store,
    required this.world,
    required this.worldNumber,
    required this.currentCity,
    required this.title,
    required this.ar,
    required this.compact,
  });

  final ProgressStore store;
  final GameWorld world;
  final int worldNumber;
  final String currentCity;
  final String title;
  final bool ar;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(compact ? 18 : 22),
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 28 : 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ar ? 'العالم $worldNumber — ${world.name}' : 'World $worldNumber — ${world.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 14 : 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        currentCity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.yellow,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: compact ? 68 : 88,
                  height: compact ? 68 : 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(world.icon, color: Colors.white, size: compact ? 42 : 54),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    ar ? 'التقدم العالمي' : 'Global progress',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
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
      );
}

class _PlayerLevelCard extends StatelessWidget {
  const _PlayerLevelCard({required this.store, required this.ar});
  final ProgressStore store;
  final bool ar;

  @override
  Widget build(BuildContext context) => Container(
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
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
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

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap, required this.compact});
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Icon(icon, color: AppTheme.navy, size: compact ? 22 : 24),
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: accent),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900, fontSize: 16),
              ),
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
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900),
                      ),
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
