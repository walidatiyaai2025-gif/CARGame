import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/ads/ad_service.dart';
import '../../core/economy/economy_config.dart';
import '../../core/motion/ambient_motion_background.dart';
import '../../core/motion/game_action_feedback.dart';
import '../../core/motion/game_travel_motion.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/game_skin.dart';
import '../../core/theme/three_d_game_icon.dart';
import 'active_run_coordinator.dart';
import 'active_run_session.dart';
import 'active_run_store.dart';
import 'city_catalog.dart';
import 'gameplay_house_cargo_board.dart';
import 'gameplay_operations_deck.dart';
import 'gameplay_result_debrief.dart';
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
    this.activeRunPersistence,
  });

  final LevelData level;
  final ProgressStore store;
  final MissionLoadout loadout;
  final AdService? adService;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final GameActionFeedbackSoundHook? onPlacementSound;
  final ActiveRunPersistence? activeRunPersistence;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final AdService _ads;
  final GlobalKey _motionLayerKey = GlobalKey();

  late List<CargoItem> _remaining;
  late List<int> _remainingHouses;
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
  bool _manualPaused = false;
  bool _lifecyclePaused = false;
  late ActiveRunCoordinator _activeRunCoordinator;
  bool _runReady = false;
  bool _abandonBusy = false;

  bool get _isPaused => _manualPaused || _lifecyclePaused;
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
    WidgetsBinding.instance.addObserver(this);
    _ads = widget.adService ?? AdService();
    _ads.preload();
    _reset(applyLoadout: true);
    _activeRunCoordinator = _createActiveRunCoordinator();
    unawaited(_initializeActiveRun());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldPause = state != AppLifecycleState.resumed;
    if (_lifecyclePaused == shouldPause || !mounted) return;
    if (shouldPause && _runReady && !_finished) {
      unawaited(_checkpointActiveRun());
    }
    setState(() => _lifecyclePaused = shouldPause);
  }

  ActiveRunCoordinator _createActiveRunCoordinator() => ActiveRunCoordinator(
    level: widget.level,
    store: widget.activeRunPersistence,
  );

  Future<void> _initializeActiveRun() async {
    ActiveRunSession? restored;
    try {
      restored = await _activeRunCoordinator.restore();
    } catch (_) {
      // Persistence failure must not block the offline core game. A clean
      // attempt remains playable, while durable rewards/economy stay separate.
    }
    if (!mounted) return;

    setState(() {
      if (restored != null) _applyActiveRunSession(restored);
      _runReady = true;
    });

    if (restored == null) {
      await _checkpointActiveRun();
    }
  }

  void _applyActiveRunSession(ActiveRunSession session) {
    _remaining = List<CargoItem>.of(session.remaining);
    _remainingHouses = List<int>.of(session.remainingHouses);
    _moves = session.movesRemaining;
    _combo = session.combo;
    _bestCombo = session.bestCombo;
    _preparedHints = session.preparedHints;
    _shieldActive = session.shieldActive;
    _madeWrongMove = session.madeWrongMove;
    _rewardTransactionId = session.rewardTransactionId;
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
    _finished = false;
    _resultActionBusy = false;
    _resultVisible = false;
    _resultSheetDismissed = false;
    _resolving = false;
    _manualPaused = false;
  }

  ActiveRunSession _currentActiveRunSession() => ActiveRunSession(
    remaining: List<CargoItem>.unmodifiable(_remaining),
    remainingHouses: List<int>.unmodifiable(_remainingHouses),
    movesRemaining: _moves,
    combo: _combo,
    bestCombo: _bestCombo,
    preparedHints: _preparedHints,
    shieldActive: _shieldActive,
    madeWrongMove: _madeWrongMove,
    rewardTransactionId: _rewardTransactionId,
  );

  Future<void> _checkpointActiveRun() async {
    if (!_runReady || _finished || _remaining.isEmpty || _moves <= 0) return;
    try {
      await _activeRunCoordinator.checkpoint(_currentActiveRunSession());
    } catch (_) {
      // Checkpoint I/O is best-effort: never mutate durable reward/economy
      // truth and never block current offline gameplay on storage failure.
    }
  }

  Future<void> _restartRun() async {
    if (!_runReady || _finished || _resultVisible || _resolving || _isPaused) {
      return;
    }
    try {
      await _activeRunCoordinator.clearForRestartOrAbandon();
    } catch (_) {
      if (mounted) _showActiveRunSafetyMessage();
      return;
    }
    if (!mounted) return;
    setState(() => _reset());
    await _checkpointActiveRun();
  }

  Future<void> _abandonRun() async {
    if (!_runReady ||
        _abandonBusy ||
        _finished ||
        _resultVisible ||
        _resolving ||
        _isPaused ||
        !Navigator.of(context).canPop()) {
      return;
    }
    setState(() => _abandonBusy = true);
    try {
      await _activeRunCoordinator.clearForRestartOrAbandon();
    } catch (_) {
      if (mounted) {
        setState(() => _abandonBusy = false);
        _showActiveRunSafetyMessage();
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showActiveRunSafetyMessage() {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    _message(
      ar
          ? 'تعذر حفظ حالة المهمة بأمان. حاول مرة أخرى.'
          : 'Could not safely update the mission checkpoint. Try again.',
    );
  }

  void _pauseManually() {
    if (_manualPaused || _finished || _resultVisible) return;
    setState(() => _manualPaused = true);
  }

  void _resumeManually() {
    if (!_manualPaused) return;
    setState(() => _manualPaused = false);
  }

  void _reset({bool applyLoadout = false}) {
    _rewardTransactionId =
        'level-${widget.level.number}-attempt-${DateTime.now().toUtc().microsecondsSinceEpoch}-${_rewardAttemptSequence++}';
    final placements = List.generate(
      widget.level.items.length,
      (index) => (
        item: widget.level.items[index],
        house: widget.level.houseForItemIndex(index),
      ),
    )..shuffle(Random(widget.level.number * 41));
    _remaining = [for (final placement in placements) placement.item];
    _remainingHouses = [for (final placement in placements) placement.house];
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
    if (!_runReady ||
        _abandonBusy ||
        _isPaused ||
        _finished ||
        _moves <= 0 ||
        _resultVisible ||
        _resolving) {
      return;
    }
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
    if (!_runReady ||
        _abandonBusy ||
        _isPaused ||
        selected == null ||
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
          _remainingHouses.removeAt(flight.selectedIndex);
        } else {
          final fallbackIndex = _remaining.indexOf(flight.item);
          if (fallbackIndex >= 0) {
            _remaining.removeAt(fallbackIndex);
            _remainingHouses.removeAt(fallbackIndex);
          }
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

    if (_remaining.isNotEmpty && _moves > 0) {
      await _checkpointActiveRun();
    }

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
    await _activeRunCoordinator.clearTerminal();

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
    await _activeRunCoordinator.clearTerminal();
    await widget.store.loseHeart();
    await widget.store.recordLoss();
    if (!mounted) return;
    await _showResult(won: false, stars: 0, reward: 0, xp: 0);
  }

  Future<void> _useHint() async {
    final selected = _selected;
    if (!_runReady || _isPaused || selected == null || _finished) return;

    if (_preparedHints > 0) {
      setState(() => _preparedHints--);
      await _checkpointActiveRun();
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
    if (!mounted || _isPaused) return;
    if (!used) {
      _message('Not enough coins or hints.');
      return;
    }
    _message('${selected.name} → ${selected.category} warehouse');
  }

  Future<void> _useExtraMoves() async {
    if (!_runReady || _isPaused || _finished) return;
    final used = await widget.store.useExtraMoves();
    if (!mounted || _isPaused) return;
    if (!used) {
      _message('No extra-moves boosters available.');
      return;
    }
    final extraMoves = EconomyConfig.current.gameplay.extraMovesPerBooster;
    setState(() => _moves += extraMoves);
    await _checkpointActiveRun();
    _message('+$extraMoves moves added.');
  }

  Future<void> _useComboShield() async {
    if (!_runReady || _isPaused || _finished) return;
    if (_shieldActive) {
      _message('Combo shield is already active.');
      return;
    }
    final used = await widget.store.useComboShield();
    if (!mounted || _isPaused) return;
    if (!used) {
      _message('No combo shields available.');
      return;
    }
    setState(() => _shieldActive = true);
    await _checkpointActiveRun();
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
    setState(() {
      _activeRunCoordinator = _createActiveRunCoordinator();
      _reset();
    });
    await _checkpointActiveRun();
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

    final routeName = capitalRouteForWorld(widget.level.world).name(ar);

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GameplayResultDebrief(
        won: won,
        worldReward: worldReward,
        isArabic: ar,
        busy: _resultActionBusy,
        cityName: widget.level.localizedDestinationLabel(ar),
        worldName: routeName,
        levelNumber: widget.level.number,
        stars: stars,
        reward: reward,
        xp: xp,
        bestCombo: _bestCombo,
        bonusCoins: bonusCoins,
        bonusXp: bonusXp,
        skin: skin,
        onWatchRewarded: won
            ? null
            : () {
                final started = _ads.showRewarded(
                  onReward: () {
                    if (!mounted) return;
                    _dismissResultSheet(sheetContext);
                    setState(() {
                      _activeRunCoordinator = _createActiveRunCoordinator();
                      _finished = false;
                      _resultVisible = false;
                      _moves += 5;
                    });
                    unawaited(_checkpointActiveRun());
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
        onPrimary: () async {
          if (won) {
            await _closeResultAndReturnToMap(sheetContext);
          } else {
            await _retryFromResult(sheetContext);
          }
        },
      ),
    );

    if (mounted && !_resultActionBusy) {
      setState(() => _resultVisible = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final pendingFeedback = _feedbackCompleter;
    if (pendingFeedback != null && !pendingFeedback.isCompleted) {
      pendingFeedback.complete();
    }
    unawaited(_activeRunCoordinator.flush().catchError((Object _) {}));
    _ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = gameSkinById(widget.store.selectedTheme);
    final world = gameWorlds[widget.level.world - 1];
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final routeName = capitalRouteForWorld(widget.level.world).name(ar);
    final flight = _flight;
    final canGoBack = Navigator.of(context).canPop();

    final canAbandon =
        canGoBack &&
        _runReady &&
        !_abandonBusy &&
        !_finished &&
        !_resultVisible &&
        !_resolving &&
        !_isPaused;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && canAbandon) unawaited(_abandonRun());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: TickerMode(
          enabled: _runReady && !_isPaused,
          child: Stack(
            key: _motionLayerKey,
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
                          const Color(0xFF091321).withValues(alpha: .82),
                          const Color(0xFFF4F7FB).withValues(alpha: .82),
                          const Color(0xFFF4F7FB).withValues(alpha: .97),
                        ],
                        stops: const [0, .31, 1],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxHeight < 690 ||
                        constraints.maxWidth < 370;
                    final horizontal = compact ? 9.0 : 14.0;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        compact ? 6 : 9,
                        horizontal,
                        compact ? 8 : 12,
                      ),
                      child: Column(
                        children: [
                          GameplayCommandBar(
                            cityName: widget.level.localizedDestinationLabel(
                              ar,
                            ),
                            worldName: routeName,
                            levelNumber: widget.level.number,
                            difficulty: widget.level.difficulty,
                            compact: compact,
                            isArabic: ar,
                            onBack: !canAbandon
                                ? null
                                : () => unawaited(_abandonRun()),
                            onRestart:
                                !_runReady ||
                                    _abandonBusy ||
                                    _finished ||
                                    _resultVisible ||
                                    _resolving ||
                                    _isPaused
                                ? null
                                : () => unawaited(_restartRun()),
                          ),
                          SizedBox(height: compact ? 6 : 9),
                          GameplayStatusPanel(
                            moves: _moves,
                            matched: _matchedCount,
                            total: widget.level.items.length,
                            progress: _progress,
                            combo: _combo,
                            hearts: widget.store.hearts,
                            skin: skin,
                            shieldActive: _shieldActive,
                            compact: compact,
                            isArabic: ar,
                          ),
                          SizedBox(height: compact ? 5 : 8),
                          GameplayMissionBanner(
                            isBoss: widget.level.isBossCity,
                            isArabic: ar,
                            selectedCargo: _selected,
                            resolving: _resolving,
                            accent: skin.accent,
                            primary: skin.primary,
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 5 : 8),
                          Expanded(
                            flex: 3,
                            child: GameplayHouseCargoBoard(
                              levelNumber: widget.level.number,
                              items: _remaining,
                              houseAssignments: _remainingHouses,
                              houseCount: widget.level.houseCount,
                              selectedIndex: _selectedIndex,
                              travellingIndex: _resolving
                                  ? _selectedIndex
                                  : null,
                              onTap: _choosePackage,
                              compact: compact,
                              isArabic: ar,
                              accent: skin.primary,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 9),
                          Expanded(
                            flex: 2,
                            child: GameplayWarehouseBoard(
                              levelNumber: widget.level.number,
                              warehouses: _warehouses,
                              activeWarehouseId: flight?.warehouse.id,
                              activeCargoId: flight?.item.id,
                              onTap: _chooseWarehouse,
                              compact: compact,
                              isArabic: ar,
                              accent: skin.primary,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 9),
                          GameplayBoosterDock(
                            compact: compact,
                            children: [
                              GameplayBoosterButton(
                                type: ThreeDIconType.hint,
                                label: ar ? 'تلميح' : 'HINT',
                                count: widget.store.freeHints + _preparedHints,
                                active: _selected != null,
                                accent: const Color(0xFFFFB300),
                                compact: compact,
                                onPressed:
                                    _selected == null ||
                                        _finished ||
                                        _resolving ||
                                        _isPaused
                                    ? null
                                    : _useHint,
                              ),
                              GameplayBoosterButton(
                                type: ThreeDIconType.extraMoves,
                                label: ar ? 'حركات' : 'MOVES',
                                count: widget.store.extraMovesBoosters,
                                accent: const Color(0xFF2D6CDF),
                                compact: compact,
                                onPressed: _finished || _resolving || _isPaused
                                    ? null
                                    : _useExtraMoves,
                              ),
                              GameplayBoosterButton(
                                type: ThreeDIconType.shield,
                                label: ar ? 'درع' : 'SHIELD',
                                count: widget.store.comboShields,
                                active: _shieldActive,
                                accent: const Color(0xFF7B3FF2),
                                compact: compact,
                                onPressed: _finished || _resolving || _isPaused
                                    ? null
                                    : _useComboShield,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (!_finished && !_resultVisible)
                SafeArea(
                  child: Align(
                    alignment: ar ? Alignment.topLeft : Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton.filledTonal(
                        key: const ValueKey('game-pause-button'),
                        tooltip: ar ? 'إيقاف مؤقت' : 'Pause',
                        onPressed: !_runReady || _abandonBusy || _isPaused
                            ? null
                            : _pauseManually,
                        icon: const Icon(Icons.pause_rounded),
                      ),
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
                  child: GameplayFlightCargo(
                    item: flight.item,
                    levelNumber: widget.level.number,
                  ),
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
              if (!_runReady)
                Positioned.fill(
                  child: AbsorbPointer(
                    child: ColoredBox(
                      key: const ValueKey('game-active-run-restoring'),
                      color: const Color(0xD90A1220),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 14),
                            Text(
                              ar
                                  ? 'جارٍ استعادة المهمة بأمان…'
                                  : 'Restoring mission safely…',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isPaused)
                Positioned.fill(
                  child: ColoredBox(
                    key: const ValueKey('game-pause-overlay'),
                    color: const Color(0xB30A1220),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Card(
                          margin: const EdgeInsets.all(24),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pause_circle_rounded,
                                  size: 54,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  ar ? 'اللعبة متوقفة مؤقتًا' : 'Game paused',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _lifecyclePaused
                                      ? (ar
                                            ? 'ستستأنف اللعبة بأمان عند العودة للتطبيق.'
                                            : 'Gameplay will resume safely when the app is active again.')
                                      : (ar
                                            ? 'الحركات والأنيميشن معطلة حتى الاستئناف.'
                                            : 'Moves and motion are frozen until you resume.'),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                FilledButton.icon(
                                  key: const ValueKey('game-resume-button'),
                                  onPressed: _lifecyclePaused
                                      ? null
                                      : _resumeManually,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(ar ? 'استئناف' : 'Resume'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
