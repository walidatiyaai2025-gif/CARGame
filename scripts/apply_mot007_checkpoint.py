from pathlib import Path

path = Path('lib/features/game/game_screen.dart')
text = path.read_text(encoding='utf-8')

text = text.replace(
    "import '../../core/motion/game_travel_motion.dart';\n",
    "import '../../core/motion/game_action_feedback.dart';\nimport '../../core/motion/game_travel_motion.dart';\n",
    1,
)

text = text.replace(
    "  int _flightSequence = 0;\n",
    "  int _flightSequence = 0;\n  GameActionFeedbackKind? _feedbackKind;\n  int _feedbackCombo = 0;\n  int _feedbackSequence = 0;\n  Completer<void>? _feedbackCompleter;\n",
    1,
)

text = text.replace(
    "    _flight = null;\n    _combo = 0;\n",
    "    _flight = null;\n    _feedbackKind = null;\n    _feedbackCombo = 0;\n    final pendingFeedback = _feedbackCompleter;\n    if (pendingFeedback != null && !pendingFeedback.isCompleted) {\n      pendingFeedback.complete();\n    }\n    _feedbackCompleter = null;\n    _combo = 0;\n",
    1,
)

old = """  Future<void> _completeFlight(_CargoFlight flight) async {
    if (!mounted || _flight?.id != flight.id) return;

    final correct = flight.item.id == flight.warehouse.id;
    setState(() {
      _moves--;
"""
new = """  Future<void> _completeFlight(_CargoFlight flight) async {
    if (!mounted || _flight?.id != flight.id) return;

    final correct = flight.item.id == flight.warehouse.id;
    final feedbackCompleter = Completer<void>();
    final feedbackSequence = ++_feedbackSequence;
    _feedbackCompleter = feedbackCompleter;
    setState(() {
      _moves--;
"""
if old not in text:
    raise SystemExit('complete flight anchor missing')
text = text.replace(old, new, 1)

old_end = """      _flight = null;
      _resolving = false;
    });

    if (_remaining.isEmpty) {
"""
new_end = """      _flight = null;
      _feedbackKind = correct
          ? GameActionFeedbackKind.correct
          : GameActionFeedbackKind.wrong;
      _feedbackCombo = correct ? _combo : 0;
    });

    await feedbackCompleter.future;
    if (!mounted || feedbackSequence != _feedbackSequence) return;
    _resolving = false;

    if (_remaining.isEmpty) {
"""
if old_end not in text:
    raise SystemExit('flight completion end anchor missing')
text = text.replace(old_end, new_end, 1)

insert_before_finish = """  Future<void> _finishWin() async {
"""
feedback_method = """  void _completeActionFeedback(int sequence) {
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
"""
if insert_before_finish not in text:
    raise SystemExit('finish win anchor missing')
text = text.replace(insert_before_finish, feedback_method, 1)

old_dispose = """  @override
  void dispose() {
    _ads.dispose();
    super.dispose();
  }
"""
new_dispose = """  @override
  void dispose() {
    final pendingFeedback = _feedbackCompleter;
    if (pendingFeedback != null && !pendingFeedback.isCompleted) {
      pendingFeedback.complete();
    }
    _ads.dispose();
    super.dispose();
  }
"""
if old_dispose not in text:
    raise SystemExit('dispose anchor missing')
text = text.replace(old_dispose, new_dispose, 1)

old_flight_overlay = """            if (flight != null)
              GameTravelMotion(
                key: ValueKey(flight.id),
                start: flight.start,
                end: flight.end,
                size: 58,
                onCompleted: () => unawaited(_completeFlight(flight)),
                child: _FlightCargo(item: flight.item),
              ),
"""
new_flight_overlay = """            if (flight != null)
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
                onCompleted: () =>
                    _completeActionFeedback(_feedbackSequence),
              ),
"""
if old_flight_overlay not in text:
    raise SystemExit('flight overlay anchor missing')
text = text.replace(old_flight_overlay, new_flight_overlay, 1)

path.write_text(text, encoding='utf-8')
