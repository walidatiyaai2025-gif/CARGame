import re
from pathlib import Path

text = Path('docs/FEATURE_CATALOG.md').read_text(encoding='utf-8')
rows = {}
phase = None
for line in text.splitlines():
    m = re.match(r'^# ([A-S])\. ', line)
    if m:
        phase = m.group(1)
        continue
    if not line.startswith('| ') or line.startswith('| ID ') or line.startswith('|---'):
        continue
    cols = [c.strip() for c in line.strip().strip('|').split('|')]
    if len(cols) != 6 or not re.fullmatch(r'[A-Z][A-Z0-9]*-\d{3}', cols[0]):
        continue
    rows[cols[0]] = {
        'id': cols[0], 'name': cols[1], 'priority': cols[2], 'status': cols[3],
        'deps': cols[4], 'phase': phase,
    }

# Evaluate as the post-reconciliation state without mutating the catalog yet.
rows['ADS-007']['status'] = 'IMPLEMENTED'
satisfied = {'VERIFIED', 'IMPLEMENTED'}

def dep_ids(raw):
    if raw == 'None':
        return []
    return re.findall(r'[A-Z][A-Z0-9]*-\d{3}', raw)

ready = []
for item in rows.values():
    if item['status'] not in {'PLANNED', 'READY'}:
        continue
    deps = dep_ids(item['deps'])
    # Human aggregate dependencies (for example "All P0 release blockers") are not auto-ready.
    if item['deps'] != 'None' and not deps:
        continue
    if all(rows.get(d, {}).get('status') in satisfied for d in deps):
        ready.append(item)

ready.sort(key=lambda x: (int(x['priority'][1]), x['phase'] or 'Z', x['id']))
print('POST-ADS-007 DEPENDENCY-READY CANDIDATES')
for item in ready[:30]:
    deps = ','.join(dep_ids(item['deps'])) or 'None'
    print(f"{item['priority']} | {item['phase']} | {item['id']} | {item['name']} | deps={deps}")

print('\nP0 READY')
for item in ready:
    if item['priority'] == 'P0':
        print(f"{item['phase']} | {item['id']} | {item['name']} | deps={item['deps']}")
