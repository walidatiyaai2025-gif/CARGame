from pathlib import Path

path = Path('lib/features/game/game_screen.dart')
text = path.read_text()
old = """                    label: _isArabic
                        ? 'شاهد إعلانًا وخذ ${widget.store.economy.rewardedContinueMoves} حركات'
                        : 'Watch ad for ${widget.store.economy.rewardedContinueMoves} moves',
"""
new = """                    label: _isArabic
                        ? 'شاهد إعلانًا وخذ ${widget.store.economy.rewardedContinueMoves} حركات'
                        : widget.store.economy.rewardedContinueMoves == 5
                        ? 'Watch ad for five moves'
                        : 'Watch ad for ${widget.store.economy.rewardedContinueMoves} moves',
"""
if old not in text:
    if "? 'Watch ad for five moves'" in text:
        raise SystemExit(0)
    raise SystemExit('rewarded continue semantics anchor missing')
path.write_text(text.replace(old, new, 1))
