import 'package:flutter/material.dart';

import '../../core/logging/log_viewer_screen.dart';
import '../../core/motion/ambient_motion_background.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../../core/widgets/game_button.dart';
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

  Future<void> _claimDailyReward() async {
    final reward = await store.claimDailyReward();
    if (!mounted) return;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reward == null
              ? (ar
                    ? 'تم استلام مكافأة اليوم بالفعل'
                    : 'Daily reward already claimed')
              : (ar ? 'حصلت على $reward عملة' : 'You earned $reward coins'),
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
        ? 'القلب التالي $minutes:$seconds'
        : 'Next heart $minutes:$seconds';
  }

  void _openShop() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ShopScreen(store: store)));

  void _openProgress() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ProgressHubScreen(store: store)),
  );

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final unlocked = store.highestUnlockedLevel.clamp(1, levels.length);
          final worldNumber = ((unlocked - 1) ~/ 25 + 1).clamp(
            1,
            gameWorlds.length,
          );
          final world = gameWorlds[worldNumber - 1];
          final currentCity = levels[unlocked - 1].cityName;

          return Stack(
            children: [
              Positioned.fill(
                child: AmbientMotionBackground(
                  startColor: world.startColor,
                  endColor: world.endColor,
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 390;
                    final horizontal = compact ? 12.0 : 18.0;
                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        10,
                        horizontal,
                        28,
                      ),
                      children: [
                        _TopBar(
                          ar: ar,
                          compact: compact,
                          onShop: _openShop,
                          onProgress: _openProgress,
                          onLogs: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LogViewerScreen(),
                            ),
                          ),
                          onLanguage: widget.onToggleLanguage,
                        ),
                        const SizedBox(height: 14),
                        _ResourceStrip(
                          compact: compact,
                          hearts: '${store.hearts}/${ProgressStore.maxHearts}',
                          heartLabel: _heartTimer(ar),
                          coins: '${store.coins}',
                          coinLabel: l10n.coins,
                          stars: '${store.totalStars}',
                          starLabel: ar ? 'النجوم' : 'Stars',
                        ),
                        const SizedBox(height: 18),
                        _JourneyHero(
                          ar: ar,
                          compact: compact,
                          title: l10n.appTitle,
                          worldName: world.name,
                          worldNumber: worldNumber,
                          currentCity: currentCity,
                          progress: store.completionProgress,
                          completed: store.completedLevels,
                          startColor: world.startColor,
                          endColor: world.endColor,
                        ),
                        const SizedBox(height: 16),
                        _QuickActions(
                          compact: compact,
                          ar: ar,
                          dailyClaimed: !store.canClaimDailyReward,
                          missionClaimed: store.missionClaimed,
                          missionText:
                              '${store.missionWins}/3 • ${store.missionStars}/6',
                          onDaily: _claimDailyReward,
                          onMission: _openProgress,
                          onShop: _openShop,
                        ),
                        const SizedBox(height: 14),
                        _StreakPanel(
                          ar: ar,
                          current: store.currentWinStreak,
                          best: store.bestWinStreak,
                          combo: store.bestCombo,
                          onTap: _openProgress,
                        ),
                        const SizedBox(height: 20),
                        _StartJourneyButton(
                          ar: ar,
                          compact: compact,
                          busy: _openingJourney,
                          enabled: store.hearts > 0,
                          cityName: currentCity,
                          onPressed: _openJourney,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Walid Atiya Ata - PMP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ar ? 'مرحبًا أيها المستخدم' : 'Welcome, player',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.navy,
                fontSize: compact ? 22 : 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              ar
                  ? 'جهّز شحنتك وابدأ المغامرة'
                  : 'Prepare your cargo and start the adventure',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _TopAction(icon: Icons.storefront_rounded, onTap: onShop),
      _TopAction(icon: Icons.insights_rounded, onTap: onProgress),
      _TopAction(icon: Icons.article_outlined, onTap: onLogs),
      _TopAction(icon: Icons.language_rounded, onTap: onLanguage),
    ],
  );
}

class _TopAction extends StatelessWidget {
  const _TopAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 5),
    child: Material(
      color: Colors.white.withValues(alpha: .90),
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppTheme.navy, size: 21),
        ),
      ),
    ),
  );
}

class _ResourceStrip extends StatelessWidget {
  const _ResourceStrip({
    required this.compact,
    required this.hearts,
    required this.heartLabel,
    required this.coins,
    required this.coinLabel,
    required this.stars,
    required this.starLabel,
  });

  final bool compact;
  final String hearts;
  final String heartLabel;
  final String coins;
  final String coinLabel;
  final String stars;
  final String starLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ResourceCard(
          icon: ThreeDIconType.heart,
          value: hearts,
          label: heartLabel,
          compact: compact,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ResourceCard(
          icon: ThreeDIconType.coin,
          value: coins,
          label: coinLabel,
          compact: compact,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ResourceCard(
          icon: ThreeDIconType.star,
          value: stars,
          label: starLabel,
          compact: compact,
        ),
      ),
    ],
  );
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.compact,
  });

  final ThreeDIconType icon;
  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white),
      boxShadow: AppTheme.softShadow,
    ),
    child: Column(
      children: [
        ThreeDGameIcon(
          type: icon,
          size: compact ? 34 : 42,
          animate: icon == ThreeDIconType.heart,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({
    required this.ar,
    required this.compact,
    required this.title,
    required this.worldName,
    required this.worldNumber,
    required this.currentCity,
    required this.progress,
    required this.completed,
    required this.startColor,
    required this.endColor,
  });

  final bool ar;
  final bool compact;
  final String title;
  final String worldName;
  final int worldNumber;
  final String currentCity;
  final double progress;
  final int completed;
  final Color startColor;
  final Color endColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 18 : 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [startColor, endColor],
      ),
      borderRadius: BorderRadius.circular(34),
      boxShadow: [
        BoxShadow(
          color: startColor.withValues(alpha: .38),
          blurRadius: 28,
          offset: const Offset(0, 15),
        ),
      ],
    ),
    child: Stack(
      children: [
        PositionedDirectional(
          end: -12,
          top: -6,
          child: Opacity(
            opacity: .16,
            child: ThreeDGameIcon(
              type: ThreeDIconType.city,
              size: compact ? 150 : 185,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 27 : 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ar
                            ? 'العالم $worldNumber — $worldName'
                            : 'World $worldNumber — $worldName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          currentCity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.yellow,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ThreeDGameIcon(
                  type: ThreeDIconType.city,
                  size: compact ? 82 : 108,
                  animate: true,
                  semanticLabel: currentCity,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ar ? 'التقدم العالمي' : 'Global progress',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 11,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(AppTheme.yellow),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completed/${ProgressStore.totalLevels} ${ar ? 'مدينة مكتملة' : 'cities completed'}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.compact,
    required this.ar,
    required this.dailyClaimed,
    required this.missionClaimed,
    required this.missionText,
    required this.onDaily,
    required this.onMission,
    required this.onShop,
  });

  final bool compact;
  final bool ar;
  final bool dailyClaimed;
  final bool missionClaimed;
  final String missionText;
  final VoidCallback onDaily;
  final VoidCallback onMission;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ActionCard(
        icon: ThreeDIconType.gift,
        title: ar ? 'المكافأة اليومية' : 'Daily reward',
        subtitle: dailyClaimed ? (ar ? 'تم الاستلام' : 'Claimed') : '+50',
        onTap: onDaily,
      ),
      _ActionCard(
        icon: ThreeDIconType.chest,
        title: ar ? 'مهمة اليوم' : 'Daily mission',
        subtitle: missionClaimed ? (ar ? 'مكتملة' : 'Completed') : missionText,
        onTap: onMission,
      ),
      _ActionCard(
        icon: ThreeDIconType.coin,
        title: ar ? 'متجر الشحنات' : 'Cargo shop',
        subtitle: ar ? 'طور قدراتك' : 'Upgrade your loadout',
        onTap: onShop,
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ThreeDIconType icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .94),
    borderRadius: BorderRadius.circular(24),
    elevation: 2,
    shadowColor: Colors.black12,
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ThreeDGameIcon(
              type: icon,
              size: 52,
              animate: icon == ThreeDIconType.gift,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
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

class _StreakPanel extends StatelessWidget {
  const _StreakPanel({
    required this.ar,
    required this.current,
    required this.best,
    required this.combo,
    required this.onTap,
  });

  final bool ar;
  final int current;
  final int best;
  final int combo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF2ECFF),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C5CFF), Color(0xFF5D2BA8)],
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar ? 'سلسلة الانتصارات' : 'Win streak',
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    ar
                        ? '$current حاليًا • الأفضل $best • Combo $combo'
                        : '$current current • best $best • combo $combo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7B43C6)),
          ],
        ),
      ),
    ),
  );
}

class _StartJourneyButton extends StatelessWidget {
  const _StartJourneyButton({
    required this.ar,
    required this.compact,
    required this.busy,
    required this.enabled,
    required this.cityName,
    required this.onPressed,
  });

  final bool ar;
  final bool compact;
  final bool busy;
  final bool enabled;
  final String cityName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: GameButton(
        semanticLabel: enabled
            ? (ar
                  ? 'ابدأ المرحلة التالية: $cityName'
                  : 'Start next city: $cityName')
            : (ar ? 'لا توجد قلوب' : 'No hearts'),
        onPressed: enabled ? onPressed : null,
        enabled: enabled,
        loading: busy,
        expand: true,
        height: compact ? 70 : 78,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        gradient: LinearGradient(
          colors: enabled
              ? const [Color(0xFFFFB62E), Color(0xFFF06419)]
              : const [Color(0xFFB8BEC7), Color(0xFF8C939D)],
        ),
        shadowColor: const Color(0x66E76B17),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabled
                        ? (ar ? 'ابدأ المرحلة التالية' : 'START NEXT CITY')
                        : (ar ? 'لا توجد قلوب' : 'NO HEARTS'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 17 : 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                    ),
                  ),
                  Text(
                    cityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const ThreeDGameIcon(type: ThreeDIconType.chest, size: 52),
          ],
        ),
      ),
    ),
  );
}
