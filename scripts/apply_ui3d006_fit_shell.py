from pathlib import Path

home_path = Path('lib/features/home/home_screen.dart')
home = home_path.read_text(encoding='utf-8')
home = home.replace(
    "import '../../core/widgets/game_button.dart';\n",
    "import '../../core/widgets/game_button.dart';\nimport '../../core/widgets/game_fit_view.dart';\n",
    1,
)
home_start = """                    return Padding(
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
"""
home_new_start = """                    return GameFitView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        6,
                        horizontal,
                        8,
                      ),
                      child: SizedBox(
"""
if home_start not in home:
    raise SystemExit('home fit anchor missing')
home = home.replace(home_start, home_new_start, 1)
home_end = """                            ],
                          ),
                        ),
                      ),
                    );
"""
home_new_end = """                            ],
                          ),
                        ),
                    );
"""
if home_end not in home:
    raise SystemExit('home fit close anchor missing')
home = home.replace(home_end, home_new_end, 1)
home_path.write_text(home, encoding='utf-8')

brief_path = Path('lib/features/levels/city_briefing_screen.dart')
brief = brief_path.read_text(encoding='utf-8')
brief = brief.replace(
    "import '../../core/widgets/game_button.dart';\n",
    "import '../../core/widgets/game_button.dart';\nimport '../../core/widgets/game_fit_view.dart';\n",
    1,
)
brief_start = """                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        12,
                        horizontal,
                        28,
                      ),
                      children: [
"""
brief_new_start = """                  Expanded(
                    child: GameFitView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        8,
                        horizontal,
                        10,
                      ),
                      child: SizedBox(
                        width: constraints.maxWidth - (horizontal * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
"""
if brief_start not in brief:
    raise SystemExit('brief list anchor missing')
brief = brief.replace(brief_start, brief_new_start, 1)
brief_end = """                      ],
                    ),
                  ),
                ],
"""
brief_new_end = """                          ],
                        ),
                      ),
                    ),
                  ),
                ],
"""
if brief_end not in brief:
    raise SystemExit('brief list close anchor missing')
brief = brief.replace(brief_end, brief_new_end, 1)
brief = brief.replace("const SizedBox(height: 18),", "const SizedBox(height: 10),", 1)
brief = brief.replace("const SizedBox(height: 20),", "const SizedBox(height: 10),", 1)
brief = brief.replace("const SizedBox(height: 24),", "const SizedBox(height: 12),", 1)
brief = brief.replace("fontSize: 22,", "fontSize: 18,", 1)
brief_path.write_text(brief, encoding='utf-8')

catalog_path = Path('docs/FEATURE_CATALOG.md')
catalog = catalog_path.read_text(encoding='utf-8')
old_row = '| UI3D-006 | Responsive screen shell and safe areas | P0 | PLANNED | UI3D-001 | Narrow phones, tall phones, tablets, large text, RTL/LTR, keyboard, and cutouts pass. |'
new_row = '| UI3D-006 | Responsive screen shell and safe areas | P0 | IN PROGRESS | UI3D-001 | Shared `GameFitView` keeps bounded screens visible without scroll and is adopted by Home and Mission Briefing; 360x640/412x915 regression coverage, tablets, large text, keyboard, cutouts, and remaining short screens still require validation. |'
if old_row in catalog:
    catalog = catalog.replace(old_row, new_row, 1)
elif '| UI3D-006 | Responsive screen shell and safe areas | P0 | IN PROGRESS |' not in catalog:
    raise SystemExit('UI3D-006 catalog row missing')
catalog_path.write_text(catalog, encoding='utf-8')

status_path = Path('docs/STATUS.md')
status = status_path.read_text(encoding='utf-8')
entry = '''\n## UI3D-006 fit shell checkpoint — 2026-08-07\n\n- Added reusable `GameFitView` for bounded game screens that must remain fully visible without a scroll container.\n- Home now uses the shared fit primitive instead of a screen-local FittedBox implementation.\n- Mission Briefing replaces its ListView with the shared fit primitive and tighter vertical rhythm while preserving boosters, wallet, RTL/LTR, SafeArea, and guarded mission launch.\n- UI3D-006 remains IN PROGRESS until remaining short screens and large-text/tablet/cutout cases are migrated and verified.\n'''
if '## UI3D-006 fit shell checkpoint — 2026-08-07' not in status:
    status = status.rstrip() + '\n' + entry
status_path.write_text(status, encoding='utf-8')
