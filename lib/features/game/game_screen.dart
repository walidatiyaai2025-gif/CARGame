import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/ads/ad_service.dart';
import '../../core/economy/economy_config.dart';
import '../../core/motion/game_action_feedback.dart';
import '../../core/motion/game_travel_motion.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../../core/widgets/game_button.dart';
import 'cargo_motion_tile.dart';
import 'city_catalog.dart';
import 'level_data.dart';
import 'mission_loadout.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.store,
    this.loadout = MissionLoadout.empty,
    this.adService,
    this.hapticsEnabled = true,
    this.soundEnabled = true,
    this.onPlacementSound,
  });

  final LevelData level;
  final ProgressStore store;
  final MissionLoadout loadout;
  final AdService? adService;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final GameActionFeedbackSoundHook? onPlacementSound;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final AdService _ads;
  final GlobalKey _motionLayerKey = GlobalKey();

  late List<CargoItem> _remaining;
  CargoItem? _selected;
  int? _selectedIndex;
  Offset? _selectedOrigin;
  _CargoFlight? _flight;
  int _flightSequence = 0;
  GameActionFeedbackKind? _feedbackKind;
  int _feedbackCombo = 0;
  int _feedbackSequence = 0;
  int _rewardAttemptSequence = 0;
  late String _rewardTransactionId;
  Completer<void>? _feedbackCompleter;
  late int _moves;
  int _combo = 0;
  int _bestCombo = 0;
  int _preparedHints = 0;
  bool _finished = false;
  bool _shieldActive = false;
  bool _madeWrongMove = false;
  bool _resultActionBusy = false;
  bool _resultVisible = false;
  bool _resultSheetDismissed = false;
  bool _resolving = false;

  int get _matchedCount => widget.level.items.length - _remaining.length;
  double get _progress => widget.level.items.isEmpty
      ? 0
      : _matchedCount / widget.level.items.length;

  int get _earnedStars {
    final baseMoves = max(1, widget.level.moves);
    final ratio = _moves / baseMoves;
    if (!_madeWrongMove && ratio >= .25) return 3;
    if (_moves > 1) return 2;
    return 1;
  }

  int get _xpEarned => EconomyConfig.current.levelXpReward(
    difficulty: widget.level.difficulty,
    stars: _earnedStars,
    combo: _bestCombo,
  );

  @override
  void initState() {
    super.initState();
    _ads = widget.adService ?? AdService();
    _ads.preload();
    _reset(applyLoadout: true);
  }

  void _reset({bool applyLoadout = false}) {
    _rewardTransactionId =
        'level-${widget.level.number}-attempt-${DateTime.now().toUtc().microsecondsSinceEpoch}-${_rewardAttemptSequence++}';
    _remaining = [...widget.level.items]
      ..shuffle(Random(widget.level.number * 41));
    final economy = EconomyConfig.current;
    _moves =
        widget.level.moves +
        (applyLoadout && widget.loadout.extraMoves
            ? economy.gameplay.extraMovesPerBooster
            : 0);
    _preparedHints = applyLoadout && widget.loadout.smartHint
        ? economy.gameplay.preparedHintUses
        : 0;
    _selected = null;
    _selectedIndex = null;
    _selectedOrigin = null;
    _flight = null;
    _feedbackKind = null;
    _feedbackCombo = 0;
    final pendingFeedback = _feedbackCompleter;
    if (pendingFeedback != null && !pendingFeedback.isCompleted) {
      pendingFeedback.complete();
    }
    _feedbackCompleter = null;
    _combo = 0;
    _bestCombo = 0;
    _finished = false;
    _shieldActive = applyLoadout && widget.loadout.comboShield;
    _madeWrongMove = false;
    _resultActionBusy = false;
    _resultVisible = false;
    _resolving = false;
  }

  List<CargoItem> get _warehouses {
    final unique = <int, CargoItem>{};
    for (final item in widget.level.items) {
      unique[item.id] = item;
    }
    return unique.values.toList();
  }

  void _choosePackage(CargoItem item, int index, Offset globalOrigin) {
    if (_finished || _moves <= 0 || _resultVisible || _resolving) return;
    setState(() {
      _selected = item;
      _selectedIndex = index;
      _selectedOrigin = globalOrigin;
    });
  }

  void _chooseWarehouse(CargoItem warehouse, Offset globalDestination) {
    final selected = _selected;
    final selectedIndex = _selectedIndex;
    final layer = _motionLayerKey.currentContext?.findRenderObject();
    if (selected == null ||
        selectedIndex == null ||
        _finished ||
        _moves <= 0 ||
        _resultVisible ||
        _resolving ||
        layer is! RenderBox) {
      return;
    }

    final flight = _CargoFlight(
      id: ++_flightSequence,
      item: selected,
      selectedIndex: selectedIndex,
      warehouse: warehouse,
      start: layer.globalToLocal(_selectedOrigin ?? globalDestination),
      end: layer.globalToLocal(globalDestination),
    );
    setState(() {
      _resolving = true;
      _flight = flight;
    });
  }

  Future<void> _completeFlight(_CargoFlight flight) async {
    if (!mounted || _flight?.id != flight.id) return;

    final correct = flight.item.id == flight.warehouse.id;
    final feedbackCompleter = Completer<void>();
    final feedbackSequence = ++_feedbackSequence;
    _feedbackCompleter = feedbackCompleter;
    setState(() {
      _moves--;
      if (correct) {
        if (flight.selectedIndex < _remaining.length &&
            identical(_remaining[flight.selectedIndex], flight.item)) {
          _remaining.removeAt(flight.selectedIndex);
        } else {
          _remaining.remove(flight.item);
        }
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
      } else {
        _madeWrongMove = true;
        if (_shieldActive) {
          _shieldActive = false;
        } else {
          _combo = 0;
        }
      }
      _selected = null;
      _selectedIndex = null;
      _selectedOrigin = null;
      _flight = null;
      _feedbackKind = correct
          ? GameActionFeedbackKind.correct
          : GameActionFeedbackKind.wrong;
      _feedbackCombo = correct ? _combo : 0;
    });

    await feedbackCompleter.future;
    if (!mounted || feedbackSequence != _feedbackSequence) return;
    _resolving = false;

    if (_remaining.isEmpty) {
      await _finishWin();
    } else if (_moves <= 0) {
      await _finishLoss();
    }
  }

  void _completeActionFeedback(int sequence) {
    if (!mounted || sequence != _feedbackSequence) return;
    final completer = _feedbackCompleter;
    setState(() {
      _feedbackKind = null;
      _feedbackCombo = 0;
    });
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _feedbackCompleter = null;
  }

  Future<void> _finishWin() async {
    if (_finished) return;
    _finished = true;

    final stars = _earnedStars;
    final reward = EconomyConfig.current.levelCoinReward(
      level: widget.level.number,
      stars: stars,
      combo: _bestCombo,
    );
    final xp = _xpEarned;

    await widget.store.completeLevel(
      widget.level.number,
      reward,
      stars: stars,
      combo: _bestCombo,
      xpEarned: xp,
      transactionId: _rewardTransactionId,
    );

    if (widget.level.number % 3 == 0) {
      _ads.showInterstitial();
    }
    if (!mounted) return;
    await _showResult(won: true, stars: stars, reward: reward, xp: xp);
  }

  Future<void> _finishLoss() async {
    if (_finished) return;
    _finished = true;
    await widget.store.loseHeart();
    await widget.store.recordLoss();
    if (!mounted) return;
    await _showResult(won: false, stars: 0, reward: 0, xp: 0);
  }

  Future<void> _useHint() async {
    final selected = _selected;
    if (selected == null || _finished) return;

    if (_preparedHints > 0) {
      setState(() => _preparedHints--);
      _message('${selected.name} → ${selected.category} warehouse');
      return;
    }

    var used = false;
    if (widget.store.freeHints > 0) {
      used = await widget.store.useFreeHint();
    }
    if (!used) {
      used = await widget.store.spendCoins(
        EconomyConfig.current.gameplay.hintCoinCost,
      );
    }
    if (!used) {
      _message('Not enough coins or hints.');
      return;
    }
    _message('${selected.name} → ${selected.category} warehouse');
  }

  Future<void> _useExtraMoves() async {
    if (_finished) return;
    final used = await widget.store.useExtraMoves();
    if (!used) {
      _message('No extra-moves boosters available.');
      return;
    }
    if (!mounted) return;
    final extraMoves = EconomyConfig.current.gameplay.extraMovesPerBooster;
    setState(() => _moves += extraMoves);
    _message('+$extraMoves moves added.');
  }

  Future<void> _useComboShield() async {
    if (_finished) return;
    if (_shieldActive) {
      _message('Combo shield is already active.');
      return;
    }
    final used = await widget.store.useComboShield();
    if (!used) {
      _message('No combo shields available.');
      return;
    }
    if (!mounted) return;
    setState(() => _shieldActive = true);
    _message('Combo shield activated.');
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _dismissResultSheet(BuildContext sheetContext) {
    if (_resultSheetDismissed) return;
    final route = ModalRoute.of(sheetContext);
    if (route == null || !route.isActive) {
      _resultSheetDismissed = true;
      return;
    }
    _resultSheetDismissed = true;
    Navigator.of(sheetContext).removeRoute(route);
  }

  Future<void> _closeResultAndReturnToMap(BuildContext sheetContext) async {
    if (_resultActionBusy) return;
    _resultActionBusy = true;

    final route = ModalRoute.of(context);
    if (route == null) return;
    final navigator = Navigator.of(context);
    _dismissResultSheet(sheetContext);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    navigator.removeRoute(route);
  }

  Future<void> _retryFromResult(BuildContext sheetContext) async {
    if (_resultActionBusy) return;
    _resultActionBusy = true;

    _dismissResultSheet(sheetContext);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _reset());
  }

  Future<void> _showResult({
    required bool won,
    required int stars,
    required int reward,
    required int xp,
  }) async {
    if (_resultVisible || !mounted) return;
    _resultVisible = true;
    _resultActionBusy = false;
    _resultSheetDismissed = false;

    final skin = gameSkinById(widget.store.selectedTheme);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final worldReward = won && widget.store.lastCompletionWasWorldReward;
    final bonusCoins = won ? widget.store.lastCompletionBonus : 0;
    final bonusXp = won ? widget.store.lastCompletionBonusXp : 0;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PopScope(
        canPop: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 14,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .86,
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: won
                            ? skin.heroGradient
                            : const LinearGradient(
                                colors: [Color(0xFFFF7B7B), Color(0xFFD93654)],
                              ),
                      ),
                      child: Icon(
                        won
                            ? worldReward
                                  ? Icons.card_giftcard_rounded
                                  : Icons.location_city_rounded
                            : Icons.heart_broken_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.level.cityName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      won
                          ? worldReward
                                ? (ar ? 'تم فتح عالم جديد' : 'WORLD COMPLETE')
                                : (ar ? 'تم إكمال المدينة' : 'CITY CLEARED')
                          : (ar ? 'انتهت الحركات' : 'MISSION FAILED'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: won ? skin.primary : Colors.redAccent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (won) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Icon(
                            index < stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: index < stars
                                ? AppTheme.yellow
                                : Colors.black12,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ResultChip(
                            icon: Icons.monetization_on_rounded,
                            text: '+$reward',
                          ),
                          _ResultChip(
                            icon: Icons.bolt_rounded,
                            text: '+$xp XP',
                          ),
                          _ResultChip(
                            icon: Icons.local_fire_department_rounded,
                            text: 'x$_bestCombo',
                          ),
                          if (bonusCoins > 0)
                            _ResultChip(
                              icon: Icons.card_giftcard_rounded,
                              text: '+$bonusCoins Bonus',
                            ),
                          if (bonusXp > 0)
                            _ResultChip(
                              icon: Icons.auto_awesome_rounded,
                              text: '+$bonusXp XP',
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (!won) ...[
                      GameButton(
                        semanticLabel: ar
                            ? 'شاهد إعلانًا وخذ خمس حركات'
                            : 'Watch ad for five moves',
                        onPressed: _resultActionBusy
                            ? null
                            : () {
                                final started = _ads.showRewarded(
                                  onReward: () {
                                    if (!mounted) return;
                                    _dismissResultSheet(sheetContext);
                                    setState(() {
                                      _finished = false;
                                      _resultVisible = false;
                                      _moves += 5;
                                    });
                                  },
                                );
                                if (!started) {
                                  _message(
                                    ar
                                        ? 'الإعلان غير متاح الآن. جرّب مرة أخرى أو أعد المحاولة.'
                                        : 'Rewarded ad is not available yet. Try again or retry.',
                                  );
                                }
                              },
                        enabled: !_resultActionBusy,
                        expand: true,
                        height: 52,
                        borderRadius: BorderRadius.circular(18),
                        backgroundColor: Colors.white,
                        foregroundColor: skin.primary,
                        border: Border.all(
                          color: skin.primary.withValues(alpha: .35),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.ondemand_video_rounded),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                ar
                                    ? 'شاهد إعلانًا وخذ 5 حركات'
                                    : 'Watch ad for 5 moves',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
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
                          ? (ar
                                ? 'التالي والعودة للخريطة'
                                : 'Next and back to map')
                          : (ar ? 'إعادة المحاولة' : 'Retry'),
                      onPressed: _resultActionBusy
                          ? null
                          : () async {
                              if (won) {
                                await _closeResultAndReturnToMap(sheetContext);
                              } else {
                                await _retryFromResult(sheetContext);
                              }
                            },
                      enabled: !_resultActionBusy,
                      loading: _resultActionBusy,
                      expand: true,
                      height: 56,
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: skin.primary,
                      shadowColor: skin.primary.withValues(alpha: .38),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            won
                                ? Icons.navigate_next_rounded
                                : Icons.restart_alt_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              won
                                  ? (ar
                                        ? 'التالي — العودة للخريطة'
                                        : 'NEXT — BACK TO MAP')
                                  : (ar ? 'إعادة المحاولة' : 'RETRY'),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted && !_resultActionBusy) {
      setState(() => _resultVisible = false);
    }
  }

  @override
  void dispose() {
    final pendingFeedback = _feedbackCompleter;
    if (pendingFeedback != null && !pendingFeedback.isCompleted) {
      pendingFeedback.complete();
    }
    _ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = gameSkinById(widget.store.selectedTheme);
    final world = gameWorlds[widget.level.world - 1];
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final flight = _flight;

    return PopScope(
      canPop: !_resultVisible && !_resolving,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(widget.level.cityName),
              Text(
                '${world.name} • ${ar ? 'المرحلة' : 'Level'} ${widget.level.number}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: ar ? 'إعادة' : 'Restart',
              onPressed: _finished || _resultVisible || _resolving
                  ? null
                  : () => setState(() => _reset()),
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
        body: Stack(
          key: _motionLayerKey,
          children: [
            Container(
              decoration: BoxDecoration(gradient: skin.backgroundGradient),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxHeight < 690 ||
                        constraints.maxWidth < 370;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 9 : 14,
                        compact ? 8 : 12,
                        compact ? 9 : 14,
                        compact ? 10 : 16,
                      ),
                      child: Column(
                        children: [
                          _StatusPanel(
                            moves: _moves,
                            matched: _matchedCount,
                            total: widget.level.items.length,
                            progress: _progress,
                            combo: _combo,
                            hearts: widget.store.hearts,
                            skin: skin,
                            shieldActive: _shieldActive,
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 6 : 10),
                          Text(
                            widget.level.isBossCity
                                ? (ar
                                      ? 'مهمة مدينة الزعيم'
                                      : 'BOSS CITY MISSION')
                                : (ar ? 'رتّب كل الشحنات' : 'SORT ALL CARGO'),
                            style: TextStyle(
                              color: widget.level.isBossCity
                                  ? skin.accent
                                  : skin.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: compact ? 14 : 17,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 10),
                          Expanded(
                            flex: 3,
                            child: _CargoBoard(
                              items: _remaining,
                              selectedIndex: _selectedIndex,
                              travellingIndex: _resolving
                                  ? _selectedIndex
                                  : null,
                              onTap: _choosePackage,
                              compact: compact,
                            ),
                          ),
                          SizedBox(height: compact ? 7 : 12),
                          Expanded(
                            flex: 2,
                            child: _WarehouseBoard(
                              warehouses: _warehouses,
                              activeFlight: flight,
                              onTap: _chooseWarehouse,
                              compact: compact,
                            ),
                          ),
                          SizedBox(height: compact ? 7 : 12),
                          Row(
                            children: [
                              Expanded(
                                child: _BoosterButton(
                                  icon: Icons.lightbulb_rounded,
                                  count:
                                      widget.store.freeHints + _preparedHints,
                                  active: _selected != null,
                                  onPressed:
                                      _selected == null ||
                                          _finished ||
                                          _resolving
                                      ? null
                                      : _useHint,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: _BoosterButton(
                                  icon: Icons.add_circle_rounded,
                                  count: widget.store.extraMovesBoosters,
                                  onPressed: _finished || _resolving
                                      ? null
                                      : _useExtraMoves,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: _BoosterButton(
                                  icon: Icons.shield_rounded,
                                  count: widget.store.comboShields,
                                  active: _shieldActive,
                                  onPressed: _finished || _resolving
                                      ? null
                                      : _useComboShield,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (flight != null)
              GameTravelMotion(
                key: ValueKey(flight.id),
                start: flight.start,
                end: flight.end,
                size: 58,
                onCompleted: () => unawaited(_completeFlight(flight)),
                child: _FlightCargo(item: flight.item),
              ),
            if (_feedbackKind case final feedbackKind?)
              GameActionFeedback(
                key: ValueKey(_feedbackSequence),
                kind: feedbackKind,
                combo: _feedbackCombo,
                semanticLabel: feedbackKind == GameActionFeedbackKind.correct
                    ? (ar
                          ? 'وضع صحيح، سلسلة $_feedbackCombo'
                          : 'Correct placement, combo $_feedbackCombo')
                    : (ar ? 'وضع غير صحيح' : 'Wrong placement'),
                hapticsEnabled: widget.hapticsEnabled,
                onSound: widget.soundEnabled ? widget.onPlacementSound : null,
                onCompleted: () => _completeActionFeedback(_feedbackSequence),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18, color: AppTheme.orange),
    label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
  );
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.icon,
    required this.count,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final int count;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) => FilledButton.tonal(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_circle_rounded : icon, size: 20),
          const SizedBox(width: 5),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    ),
  );
}

class _CargoBoard extends StatelessWidget {
  const _CargoBoard({
    required this.items,
    required this.selectedIndex,
    required this.travellingIndex,
    required this.onTap,
    required this.compact,
  });

  final List<CargoItem> items;
  final int? selectedIndex;
  final int? travellingIndex;
  final void Function(CargoItem item, int index, Offset globalOrigin) onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 7 : 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: GridView.builder(
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: compact ? 6 : 9,
        mainAxisSpacing: compact ? 6 : 9,
        childAspectRatio: compact ? 1.0 : .92,
      ),
      itemBuilder: (_, index) {
        final item = items[index];
        final selectedItem = index == selectedIndex;
        final travellingItem = index == travellingIndex;
        return Builder(
          builder: (tileContext) {
            Offset? tapOrigin;
            return InkWell(
              key: ValueKey('cargo-${item.id}-$index'),
              onTapDown: (details) => tapOrigin = details.globalPosition,
              onTap: () =>
                  onTap(item, index, tapOrigin ?? _globalCenter(tileContext)),
              borderRadius: BorderRadius.circular(18),
              child: CargoMotionTile(
                selected: selectedItem,
                busy: travellingItem,
                child: Container(
                  padding: EdgeInsets.all(compact ? 5 : 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [item.accentColor, item.color],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selectedItem ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: Colors.white,
                        size: compact ? 26 : 34,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 8 : 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _WarehouseBoard extends StatelessWidget {
  const _WarehouseBoard({
    required this.warehouses,
    required this.activeFlight,
    required this.onTap,
    required this.compact,
  });

  final List<CargoItem> warehouses;
  final _CargoFlight? activeFlight;
  final void Function(CargoItem item, Offset globalDestination) onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => GridView.builder(
    itemCount: warehouses.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: min(3, warehouses.length),
      crossAxisSpacing: compact ? 6 : 9,
      mainAxisSpacing: compact ? 6 : 9,
      childAspectRatio: compact ? 1.2 : 1.05,
    ),
    itemBuilder: (_, index) {
      final item = warehouses[index];
      final active = activeFlight?.warehouse.id == item.id;
      final correct = active && activeFlight?.item.id == item.id;
      return Builder(
        builder: (tileContext) {
          Offset? tapDestination;
          return WarehouseMotionTarget(
            active: active,
            correct: correct,
            child: InkWell(
              key: ValueKey('warehouse-${item.id}'),
              onTapDown: (details) => tapDestination = details.globalPosition,
              onTap: () =>
                  onTap(item, tapDestination ?? _globalCenter(tileContext)),
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding: EdgeInsets.all(compact ? 5 : 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: item.color, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warehouse_rounded,
                      color: item.color,
                      size: compact ? 28 : 38,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.color,
                        fontSize: compact ? 8 : 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.moves,
    required this.matched,
    required this.total,
    required this.progress,
    required this.combo,
    required this.hearts,
    required this.skin,
    required this.shieldActive,
    required this.compact,
  });

  final int moves;
  final int matched;
  final int total;
  final double progress;
  final int combo;
  final int hearts;
  final GameSkin skin;
  final bool shieldActive;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 10 : 14),
    decoration: BoxDecoration(
      gradient: skin.heroGradient,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Metric(
              key: const ValueKey('game-moves'),
              icon: Icons.touch_app_rounded,
              value: '$moves',
              compact: compact,
            ),
            _Metric(
              icon: Icons.inventory_2_rounded,
              value: '$matched/$total',
              compact: compact,
            ),
            _Metric(
              icon: Icons.local_fire_department_rounded,
              value: 'x$combo',
              compact: compact,
            ),
            _Metric(
              icon: shieldActive
                  ? Icons.shield_rounded
                  : Icons.favorite_rounded,
              value: shieldActive ? 'ON' : '$hearts',
              compact: compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: compact ? 6 : 8,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(skin.accent),
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    super.key,
    required this.icon,
    required this.value,
    required this.compact,
  });
  final IconData icon;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Colors.white, size: compact ? 18 : 21),
      Text(
        value,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: compact ? 13 : 15,
        ),
      ),
    ],
  );
}

class _FlightCargo extends StatelessWidget {
  const _FlightCargo({required this.item});

  final CargoItem item;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [item.accentColor, item.color]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: item.color.withValues(alpha: .42),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Icon(item.icon, color: Colors.white, size: 32),
  );
}

class _CargoFlight {
  const _CargoFlight({
    required this.id,
    required this.item,
    required this.selectedIndex,
    required this.warehouse,
    required this.start,
    required this.end,
  });

  final int id;
  final CargoItem item;
  final int selectedIndex;
  final CargoItem warehouse;
  final Offset start;
  final Offset end;
}

Offset _globalCenter(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return Offset.zero;
  return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
}
