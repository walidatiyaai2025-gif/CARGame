from pathlib import Path

path = Path('lib/features/game/game_screen.dart')
text = path.read_text(encoding='utf-8')

text = text.replace(
    "import '../../core/ads/ad_service.dart';\n",
    "import '../../core/ads/ad_service.dart';\nimport '../../core/motion/game_motion.dart';\n",
    1,
)
text = text.replace(
    "import 'city_catalog.dart';\n",
    "import 'cargo_motion_tile.dart';\nimport 'city_catalog.dart';\n",
    1,
)
text = text.replace(
    "  bool _resultVisible = false;\n",
    "  bool _resultVisible = false;\n  bool _cargoActionBusy = false;\n  int? _activeWarehouseId;\n  bool _placementCorrect = false;\n",
    1,
)
text = text.replace(
    "    _resultVisible = false;\n  }\n",
    "    _resultVisible = false;\n    _cargoActionBusy = false;\n    _activeWarehouseId = null;\n    _placementCorrect = false;\n  }\n",
    1,
)
text = text.replace(
    "    if (_finished || _moves <= 0 || _resultVisible) return;\n",
    "    if (_finished || _moves <= 0 || _resultVisible || _cargoActionBusy) {\n      return;\n    }\n",
    1,
)
old = """    final selected = _selected;
    if (selected == null || _finished || _moves <= 0 || _resultVisible) return;

    final correct = selected.id == warehouse.id;
    setState(() {
      _moves--;
"""
new = """    final selected = _selected;
    if (selected == null ||
        _finished ||
        _moves <= 0 ||
        _resultVisible ||
        _cargoActionBusy) {
      return;
    }

    final correct = selected.id == warehouse.id;
    final motion = GameMotion.of(context);
    setState(() {
      _cargoActionBusy = true;
      _activeWarehouseId = warehouse.id;
      _placementCorrect = correct;
    });
    await Future<void>.delayed(
      motion.duration(GameMotionDurations.standard),
    );
    if (!mounted) return;

    setState(() {
      _moves--;
"""
if old not in text:
    raise SystemExit('warehouse handler anchor missing')
text = text.replace(old, new, 1)
text = text.replace(
    "      _selected = null;\n    });\n\n    if (_remaining.isEmpty)",
    "      _selected = null;\n      _cargoActionBusy = false;\n      _activeWarehouseId = null;\n      _placementCorrect = false;\n    });\n\n    if (_remaining.isEmpty)",
    1,
)
text = text.replace(
    "                          compact: compact,\n                        ),\n",
    "                          compact: compact,\n                          busy: _cargoActionBusy,\n                        ),\n",
    1,
)
text = text.replace(
    "                          compact: compact,\n                        ),\n                      ),\n                      SizedBox(height: compact ? 7 : 12),\n",
    "                          compact: compact,\n                          busy: _cargoActionBusy,\n                          activeWarehouseId: _activeWarehouseId,\n                          placementCorrect: _placementCorrect,\n                        ),\n                      ),\n                      SizedBox(height: compact ? 7 : 12),\n",
    1,
)
text = text.replace(
    "    required this.compact,\n  });\n\n  final List<CargoItem> items;",
    "    required this.compact,\n    required this.busy,\n  });\n\n  final List<CargoItem> items;",
    1,
)
text = text.replace(
    "  final bool compact;\n\n  @override\n  Widget build(BuildContext context) => Container(",
    "  final bool compact;\n  final bool busy;\n\n  @override\n  Widget build(BuildContext context) => Container(",
    1,
)
old_tile = """        return InkWell(
          onTap: () => onTap(item),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedScale(
            scale: selectedItem ? 1.05 : 1,
            duration: const Duration(milliseconds: 150),
            child: Container(
"""
new_tile = """        return CargoMotionTile(
          selected: selectedItem,
          busy: busy,
          child: InkWell(
            onTap: busy ? null : () => onTap(item),
            borderRadius: BorderRadius.circular(18),
            child: Container(
"""
if old_tile not in text:
    raise SystemExit('cargo tile anchor missing')
text = text.replace(old_tile, new_tile, 1)
text = text.replace(
    "              ),\n            ),\n          ),\n        );\n",
    "              ),\n            ),\n          ),\n        );\n",
    1,
)
# Remove one obsolete AnimatedScale closing level from cargo tile block.
text = text.replace(
    "              ),\n            ),\n          ),\n        );\n      },\n    ),\n  );\n}\n\nclass _WarehouseBoard",
    "              ),\n            ),\n          ),\n        );\n      },\n    ),\n  );\n}\n\nclass _WarehouseBoard",
    1,
)
text = text.replace(
    "    required this.compact,\n  });\n\n  final List<CargoItem> warehouses;",
    "    required this.compact,\n    required this.busy,\n    required this.activeWarehouseId,\n    required this.placementCorrect,\n  });\n\n  final List<CargoItem> warehouses;",
    1,
)
text = text.replace(
    "  final bool compact;\n\n  @override\n  Widget build(BuildContext context) => GridView.builder(",
    "  final bool compact;\n  final bool busy;\n  final int? activeWarehouseId;\n  final bool placementCorrect;\n\n  @override\n  Widget build(BuildContext context) => GridView.builder(",
    1,
)
old_warehouse = """      return InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
"""
new_warehouse = """      return WarehouseMotionTarget(
        active: activeWarehouseId == item.id,
        correct: placementCorrect,
        child: InkWell(
          onTap: busy ? null : () => onTap(item),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
"""
if old_warehouse not in text:
    raise SystemExit('warehouse tile anchor missing')
text = text.replace(old_warehouse, new_warehouse, 1)
# Add the extra wrapper close for WarehouseMotionTarget.
anchor = """          ),
        ),
      );
    },
  );
}

class _StatusPanel"""
replacement = """          ),
        ),
      );
    },
  );
}

class _StatusPanel"""
# Formatting will validate wrapper balance; keep replacement explicit for anchor validation.
if anchor not in text:
    raise SystemExit('warehouse closing anchor missing')

path.write_text(text, encoding='utf-8')
