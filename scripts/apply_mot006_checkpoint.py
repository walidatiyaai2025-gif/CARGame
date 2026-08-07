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

old_handler = """    final selected = _selected;
    if (selected == null || _finished || _moves <= 0 || _resultVisible) return;

    final correct = selected.id == warehouse.id;
    setState(() {
      _moves--;
"""
new_handler = """    final selected = _selected;
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
if old_handler not in text:
    raise SystemExit('warehouse handler anchor missing')
text = text.replace(old_handler, new_handler, 1)
text = text.replace(
    "      _selected = null;\n    });\n\n    if (_remaining.isEmpty)",
    "      _selected = null;\n      _cargoActionBusy = false;\n      _activeWarehouseId = null;\n      _placementCorrect = false;\n    });\n\n    if (_remaining.isEmpty)",
    1,
)

text = text.replace(
    """                        child: _CargoBoard(
                          items: _remaining,
                          selected: _selected,
                          onTap: _choosePackage,
                          compact: compact,
                        ),
""",
    """                        child: _CargoBoard(
                          items: _remaining,
                          selected: _selected,
                          onTap: _choosePackage,
                          compact: compact,
                          busy: _cargoActionBusy,
                        ),
""",
    1,
)
text = text.replace(
    """                        child: _WarehouseBoard(
                          warehouses: _warehouses,
                          onTap: _chooseWarehouse,
                          compact: compact,
                        ),
""",
    """                        child: _WarehouseBoard(
                          warehouses: _warehouses,
                          onTap: _chooseWarehouse,
                          compact: compact,
                          busy: _cargoActionBusy,
                          activeWarehouseId: _activeWarehouseId,
                          placementCorrect: _placementCorrect,
                        ),
""",
    1,
)

start = text.index('class _CargoBoard extends StatelessWidget')
end = text.index('class _StatusPanel extends StatelessWidget')
boards = r'''class _CargoBoard extends StatelessWidget {
  const _CargoBoard({
    required this.items,
    required this.selected,
    required this.onTap,
    required this.compact,
    required this.busy,
  });

  final List<CargoItem> items;
  final CargoItem? selected;
  final ValueChanged<CargoItem> onTap;
  final bool compact;
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 7 : 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: GridView.builder(
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: compact ? 6 : 9,
        mainAxisSpacing: compact ? 6 : 9,
        childAspectRatio: compact ? 1.0 : .92,
      ),
      itemBuilder: (_, index) {
        final item = items[index];
        final selectedItem = identical(item, selected);
        return CargoMotionTile(
          selected: selectedItem,
          busy: busy,
          child: InkWell(
            onTap: busy ? null : () => onTap(item),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: EdgeInsets.all(compact ? 5 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [item.accentColor, item.color],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selectedItem ? Colors.white : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: Colors.white, size: compact ? 26 : 34),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 8 : 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _WarehouseBoard extends StatelessWidget {
  const _WarehouseBoard({
    required this.warehouses,
    required this.onTap,
    required this.compact,
    required this.busy,
    required this.activeWarehouseId,
    required this.placementCorrect,
  });

  final List<CargoItem> warehouses;
  final ValueChanged<CargoItem> onTap;
  final bool compact;
  final bool busy;
  final int? activeWarehouseId;
  final bool placementCorrect;

  @override
  Widget build(BuildContext context) => GridView.builder(
    itemCount: warehouses.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: min(3, warehouses.length),
      crossAxisSpacing: compact ? 6 : 9,
      mainAxisSpacing: compact ? 6 : 9,
      childAspectRatio: compact ? 1.2 : 1.05,
    ),
    itemBuilder: (_, index) {
      final item = warehouses[index];
      return WarehouseMotionTarget(
        active: activeWarehouseId == item.id,
        correct: placementCorrect,
        child: InkWell(
          onTap: busy ? null : () => onTap(item),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: EdgeInsets.all(compact ? 5 : 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: item.color, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warehouse_rounded,
                  color: item.color,
                  size: compact ? 28 : 38,
                ),
                const SizedBox(height: 3),
                Text(
                  item.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.color,
                    fontSize: compact ? 8 : 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

'''
text = text[:start] + boards + text[end:]
path.write_text(text, encoding='utf-8')
