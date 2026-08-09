from pathlib import Path

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

text = text.replace("import '../../core/theme/app_theme.dart';\n", '')
text = text.replace("import '../../core/widgets/game_button.dart';\n", '')

if '_ResultChip' in text:
    raise SystemExit('legacy result chip still present')
if 'GameplayResultDebrief(' not in text:
    raise SystemExit('result debrief was not wired')
if 'AppTheme.' in text:
    raise SystemExit('AppTheme still used; import removal unsafe')
if 'GameButton(' in text:
    raise SystemExit('GameButton still used; import removal unsafe')

path.write_text(text)
