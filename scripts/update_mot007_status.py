from pathlib import Path

path = Path('docs/FEATURE_CATALOG.md')
text = path.read_text(encoding='utf-8')
old = "| MOT-007 | Correct/wrong/combo feedback | P0 | PLANNED | GAME-003, MOT-001 | Sparkle, bounce, recoil, capped combo escalation, audio, and haptics are synchronized. |"
new = "| MOT-007 | Correct/wrong/combo feedback | P0 | IN PROGRESS | GAME-003, MOT-001 | Reusable synchronized correct/wrong overlay provides sparkle, bounce, recoil, capped combo escalation, one-shot haptics, Reduced Motion, guarded completion, and an optional sound hook; centralized audio-service integration and physical-device review remain. |"
if old not in text:
    raise SystemExit('MOT-007 catalog row anchor missing')
text = text.replace(old, new, 1)
path.write_text(text, encoding='utf-8')
