import 'package:flutter/material.dart';

import '../../core/logging/log_viewer_screen.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../levels/level_select_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.onToggleLanguage,
  });

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
              : (ar ? 'رائع! حصلت على $reward عملة' : 'Awesome! You earned $reward coins'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                const totalLevels = 5;
                final unlocked = store.highestUnlockedLevel.clamp(1, totalLevels);
                final completed = (unlocked - 1).clamp(0, totalLevels);
                final progress = completed / totalLevels;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ar ? 'مرحبًا أيها المستخدم' : 'Welcome, player',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.navy,
                                  ),
                            ),
                          ),
                          _RoundAction(
                            icon: Icons.article_outlined,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LogViewerScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RoundAction(
                            icon: Icons.language_rounded,
                            onTap: onToggleLanguage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ResourcePill(
                              icon: Icons.favorite_rounded,
                              value: '${store.hearts}/5',
                              label: ar ? 'القلوب' : 'Hearts',
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
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
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
                                          letterSpacing: -1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        ar
                                            ? 'رتّب الشحنات، افتح المخازن، واصعد للقمة'
                                            : 'Sort cargo, unlock warehouses, master every route',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(Icons.warehouse_rounded, size: 68, color: Colors.white),
                                      Positioned(
                                        right: 13,
                                        bottom: 13,
                                        child: Icon(
                                          Icons.local_shipping_rounded,
                                          size: 34,
                                          color: AppTheme.yellow,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                _LevelBadge(level: unlocked),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            ar ? 'تقدم الرحلة' : 'Journey progress',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            '${(progress * 100).round()}%',
                                            style: const TextStyle(
                                              color: AppTheme.yellow,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 9),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 10,
                                          backgroundColor: Colors.white24,
                                          valueColor: const AlwaysStoppedAnimation(AppTheme.yellow),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                              title: ar ? 'المكافأة اليومية' : 'Daily reward',
                              subtitle: store.canClaimDailyReward
                                  ? (ar ? '+50 عملة جاهزة' : '+50 coins ready')
                                  : (ar ? 'تم الاستلام اليوم' : 'Claimed today'),
                              accent: AppTheme.orange,
                              enabled: store.canClaimDailyReward,
                              onTap: () => _claimDailyReward(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.emoji_events_rounded,
                              title: ar ? 'إنجازك' : 'Achievement',
                              subtitle: ar
                                  ? '$completed من $totalLevels مراحل'
                                  : '$completed of $totalLevels levels',
                              accent: AppTheme.green,
                              enabled: true,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: AppTheme.orangeGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55FF8A00),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: store.hearts > 0
                                ? () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => LevelSelectScreen(store: store),
                                      ),
                                    )
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                                  const SizedBox(width: 10),
                                  Text(
                                    store.hearts > 0
                                        ? (ar ? 'ابدأ اللعب' : 'PLAY NOW')
                                        : (ar ? 'لا توجد قلوب' : 'NO HEARTS'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Walid Atiya Ata - PMP',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF4FF), AppTheme.cream],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
}

class _ResourcePill extends StatelessWidget {
  const _ResourcePill({
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: accent.withValues(alpha: .12), shape: BoxShape.circle),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900, fontSize: 17)),
                Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.route_rounded, color: AppTheme.yellow, size: 23),
          Text('$level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(height: 13),
              Text(title, style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
