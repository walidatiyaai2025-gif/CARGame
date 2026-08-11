from pathlib import Path

path = Path('test/core/motion/ui3d_007_visual_effects_test.dart')
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
text = text.replace(
    "    expect(constrained.shadow(12), 7.8);\n    expect(reduced.shadow(12), 4.2);\n",
    "    expect(constrained.shadow(12), closeTo(7.8, 1e-9));\n    expect(reduced.shadow(12), closeTo(4.2, 1e-9));\n",
    1,
)
path.write_text(text, encoding='utf-8')
print('UI3D-007 focused visual policy tests fixed')
