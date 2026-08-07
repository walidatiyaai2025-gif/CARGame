from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')

old = """void main() {\n  WidgetsFlutterBinding.ensureInitialized();\n  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));\n  runZonedGuarded<void>(() => runApp(const BootstrapApp()), (\n"""
new = """Future<void> _applyImmersiveFullscreen() async {\n  try {\n    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);\n  } catch (error, stackTrace) {\n    debugPrint('Immersive fullscreen unavailable: $error\\n$stackTrace');\n  }\n}\n\nvoid main() {\n  WidgetsFlutterBinding.ensureInitialized();\n  unawaited(_applyImmersiveFullscreen());\n  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {\n    if (!systemOverlaysAreVisible) return;\n    await Future<void>.delayed(const Duration(milliseconds: 900));\n    await _applyImmersiveFullscreen();\n  });\n  WidgetsBinding.instance.addPostFrameCallback((_) {\n    unawaited(_applyImmersiveFullscreen());\n  });\n  runZonedGuarded<void>(() => runApp(const BootstrapApp()), (\n"""
if old not in text:
    raise SystemExit('main bootstrap anchor not found')
text = text.replace(old, new, 1)

old = """  void didChangeAppLifecycleState(AppLifecycleState state) {\n    if (state == AppLifecycleState.resumed &&\n        _optionalServices.snapshot(_adsServiceName).canRetry) {\n      unawaited(_initializeAdsInBackground(forceRetry: true));\n    }\n  }\n"""
new = """  void didChangeAppLifecycleState(AppLifecycleState state) {\n    if (state != AppLifecycleState.resumed) return;\n\n    unawaited(_applyImmersiveFullscreen());\n    if (_optionalServices.snapshot(_adsServiceName).canRetry) {\n      unawaited(_initializeAdsInBackground(forceRetry: true));\n    }\n  }\n"""
if old not in text:
    raise SystemExit('lifecycle anchor not found')
text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
