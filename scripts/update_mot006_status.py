from pathlib import Path

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text(encoding='utf-8')
old = '| MOT-006 | Product pickup, travel, placement, settle | P0 | PLANNED | GAME-003, MOT-001 | Every gameplay action shows cause/result while board state remains deterministic. |'
new = '| MOT-006 | Product pickup, travel, placement, settle | P0 | IN PROGRESS | GAME-003, MOT-001 | Selection now lifts the cargo, placement locks repeated input, and the chosen warehouse gives correct/wrong settle feedback before deterministic state mutation. Coordinate-to-coordinate travel and physical-device review remain. |'
if old not in text:
    raise SystemExit('MOT-006 catalog row not found')
text = text.replace(old, new, 1)
text = text.replace(
    '- `MOT-003` Universal Button Motion System adoption.\n',
    '- `MOT-006` Product pickup, travel, placement, settle.\n',
    1,
)
catalog.write_text(text, encoding='utf-8')
