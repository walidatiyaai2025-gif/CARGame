#!/usr/bin/env python3
from pathlib import Path

path = Path('lib/features/game/game_screen.dart')
text = path.read_text()

if 'final ActiveRunPersistence? activeRunPersistence;' in text:
    print('GAME-015 GameScreen wiring already applied.')
    raise SystemExit(0)


def replace_once(old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'expected one match, found {count}: {old[:100]!r}')
    text = text.replace(old, new, 1)


replace_once(
    "import 'city_catalog.dart';\nimport 'gameplay_house_cargo_board.dart';",
    "import 'active_run_coordinator.dart';\nimport 'active_run_session.dart';\nimport 'active_run_store.dart';\nimport 'city_catalog.dart';\nimport 'gameplay_house_cargo_board.dart';",
)
replace_once(
    "    this.onPlacementSound,\n  });",
    "    this.onPlacementSound,\n    this.activeRunPersistence,\n  });",
)
replace_once(
    "  final GameActionFeedbackSoundHook? onPlacementSound;\n",
    "  final GameActionFeedbackSoundHook? onPlacementSound;\n  final ActiveRunPersistence? activeRunPersistence;\n",
)
replace_once(
    "  bool _manualPaused = false;\n  bool _lifecyclePaused = false;\n",
    "  bool _manualPaused = false;\n  bool _lifecyclePaused = false;\n  late ActiveRunCoordinator _activeRunCoordinator;\n  bool _runReady = false;\n  bool _abandonBusy = false;\n",
)
replace_once(
    "    _ads.preload();\n    _reset(applyLoadout: true);\n  }",
    "    _ads.preload();\n    _reset(applyLoadout: true);\n    _activeRunCoordinator = _createActiveRunCoordinator();\n    unawaited(_initializeActiveRun());\n  }",
)
replace_once(
    "  @override\n  void didChangeAppLifecycleState(AppLifecycleState state) {\n    final shouldPause = state != AppLifecycleState.resumed;\n    if (_lifecyclePaused == shouldPause || !mounted) return;\n    setState(() => _lifecyclePaused = shouldPause);\n  }\n\n  void _pauseManually() {",
    "  @override\n  void didChangeAppLifecycleState(AppLifecycleState state) {\n    final shouldPause = state != AppLifecycleState.resumed;\n    if (_lifecyclePaused == shouldPause || !mounted) return;\n    if (shouldPause && _runReady && !_finished) {\n      unawaited(_checkpointActiveRun());\n    }\n    setState(() => _lifecyclePaused = shouldPause);\n  }\n\n  ActiveRunCoordinator _createActiveRunCoordinator() => ActiveRunCoordinator(\n    level: widget.level,\n    store: widget.activeRunPersistence,\n  );\n\n  Future<void> _initializeActiveRun() async {\n    ActiveRunSession? restored;\n    try {\n      restored = await _activeRunCoordinator.restore();\n    } catch (_) {\n      // Persistence failure must not block the offline core game. A clean\n      // attempt remains playable, while durable rewards/economy stay separate.\n    }\n    if (!mounted) return;\n\n    setState(() {\n      if (restored != null) _applyActiveRunSession(restored!);\n      _runReady = true;\n    });\n\n    if (restored == null) {\n      await _checkpointActiveRun();\n    }\n  }\n\n  void _applyActiveRunSession(ActiveRunSession session) {\n    _remaining = List<CargoItem>.of(session.remaining);\n    _remainingHouses = List<int>.of(session.remainingHouses);\n    _moves = session.movesRemaining;\n    _combo = session.combo;\n    _bestCombo = session.bestCombo;\n    _preparedHints = session.preparedHints;\n    _shieldActive = session.shieldActive;\n    _madeWrongMove = session.madeWrongMove;\n    _rewardTransactionId = session.rewardTransactionId;\n    _selected = null;\n    _selectedIndex = null;\n    _selectedOrigin = null;\n    _flight = null;\n    _feedbackKind = null;\n    _feedbackCombo = 0;\n    final pendingFeedback = _feedbackCompleter;\n    if (pendingFeedback != null && !pendingFeedback.isCompleted) {\n      pendingFeedback.complete();\n    }\n    _feedbackCompleter = null;\n    _finished = false;\n    _resultActionBusy = false;\n    _resultVisible = false;\n    _resultSheetDismissed = false;\n    _resolving = false;\n    _manualPaused = false;\n  }\n\n  ActiveRunSession _currentActiveRunSession() => ActiveRunSession(\n    remaining: List<CargoItem>.unmodifiable(_remaining),\n    remainingHouses: List<int>.unmodifiable(_remainingHouses),\n    movesRemaining: _moves,\n    combo: _combo,\n    bestCombo: _bestCombo,\n    preparedHints: _preparedHints,\n    shieldActive: _shieldActive,\n    madeWrongMove: _madeWrongMove,\n    rewardTransactionId: _rewardTransactionId,\n  );\n\n  Future<void> _checkpointActiveRun() async {\n    if (!_runReady || _finished || _remaining.isEmpty || _moves <= 0) return;\n    try {\n      await _activeRunCoordinator.checkpoint(_currentActiveRunSession());\n    } catch (_) {\n      // Checkpoint I/O is best-effort: never mutate durable reward/economy\n      // truth and never block current offline gameplay on storage failure.\n    }\n  }\n\n  Future<void> _restartRun() async {\n    if (!_runReady || _finished || _resultVisible || _resolving || _isPaused) {\n      return;\n    }\n    try {\n      await _activeRunCoordinator.clearForRestartOrAbandon();\n    } catch (_) {\n      if (mounted) _showActiveRunSafetyMessage();\n      return;\n    }\n    if (!mounted) return;\n    setState(() => _reset());\n    await _checkpointActiveRun();\n  }\n\n  Future<void> _abandonRun() async {\n    if (!_runReady ||\n        _abandonBusy ||\n        _finished ||\n        _resultVisible ||\n        _resolving ||\n        _isPaused ||\n        !Navigator.of(context).canPop()) {\n      return;\n    }\n    setState(() => _abandonBusy = true);\n    try {\n      await _activeRunCoordinator.clearForRestartOrAbandon();\n    } catch (_) {\n      if (mounted) {\n        setState(() => _abandonBusy = false);\n        _showActiveRunSafetyMessage();\n      }\n      return;\n    }\n    if (!mounted) return;\n    Navigator.of(context).pop();\n  }\n\n  void _showActiveRunSafetyMessage() {\n    final ar = Localizations.localeOf(context).languageCode == 'ar';\n    _message(\n      ar\n          ? 'تعذر حفظ حالة المهمة بأمان. حاول مرة أخرى.'\n          : 'Could not safely update the mission checkpoint. Try again.',\n    );\n  }\n\n  void _pauseManually() {",
)
replace_once(
    "    if (_isPaused || _finished || _moves <= 0 || _resultVisible || _resolving) {",
    "    if (!_runReady ||\n        _abandonBusy ||\n        _isPaused ||\n        _finished ||\n        _moves <= 0 ||\n        _resultVisible ||\n        _resolving) {",
)
replace_once(
    "    if (_isPaused ||\n        selected == null ||",
    "    if (!_runReady ||\n        _abandonBusy ||\n        _isPaused ||\n        selected == null ||",
)
replace_once(
    "    });\n\n    await feedbackCompleter.future;\n",
    "    });\n\n    if (_remaining.isNotEmpty && _moves > 0) {\n      await _checkpointActiveRun();\n    }\n\n    await feedbackCompleter.future;\n",
)
replace_once(
    "  Future<void> _finishWin() async {\n    if (_finished) return;\n    _finished = true;\n\n    final stars = _earnedStars;",
    "  Future<void> _finishWin() async {\n    if (_finished) return;\n    _finished = true;\n    await _activeRunCoordinator.clearTerminal();\n\n    final stars = _earnedStars;",
)
replace_once(
    "  Future<void> _finishLoss() async {\n    if (_finished) return;\n    _finished = true;\n    await widget.store.loseHeart();",
    "  Future<void> _finishLoss() async {\n    if (_finished) return;\n    _finished = true;\n    await _activeRunCoordinator.clearTerminal();\n    await widget.store.loseHeart();",
)
replace_once(
    "  Future<void> _useHint() async {\n    final selected = _selected;\n    if (_isPaused || selected == null || _finished) return;\n\n    if (_preparedHints > 0) {\n      setState(() => _preparedHints--);\n      _message('${selected.name} → ${selected.category} warehouse');",
    "  Future<void> _useHint() async {\n    final selected = _selected;\n    if (!_runReady || _isPaused || selected == null || _finished) return;\n\n    if (_preparedHints > 0) {\n      setState(() => _preparedHints--);\n      await _checkpointActiveRun();\n      _message('${selected.name} → ${selected.category} warehouse');",
)
replace_once(
    "  Future<void> _useExtraMoves() async {\n    if (_isPaused || _finished) return;",
    "  Future<void> _useExtraMoves() async {\n    if (!_runReady || _isPaused || _finished) return;",
)
replace_once(
    "    setState(() => _moves += extraMoves);\n    _message('+$extraMoves moves added.');",
    "    setState(() => _moves += extraMoves);\n    await _checkpointActiveRun();\n    _message('+$extraMoves moves added.');",
)
replace_once(
    "  Future<void> _useComboShield() async {\n    if (_isPaused || _finished) return;",
    "  Future<void> _useComboShield() async {\n    if (!_runReady || _isPaused || _finished) return;",
)
replace_once(
    "    setState(() => _shieldActive = true);\n    _message('Combo shield activated.');",
    "    setState(() => _shieldActive = true);\n    await _checkpointActiveRun();\n    _message('Combo shield activated.');",
)
replace_once(
    "    if (!mounted) return;\n    setState(() => _reset());\n  }\n\n  Future<void> _showResult({",
    "    if (!mounted) return;\n    setState(() {\n      _activeRunCoordinator = _createActiveRunCoordinator();\n      _reset();\n    });\n    await _checkpointActiveRun();\n  }\n\n  Future<void> _showResult({",
)
replace_once(
    "                    setState(() {\n                      _finished = false;\n                      _resultVisible = false;\n                      _moves += 5;\n                    });",
    "                    setState(() {\n                      _activeRunCoordinator = _createActiveRunCoordinator();\n                      _finished = false;\n                      _resultVisible = false;\n                      _moves += 5;\n                    });\n                    unawaited(_checkpointActiveRun());",
)
replace_once(
    "    _ads.dispose();\n    super.dispose();",
    "    unawaited(_activeRunCoordinator.flush().catchError((Object _) {}));\n    _ads.dispose();\n    super.dispose();",
)
replace_once(
    "    return PopScope(\n      canPop: !_resultVisible && !_resolving && !_isPaused,\n      child: Scaffold(",
    "    final canAbandon =\n        canGoBack &&\n        _runReady &&\n        !_abandonBusy &&\n        !_finished &&\n        !_resultVisible &&\n        !_resolving &&\n        !_isPaused;\n\n    return PopScope(\n      canPop: false,\n      onPopInvokedWithResult: (didPop, result) {\n        if (!didPop && canAbandon) unawaited(_abandonRun());\n      },\n      child: Scaffold(",
)
replace_once(
    "        body: TickerMode(\n          enabled: !_isPaused,",
    "        body: TickerMode(\n          enabled: _runReady && !_isPaused,",
)
replace_once(
    "                            onBack:\n                                !canGoBack ||\n                                    _resultVisible ||\n                                    _resolving ||\n                                    _isPaused\n                                ? null\n                                : () => Navigator.maybePop(context),\n                            onRestart:\n                                _finished ||\n                                    _resultVisible ||\n                                    _resolving ||\n                                    _isPaused\n                                ? null\n                                : () => setState(() => _reset()),",
    "                            onBack: !canAbandon\n                                ? null\n                                : () => unawaited(_abandonRun()),\n                            onRestart:\n                                !_runReady ||\n                                    _abandonBusy ||\n                                    _finished ||\n                                    _resultVisible ||\n                                    _resolving ||\n                                    _isPaused\n                                ? null\n                                : () => unawaited(_restartRun()),",
)
replace_once(
    "                        onPressed: _isPaused ? null : _pauseManually,",
    "                        onPressed: !_runReady || _abandonBusy || _isPaused\n                            ? null\n                            : _pauseManually,",
)
replace_once(
    "              if (_isPaused)\n                Positioned.fill(",
    "              if (!_runReady)\n                Positioned.fill(\n                  child: AbsorbPointer(\n                    child: ColoredBox(\n                      key: const ValueKey('game-active-run-restoring'),\n                      color: const Color(0xD90A1220),\n                      child: Center(\n                        child: Column(\n                          mainAxisSize: MainAxisSize.min,\n                          children: [\n                            const CircularProgressIndicator(),\n                            const SizedBox(height: 14),\n                            Text(\n                              ar\n                                  ? 'جارٍ استعادة المهمة بأمان…'\n                                  : 'Restoring mission safely…',\n                              style: const TextStyle(\n                                color: Colors.white,\n                                fontWeight: FontWeight.w800,\n                              ),\n                            ),\n                          ],\n                        ),\n                      ),\n                    ),\n                  ),\n                ),\n              if (_isPaused)\n                Positioned.fill(",
)

path.write_text(text)
print('GAME-015 GameScreen lifecycle wiring applied.')
