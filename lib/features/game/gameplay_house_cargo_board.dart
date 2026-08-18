import 'package:flutter/material.dart';

import 'cargo_motion_tile.dart';
import 'cargo_visual_asset.dart';
import 'level_data.dart';

typedef GameplayHouseCargoTap =
    void Function(CargoItem item, int index, Offset globalOrigin);

class GameplayHouseCargoBoard extends StatelessWidget {
  const GameplayHouseCargoBoard({
    super.key,
    required this.items,
    required this.houseAssignments,
    required this.houseCount,
    required this.selectedIndex,
    required this.travellingIndex,
    required this.onTap,
    required this.compact,
    required this.isArabic,
    required this.accent,
    this.levelNumber = 1,
  });

  final List<CargoItem> items;
  final List<int> houseAssignments;
  final int houseCount;
  final int? selectedIndex;
  final int? travellingIndex;
  final GameplayHouseCargoTap onTap;
  final bool compact;
  final bool isArabic;
  final Color accent;
  final int levelNumber;

  int _houseAt(int index) {
    if (houseAssignments.length != items.length) return 1;
    final value = houseAssignments[index];
    if (value < 1 || value > houseCount) return 1;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final visibleHouseCount = houseCount < 1 ? 1 : houseCount;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 7 : 10,
        compact ? 6 : 9,
        compact ? 7 : 10,
        compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDFEFF), Color(0xFFF0F4F8)],
        ),
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0B1423),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          _HouseBoardHeader(
            houseCount: visibleHouseCount,
            selected: selectedIndex != null,
            isArabic: isArabic,
            accent: accent,
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: visibleHouseCount,
              separatorBuilder: (_, __) => SizedBox(height: compact ? 6 : 8),
              itemBuilder: (context, houseOffset) {
                final houseNumber = houseOffset + 1;
                final indexes = <int>[
                  for (var index = 0; index < items.length; index++)
                    if (_houseAt(index) == houseNumber) index,
                ];

                return _CargoHouse(
                  houseNumber: houseNumber,
                  itemIndexes: indexes,
                  items: items,
                  selectedIndex: selectedIndex,
                  travellingIndex: travellingIndex,
                  onTap: onTap,
                  compact: compact,
                  isArabic: isArabic,
                  accent: accent,
                  levelNumber: levelNumber,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseBoardHeader extends StatelessWidget {
  const _HouseBoardHeader({
    required this.houseCount,
    required this.selected,
    required this.isArabic,
    required this.accent,
    required this.compact,
  });

  final int houseCount;
  final bool selected;
  final bool isArabic;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: compact ? 4 : 5,
        height: compact ? 16 : 20,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      const SizedBox(width: 6),
      Icon(
        Icons.home_work_rounded,
        color: accent,
        size: compact ? 16 : 19,
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          isArabic ? 'منطقة الشحن • البيوت' : 'CARGO BAY • HOUSES',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF0B1423),
            fontSize: compact ? 9 : 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        selected
            ? (isArabic ? 'تم الاختيار' : 'SELECTED')
            : isArabic
            ? '$houseCount بيوت'
            : '$houseCount HOUSES',
        style: TextStyle(
          color: Colors.black45,
          fontSize: compact ? 7 : 8,
          fontWeight: FontWeight.w800,
          letterSpacing: .3,
        ),
      ),
    ],
  );
}

class _CargoHouse extends StatelessWidget {
  const _CargoHouse({
    required this.houseNumber,
    required this.itemIndexes,
    required this.items,
    required this.selectedIndex,
    required this.travellingIndex,
    required this.onTap,
    required this.compact,
    required this.isArabic,
    required this.accent,
    required this.levelNumber,
  });

  final int houseNumber;
  final List<int> itemIndexes;
  final List<CargoItem> items;
  final int? selectedIndex;
  final int? travellingIndex;
  final GameplayHouseCargoTap onTap;
  final bool compact;
  final bool isArabic;
  final Color accent;
  final int levelNumber;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 6 : 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(compact ? 17 : 20),
      border: Border.all(color: accent.withValues(alpha: .16)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: compact ? 27 : 31,
              height: compact ? 24 : 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.house_rounded,
                color: accent,
                size: compact ? 16 : 19,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isArabic ? 'البيت $houseNumber' : 'HOUSE $houseNumber',
                style: TextStyle(
                  color: const Color(0xFF0B1423),
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              itemIndexes.isEmpty
                  ? (isArabic ? 'تم' : 'CLEARED')
                  : '${itemIndexes.length}',
              style: TextStyle(
                color: itemIndexes.isEmpty
                    ? const Color(0xFF20A66A)
                    : Colors.black45,
                fontSize: compact ? 8 : 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        if (itemIndexes.isNotEmpty) ...[
          SizedBox(height: compact ? 5 : 7),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemIndexes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: itemIndexes.length < 3 ? itemIndexes.length : 3,
              crossAxisSpacing: compact ? 5 : 7,
              mainAxisSpacing: compact ? 5 : 7,
              childAspectRatio: compact ? 1.0 : .92,
            ),
            itemBuilder: (context, position) {
              final index = itemIndexes[position];
              final item = items[index];
              final selectedItem = index == selectedIndex;
              final travellingItem = index == travellingIndex;

              return Builder(
                builder: (tileContext) {
                  Offset? tapOrigin;
                  return InkWell(
                    key: ValueKey('house-$houseNumber-cargo-${item.id}-$index'),
                    onTapDown: (details) => tapOrigin = details.globalPosition,
                    onTap: () => onTap(
                      item,
                      index,
                      tapOrigin ?? _globalCenter(tileContext),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: CargoMotionTile(
                      selected: selectedItem,
                      busy: travellingItem,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: EdgeInsets.all(compact ? 5 : 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [item.accentColor, item.color],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedItem
                                ? Colors.white
                                : Colors.white.withValues(alpha: .34),
                            width: selectedItem ? 3 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withValues(
                                alpha: selectedItem ? .36 : .18,
                              ),
                              blurRadius: selectedItem ? 14 : 8,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CargoVisualAsset(
                              item: item,
                              levelNumber: levelNumber,
                              width: compact ? 27 : 35,
                              height: compact ? 27 : 35,
                              fallback: Icon(
                                item.icon,
                                color: Colors.white,
                                size: compact ? 24 : 32,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 7 : 9,
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
            },
          ),
        ],
      ],
    ),
  );
}

Offset _globalCenter(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox) return Offset.zero;
  return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
}
