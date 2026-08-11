from pathlib import Path

motion_path = Path('test/core/motion/ui3d_007_visual_effects_test.dart')
motion = motion_path.read_text(encoding='utf-8')
motion = motion.replace(
    "import 'package:flutter_test/flutter_test.dart';\n",
    "import 'package:flutter_test/flutter_test.dart';\nimport 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';\nimport 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';\n",
    1,
)
motion = motion.replace(
    "void main() {\n",
    "void main() {\n  setUp(() {\n    SharedPreferencesAsyncPlatform.instance =\n        InMemorySharedPreferencesAsync.empty();\n  });\n\n",
    1,
)
motion = motion.replace(
    "    expect(constrained.shadow(12), 7.8);\n    expect(reduced.shadow(12), 4.2);\n",
    "    expect(constrained.shadow(12), closeTo(7.8, 1e-9));\n    expect(reduced.shadow(12), closeTo(4.2, 1e-9));\n",
    1,
)
motion_path.write_text(motion, encoding='utf-8')

settings_path = Path('test/features/settings/visual_effects_settings_test.dart')
settings = settings_path.read_text(encoding='utf-8')
settings = settings.replace(
    "import 'package:flutter/material.dart';\nimport 'package:flutter_test/flutter_test.dart';\n",
    "import 'package:flutter/material.dart';\nimport 'package:flutter_localizations/flutter_localizations.dart';\nimport 'package:flutter_test/flutter_test.dart';\nimport 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';\nimport 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';\n",
    1,
)
settings = settings.replace(
    "void main() {\n",
    "void main() {\n  setUp(() {\n    SharedPreferencesAsyncPlatform.instance =\n        InMemorySharedPreferencesAsync.empty();\n  });\n\n",
    1,
)
settings = settings.replace(
    "          supportedLocales: const [Locale('en'), Locale('ar')],\n          home: SettingsScreen(\n",
    "          supportedLocales: const [Locale('en'), Locale('ar')],\n          localizationsDelegates: const [\n            GlobalMaterialLocalizations.delegate,\n            GlobalWidgetsLocalizations.delegate,\n            GlobalCupertinoLocalizations.delegate,\n          ],\n          home: SettingsScreen(\n",
    1,
)
settings_path.write_text(settings, encoding='utf-8')
print('UI3D-007 focused visual policy and Settings tests fixed')
