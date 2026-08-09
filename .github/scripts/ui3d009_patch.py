from pathlib import Path

debrief_path = Path('lib/features/game/gameplay_result_debrief.dart')
debrief = debrief_path.read_text()

old_header = '''              Row(
                children: [
                  _HeaderPill(
                    icon: won
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    text: isArabic ? 'تقرير المهمة' : 'MISSION DEBRIEF',
                  ),
                  const Spacer(),
                  _HeaderPill(
                    icon: Icons.tag_rounded,
                    text: '${isArabic ? 'مرحلة' : 'LEVEL'} $levelNumber',
                  ),
                ],
              ),'''
new_header = '''              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeaderPill(
                        icon: won
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        text: isArabic ? 'تقرير المهمة' : 'MISSION DEBRIEF',
                      ),
                      const SizedBox(width: 12),
                      _HeaderPill(
                        icon: Icons.tag_rounded,
                        text: '${isArabic ? 'مرحلة' : 'LEVEL'} $levelNumber',
                      ),
                    ],
                  ),
                ),
              ),'''
if old_header not in debrief:
    raise SystemExit('debrief header row not found')
debrief = debrief.replace(old_header, new_header, 1)

old_status = '''                        Text(
                          won
                              ? worldReward
                                    ? (isArabic
                                          ? 'اكتمل العالم'
                                          : 'WORLD COMPLETE')
                                    : (isArabic
                                          ? 'تم تأمين المسار'
                                          : 'ROUTE SECURED')
                              : (isArabic
                                    ? 'المهمة متوقفة'
                                    : 'MISSION INTERRUPTED'),
                          style: TextStyle(
                            color: won ? skin.accent : const Color(0xFFFFD5DA),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),'''
new_status = '''                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            won
                                ? worldReward
                                      ? (isArabic
                                            ? 'اكتمل العالم'
                                            : 'WORLD COMPLETE')
                                      : (isArabic
                                            ? 'تم تأمين المسار'
                                            : 'ROUTE SECURED')
                                : (isArabic
                                      ? 'المهمة متوقفة'
                                      : 'MISSION INTERRUPTED'),
                            style: TextStyle(
                              color: won
                                  ? skin.accent
                                  : const Color(0xFFFFD5DA),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ),'''
if old_status not in debrief:
    raise SystemExit('debrief status label not found')
debrief = debrief.replace(old_status, new_status, 1)
debrief_path.write_text(debrief)

path = Path('lib/features/game/game_screen.dart')
text = path.read_text()

import_anchor = "import 'gameplay_operations_deck.dart';\n"
result_import = "import 'gameplay_result_debrief.dart';\n"
if result_import not in text:
    if import_anchor not in text:
        raise SystemExit('gameplay operations import anchor not found')
    text = text.replace(import_anchor, import_anchor + result_import, 1)

start_function = text.index('  Future<void> _showResult({')
show_start = text.index('    await showModalBottomSheet<void>(', start_function)
tail_marker = '\n\n    if (mounted && !_resultActionBusy) {'
show_end = text.index(tail_marker, show_start)

replacement = '''    final world = gameWorlds[widget.level.world - 1];

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
        cityName: widget.level.cityName,
        worldName: world.name,
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
        onPrimary: () async {
          if (won) {
            await _closeResultAndReturnToMap(sheetContext);
          } else {
            await _retryFromResult(sheetContext);
          }
        },
      ),
    );'''
text = text[:show_start] + replacement + text[show_end:]

result_chip_start = text.find('\nclass _ResultChip extends StatelessWidget {')
booster_start = text.find('\nclass _BoosterButton extends StatelessWidget {')
if result_chip_start == -1 or booster_start == -1 or booster_start <= result_chip_start:
    raise SystemExit('legacy result chip block not found')
text = text[:result_chip_start] + text[booster_start:]

legacy_start = text.find('\nclass _BoosterButton extends StatelessWidget {')
cargo_flight_start = text.find('\nclass _CargoFlight {')
if legacy_start == -1 or cargo_flight_start == -1 or cargo_flight_start <= legacy_start:
    raise SystemExit('superseded gameplay widget block not found')
text = text[:legacy_start] + '\n' + text[cargo_flight_start:]

global_center_start = text.find('\nOffset _globalCenter(BuildContext context) {')
if global_center_start == -1:
    raise SystemExit('legacy global-center helper not found')
text = text[:global_center_start].rstrip() + '\n'

text = text.replace("import '../../core/theme/app_theme.dart';\n", '')
text = text.replace("import '../../core/widgets/game_button.dart';\n", '')
text = text.replace("import 'cargo_motion_tile.dart';\n", '')

for obsolete in (
    '_ResultChip',
    '_BoosterButton',
    '_CargoBoard',
    '_WarehouseBoard',
    '_StatusPanel',
    '_Metric',
    '_FlightCargo',
    '_globalCenter',
):
    if obsolete in text:
        raise SystemExit(f'legacy presentation symbol still present: {obsolete}')
if 'GameplayResultDebrief(' not in text:
    raise SystemExit('result debrief was not wired')
if 'AppTheme.' in text:
    raise SystemExit('AppTheme still used; import removal unsafe')
if 'GameButton(' in text:
    raise SystemExit('GameButton still used; import removal unsafe')

path.write_text(text)
