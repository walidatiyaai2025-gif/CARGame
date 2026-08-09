from pathlib import Path
import subprocess

path = 'lib/features/settings/settings_screen.dart'
base = subprocess.check_output(
    ['git', 'show', 'bbc2f15770362f51f97543929e9f482fff6a7fe2:' + path],
    text=True,
)
old = '''  void _showPrivacyInfo(BuildContext context, bool ar) {\n    showModalBottomSheet<void>(\n      context: context,\n      showDragHandle: true,\n      builder: (context) =>\n          _PrivacySheet(ar: ar, controller: adConsentController),\n    );\n  }\n'''
new = '''  void _showPrivacyInfo(BuildContext context, bool ar) {\n    showModalBottomSheet<void>(\n      context: context,\n      showDragHandle: true,\n      isScrollControlled: true,\n      builder: (context) => SafeArea(\n        top: false,\n        child: SingleChildScrollView(\n          child: _PrivacySheet(ar: ar, controller: adConsentController),\n        ),\n      ),\n    );\n  }\n'''
if old not in base:
    raise SystemExit('privacy modal pattern missing')
Path(path).write_text(base.replace(old, new, 1), encoding='utf-8')
