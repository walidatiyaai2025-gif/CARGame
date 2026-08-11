from pathlib import Path

path = Path('test/core/settings/visual_effects_preference_scope_test.dart')
text = path.read_text(encoding='utf-8')
text = text.replace(
    "import 'package:flutter_test/flutter_test.dart';\n",
    "import 'package:flutter_test/flutter_test.dart';\nimport 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';\nimport 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';\n",
    1,
)
text = text.replace(
    "void main() {\n",
    "void main() {\n  setUp(() {\n    SharedPreferencesAsyncPlatform.instance =\n        InMemorySharedPreferencesAsync.empty();\n  });\n\n",
    1,
)
path.write_text(text, encoding='utf-8')
print('UI3D-007 bootstrap fixture fix applied')
