class MissionLoadout {
  const MissionLoadout({
    this.smartHint = false,
    this.extraMoves = false,
    this.comboShield = false,
  });

  final bool smartHint;
  final bool extraMoves;
  final bool comboShield;

  static const empty = MissionLoadout();

  int get selectedCount =>
      (smartHint ? 1 : 0) +
      (extraMoves ? 1 : 0) +
      (comboShield ? 1 : 0);
}
