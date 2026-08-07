from pathlib import Path

main_path = Path('lib/main.dart')
main = main_path.read_text(encoding='utf-8')
main = main.replace(
    "  runZonedGuarded<void>(() => runApp(const BootstrapApp()), (\n",
    "  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));\n  runZonedGuarded<void>(() => runApp(const BootstrapApp()), (\n",
    1,
)
main_path.write_text(main, encoding='utf-8')

home_path = Path('lib/features/home/home_screen.dart')
home = home_path.read_text(encoding='utf-8')
home = home.replace(
    "import '../../core/logging/log_viewer_screen.dart';\n",
    "import '../../core/ads/banner_ad_footer.dart';\nimport '../../core/logging/log_viewer_screen.dart';\n",
    1,
)
home = home.replace(
    "    return Scaffold(\n      body: AnimatedBuilder(\n",
    "    return Scaffold(\n      bottomNavigationBar: const BannerAdFooter(),\n      body: AnimatedBuilder(\n",
    1,
)
old = """                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        10,
                        horizontal,
                        28,
                      ),
                      children: [
"""
new = """                    return Padding(
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
for old_s, new_s in {
    "const SizedBox(height: 14),": "const SizedBox(height: 8),",
    "const SizedBox(height: 18),": "const SizedBox(height: 10),",
    "const SizedBox(height: 16),": "const SizedBox(height: 9),",
    "const SizedBox(height: 20),": "const SizedBox(height: 10),",
}.items():
    home = home.replace(old_s, new_s)
home = home.replace("vertical: 9", "vertical: 5")
home = home.replace(
    "borderRadius: BorderRadius.circular(22)",
    "borderRadius: BorderRadius.circular(16)",
)
home = home.replace("size: compact ? 34 : 42", "size: compact ? 27 : 32")
home = home.replace(
    "fontSize: compact ? 15 : 18",
    "fontSize: compact ? 13 : 15",
)
home = home.replace(
    "padding: EdgeInsets.all(compact ? 18 : 24)",
    "padding: EdgeInsets.all(compact ? 12 : 16)",
)
home = home.replace(
    "fontSize: compact ? 27 : 34",
    "fontSize: compact ? 22 : 27",
)
home = home.replace("size: compact ? 82 : 108", "size: compact ? 62 : 78")
home_path.write_text(home, encoding='utf-8')
