import 'package:flutter/material.dart';

import '../../core/ads/banner_ad_footer.dart';
import '../../core/logging/log_viewer_screen.dart';
import '../../core/motion/ambient_motion_background.dart';
import '../../core/navigation/game_navigator.dart';
import '../../core/navigation/game_route_names.dart';
import '../../core/settings/app_settings_store.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../../core/widgets/game_action_panel.dart';
import '../../core/widgets/game_button.dart';
import '../../core/widgets/game_fit_view.dart';
import '../../core/widgets/game_panel.dart';
import '../../core/widgets/game_resource_panel.dart';
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
    required this.settings,
    required this.onToggleLanguage,
  });

  final ProgressStore store;
  final AppSettingsStore settings;
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
      await GameNavigator.pushNamed<void>(
        context,
        name: GameRouteNames.worldMap,
        builder: (_) =>
            LevelSelectScreen(store: store, settings: widget.settings),
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

  void _openShop() {
    GameNavigator.pushNamed<void>(
      context,
      name: GameRouteNames.shop,
      builder: (_) => ShopScreen(store: store),
    );
  }

  void _openProgress() {
    GameNavigator.pushNamed<void>(
      context,
      name: GameRouteNames.progress,
      builder: (_) => ProgressHubScreen(store: store),
    );
  }

  void _openLogs() {
    GameNavigator.pushNamed<void>(
      context,
      name: GameRouteNames.logs,
      builder: (_) => const LogViewerScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      bottomNavigationBar: const BannerAdFooter(),
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
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: .30),
                          Colors.white.withValues(alpha: .06),
                          const Color(0xFFF8FBFF).withValues(alpha: .64),
                        ],
                        stops: const [0, .48, 1],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 390;
                    final horizontal = compact ? 12.0 : 18.0;
                    return GameFitView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        8,
                        horizontal,
                        8,
                      ),
                      child: SizedBox(
                        width: constraints.maxWidth - (horizontal * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CommandHeader(
                              ar: ar,
                              compact: compact,
                              worldNumber: worldNumber,
                              onShop: _openShop,
                              onProgress: _openProgress,
                              onLogs: _openLogs,
                              onLanguage: widget.onToggleLanguage,
                            ),
                            const SizedBox(height: 8),
                            _ResourceStrip(
                              compact: compact,
                              hearts:
                                  '${store.hearts}/${ProgressStore.maxHearts}',
                              heartLabel: _heartTimer(ar),
                              coins: '${store.coins}',
                              coinLabel: l10n.coins,
                              stars: '${store.totalStars}',
                              starLabel: ar ? 'النجوم' : 'Stars',
                            ),
                            const SizedBox(height: 10),
                            _DestinationHero(
                              ar: ar,
                              compact: compact,
                              title: l10n.appTitle,
                              worldName: world.name,
                              worldNumber: worldNumber,
                              levelNumber: unlocked,
                              currentCity: currentCity,
                              progress: store.completionProgress,
                              completed: store.completedLevels,
                              startColor: world.startColor,
                              endColor: world.endColor,
                            ),
                            const SizedBox(height: 10),
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
                            const SizedBox(height: 8),
                            _PerformanceStrip(
                              ar: ar,
                              current: store.currentWinStreak,
                              best: store.bestWinStreak,
                              combo: store.bestCombo,
                              onTap: _openProgress,
                            ),
                            const SizedBox(height: 10),
                            _StartJourneyButton(
                              ar: ar,
                              compact: compact,
                              busy: _openingJourney,
                              enabled: store.hearts > 0,
                              cityName: currentCity,
                              levelNumber: unlocked,
                              onPressed: _openJourney,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Walid Atiya Ata - PMP',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .2,
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _CommandHeader extends StatelessWidget {
  const _CommandHeader({
    required this.ar,
    required this.compact,
    required this.worldNumber,
    required this.onShop,
    required this.onProgress,
    required this.onLogs,
    required this.onLanguage,
  });

  final bool ar;
  final bool compact;
  final int worldNumber;
  final VoidCallback onShop;
  final VoidCallback onProgress;
  final VoidCallback onLogs;
  final VoidCallback onLanguage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 42 : 48,
          height: compact ? 42 : 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF16213E), Color(0xFF0B1120)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white70),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330B1120),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$worldNumber',
            style: TextStyle(
              color: AppTheme.yellow,
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'مركز قيادة الشحنات' : 'CARGO COMMAND',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.navy,
                  fontSize: compact ? 18 : 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
              Text(
                ar
                    ? 'المسار جاهز للمرحلة التالية'
                    : 'Route ready for the next drop',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _HeaderAction(icon: Icons.storefront_rounded, onTap: onShop),
        _HeaderAction(icon: Icons.insights_rounded, onTap: onProgress),
        _HeaderAction(icon: Icons.article_outlined, onTap: onLogs),
        _HeaderAction(icon: Icons.language_rounded, onTap: onLanguage),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4),
    child: Material(
      color: const Color(0xEEFFFFFF),
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: AppTheme.navy, size: 20),
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
        child: GameResourcePanel(
          icon: ThreeDIconType.heart,
          value: hearts,
          label: heartLabel,
          compact: compact,
          animateIcon: true,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: GameResourcePanel(
          icon: ThreeDIconType.coin,
          value: coins,
          label: coinLabel,
          compact: compact,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: GameResourcePanel(
          icon: ThreeDIconType.star,
          value: stars,
          label: starLabel,
          compact: compact,
        ),
      ),
    ],
  );
}

class _DestinationHero extends StatelessWidget {
  const _DestinationHero({
    required this.ar,
    required this.compact,
    required this.title,
    required this.worldName,
    required this.worldNumber,
    required this.levelNumber,
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
  final int levelNumber;
  final String currentCity;
  final double progress;
  final int completed;
  final Color startColor;
  final Color endColor;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(compact ? 28 : 34),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [startColor, Color.lerp(startColor, endColor, .55)!, endColor],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .55)),
      boxShadow: [
        BoxShadow(
          color: endColor.withValues(alpha: .32),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Stack(
      children: [
        PositionedDirectional(
          end: compact ? -34 : -26,
          top: compact ? -26 : -34,
          child: Opacity(
            opacity: .14,
            child: ThreeDGameIcon(
              type: ThreeDIconType.city,
              size: compact ? 180 : 230,
            ),
          ),
        ),
        PositionedDirectional(
          start: -70,
          bottom: -90,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .09),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(compact ? 13 : 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0B1120,
                            ).withValues(alpha: .32),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            ar
                                ? 'الوجهة التالية • المرحلة $levelNumber'
                                : 'NEXT DROP • LEVEL $levelNumber',
                            style: TextStyle(
                              color: AppTheme.yellow,
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 23 : 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentCity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 19 : 22,
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: compact ? 74 : 88,
                    height: compact ? 74 : 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white24),
                    ),
                    alignment: Alignment.center,
                    child: ThreeDGameIcon(
                      type: ThreeDIconType.city,
                      size: compact ? 60 : 72,
                      animate: true,
                      semanticLabel: currentCity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF07111F).withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ar ? 'تقدم شبكة المدن' : 'CITY NETWORK PROGRESS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .35,
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
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.yellow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ar
                                ? '$completed مدينة مكتملة'
                                : '$completed cities cleared',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '$completed/${ProgressStore.totalLevels}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      GameActionPanel(
        icon: ThreeDIconType.gift,
        title: ar ? 'المكافأة اليومية' : 'Daily reward',
        subtitle: dailyClaimed ? (ar ? 'تم الاستلام' : 'Claimed') : '+50',
        onTap: onDaily,
        animateIcon: true,
      ),
      GameActionPanel(
        icon: ThreeDIconType.chest,
        title: ar ? 'مهمة اليوم' : 'Daily mission',
        subtitle: missionClaimed ? (ar ? 'مكتملة' : 'Completed') : missionText,
        onTap: onMission,
      ),
      GameActionPanel(
        icon: ThreeDIconType.coin,
        title: ar ? 'متجر الشحنات' : 'Cargo shop',
        subtitle: ar ? 'طوّر تجهيزاتك' : 'Upgrade loadout',
        onTap: onShop,
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _PerformanceStrip extends StatelessWidget {
  const _PerformanceStrip({
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
  Widget build(BuildContext context) => GamePanel(
    onTap: onTap,
    semanticLabel: ar ? 'أداء السائق' : 'Driver performance',
    backgroundColor: Colors.white.withValues(alpha: .90),
    borderColor: const Color(0xFFDDE4EE),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB62E), Color(0xFFF06419)],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33F06419),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'أداء الرحلة' : 'RUN PERFORMANCE',
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .35,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ar
                    ? 'سلسلة $current • الأفضل $best • كومبو $combo'
                    : 'Streak $current • best $best • combo $combo',
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
        const Icon(Icons.chevron_right_rounded, color: AppTheme.navy),
      ],
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
    required this.levelNumber,
    required this.onPressed,
  });

  final bool ar;
  final bool compact;
  final bool busy;
  final bool enabled;
  final String cityName;
  final int levelNumber;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: GameButton(
        semanticLabel: enabled
            ? (ar
                  ? 'ابدأ المرحلة $levelNumber: $cityName'
                  : 'Start level $levelNumber: $cityName')
            : (ar ? 'لا توجد قلوب' : 'No hearts'),
        onPressed: enabled ? onPressed : null,
        enabled: enabled,
        loading: busy,
        expand: true,
        height: compact ? 68 : 76,
        borderRadius: BorderRadius.circular(26),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gradient: LinearGradient(
          colors: enabled
              ? const [Color(0xFF17233D), Color(0xFF0A1020)]
              : const [Color(0xFFB8BEC7), Color(0xFF8C939D)],
        ),
        shadowColor: const Color(0x66111A2E),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD65A), Color(0xFFF28A1A)],
                      )
                    : null,
                color: enabled ? null : Colors.white24,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabled
                        ? (ar ? 'ابدأ الرحلة التالية' : 'START NEXT DROP')
                        : (ar ? 'لا توجد قلوب' : 'NO HEARTS'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 16 : 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                  Text(
                    ar
                        ? 'المرحلة $levelNumber • $cityName'
                        : 'Level $levelNumber • $cityName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const ThreeDGameIcon(type: ThreeDIconType.chest, size: 48),
          ],
        ),
      ),
    ),
  );
}
