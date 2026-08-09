from pathlib import Path
import subprocess

path = 'lib/features/settings/settings_screen.dart'
base = subprocess.check_output(
    ['git', 'show', 'bbc2f15770362f51f97543929e9f482fff6a7fe2:' + path],
    text=True,
)
old = '''    return Padding(\n      padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),\n      child: Column(\n        mainAxisSize: MainAxisSize.min,\n        children: [\n'''
new = '''    return SafeArea(\n      top: false,\n      child: SingleChildScrollView(\n        padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),\n        child: Column(\n          mainAxisSize: MainAxisSize.min,\n          children: [\n'''
if old not in base:
    raise SystemExit('privacy sheet opening pattern missing')
base = base.replace(old, new, 1)
old_tail = '''          ],\n        ],\n      ),\n    );\n  }\n}\n\nclass _HeroHeader'''
new_tail = '''          ],\n        ),\n      ),\n    );\n  }\n}\n\nclass _HeroHeader'''
if old_tail not in base:
    raise SystemExit('privacy sheet closing pattern missing')
base = base.replace(old_tail, new_tail, 1)
Path(path).write_text(base, encoding='utf-8')
