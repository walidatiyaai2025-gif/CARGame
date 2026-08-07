from pathlib import Path

main_path = Path('lib/main.dart')
main = main_path.read_text(encoding='utf-8')
main = main.replace("import 'core/logging/app_logger.dart';\n", "import 'core/ads/banner_ad_footer.dart';\nimport 'core/logging/app_logger.dart';\n", 1)
main = main.replace(
    "  runZonedGuarded<void>(() => runApp(const BootstrapApp()), (\n",
    "  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));\n  runZonedGuarded<void>(() => runApp(const BootstrapApp()), (\n",
    1,
)
old_home = """      home: MotionLifecycleScope(
        child: Stack(
          children: [
            HomeScreen(
              store: widget.store,
              settings: widget.settings,
              onToggleLanguage: _toggleLanguage,
            ),
"""
new_home = """      home: MotionLifecycleScope(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  HomeScreen(
                    store: widget.store,
                    settings: widget.settings,
                    onToggleLanguage: _toggleLanguage,
                  ),
"""
if old_home not in main:
    raise SystemExit('main home anchor missing')
main = main.replace(old_home, new_home, 1)
old_tail = """            PositionedDirectional(
              top: 66,
              end: 16,
              child: SafeArea(
                child: Material(
"""
new_tail = """                  PositionedDirectional(
                    top: 66,
                    end: 16,
                    child: SafeArea(
                      child: Material(
"""
if old_tail not in main:
    raise SystemExit('settings overlay anchor missing')
main = main.replace(old_tail, new_tail, 1)
# Close the newly introduced Expanded/Stack before the existing footer of home list.
marker = """            ),
          ],
        ),
      ),
    );
  }
}
"""
replacement = """                ],
              ),
            ),
            const BannerAdFooter(),
          ],
        ),
      ),
    );
  }
}
"""
idx = main.rfind(marker)
if idx == -1:
    raise SystemExit('main closing anchor missing')
main = main[:idx] + replacement + main[idx + len(marker):]
main_path.write_text(main, encoding='utf-8')

home_path = Path('lib/features/home/home_screen.dart')
home = home_path.read_text(encoding='utf-8')
old = """                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        10,
                        horizontal,
                        28,
                      ),
                      children: [
"""
new = """                    final heightScale =
                        (constraints.maxHeight / 820).clamp(.72, 1.0);
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        6,
                        horizontal,
                        8,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: constraints.maxWidth - (horizontal * 2),
                          height: constraints.maxHeight / heightScale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
"""
if old not in home:
    raise SystemExit('home list anchor missing')
home = home.replace(old, new, 1)
old_end = """                        const Text(
                          'Walid Atiya Ata - PMP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),
                      ],
                    );
"""
new_end = """                        const Text(
                          'Walid Atiya Ata - PMP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),
                            ],
                          ),
                        ),
                      ),
                    );
"""
if old_end not in home:
    raise SystemExit('home list close anchor missing')
home = home.replace(old_end, new_end, 1)
# Compact spacing and card dimensions for fit-first home.
for old_s, new_s in {
    "const SizedBox(height: 14),": "const SizedBox(height: 8),",
    "const SizedBox(height: 18),": "const SizedBox(height: 10),",
    "const SizedBox(height: 16),": "const SizedBox(height: 9),",
    "const SizedBox(height: 20),": "const SizedBox(height: 10),",
}.items():
    home = home.replace(old_s, new_s)
home = home.replace("vertical: 9", "vertical: 5")
home = home.replace("borderRadius: BorderRadius.circular(22)", "borderRadius: BorderRadius.circular(16)")
home = home.replace("size: compact ? 34 : 42", "size: compact ? 27 : 32")
home = home.replace("fontSize: compact ? 15 : 18", "fontSize: compact ? 13 : 15")
home = home.replace("padding: EdgeInsets.all(compact ? 18 : 24)", "padding: EdgeInsets.all(compact ? 12 : 16)")
home = home.replace("fontSize: compact ? 27 : 34", "fontSize: compact ? 22 : 27")
home = home.replace("size: compact ? 82 : 108", "size: compact ? 62 : 78")
home_path.write_text(home, encoding='utf-8')
