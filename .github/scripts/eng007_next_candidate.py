from pathlib import Path
import re

text = Path('docs/FEATURE_CATALOG.md').read_text(encoding='utf-8')
phase = None
order = 0
features = []
for line in text.splitlines():
    m = re.match(r'^#\s+([A-Z])\.\s+(.+)$', line)
    if m:
        phase = m.group(1)
        continue
    if not phase or not line.startswith('|'):
        continue
    cells = [c.replace('`','').strip() for c in line.split('|')[1:-1]]
    if len(cells) < 6 or cells[0] == 'ID' or re.fullmatch(r'[-:]+', cells[0] or '-'):
        continue
    if not re.fullmatch(r'[A-Z][A-Z0-9]*-\d{3}', cells[0]):
        continue
    order += 1
    features.append({'phase': phase, 'id': cells[0], 'name': cells[1], 'priority': cells[2], 'status': cells[3].upper(), 'deps': cells[4], 'order': order})

by_id = {f['id']: f for f in features}
ready = []
for f in features:
    if f['status'] not in {'PLANNED', 'READY'}:
        continue
    deps = re.findall(r'[A-Z][A-Z0-9]*-\d{3}', f['deps'])
    if all(by_id.get(d, {}).get('status') in {'IMPLEMENTED', 'VERIFIED'} for d in deps):
        ready.append(f)

rank = {'P0': 0, 'P1': 1, 'P2': 2, 'P3': 3}
ready.sort(key=lambda f: (rank.get(f['priority'], 9), f['order']))
print('Top dependency-ready planned features:')
for f in ready[:20]:
    print(f"{f['priority']} | {f['phase']} | {f['id']} | {f['name']} | deps={f['deps']}")
