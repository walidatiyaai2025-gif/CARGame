import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../../core/widgets/game_button.dart';
import 'cargo_motion_tile.dart';
import 'cargo_visual_asset.dart';
import 'level_data.dart';

typedef GameplayCargoTap =
    void Function(CargoItem item, int index, Offset globalOrigin);
typedef GameplayWarehouseTap =
    void Function(CargoItem item, Offset globalDestination);

class GameplayCommandBar extends StatelessWidget {
  const GameplayCommandBar({
    super.key,
    required this.cityName,
    required this.worldName,
    required this.levelNumber,
    required this.difficulty,
    required this.compact,
    required this.isArabic,
    required this.onBack,
    required this.onRestart,
  });

  final String cityName;
  final String worldName;
  final int levelNumber;
  final int difficulty;
  final bool compact;
  final bool isArabic;
  final VoidCallback? onBack;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 7 : 10,
      vertical: compact ? 5 : 7,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF0B1423).withValues(alpha: .92),
      borderRadius: BorderRadius.circular(compact ? 20 : 24),
      border: Border.all(color: Colors.white24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        _CommandIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: isArabic ? 'رجوع' : 'Back',
          onTap: onBack,
        ),
        SizedBox(width: compact ? 7 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cityName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 17,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$worldName • ${isArabic ? 'المرحلة' : 'Level'} $levelNumber • ${isArabic ? 'صعوبة' : 'D'} $difficulty',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 7 : 10),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF20C997).withValues(alpha: .15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF20C997).withValues(alpha: .38),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 7,
                height: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF20C997),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isArabic ? 'مباشر' : 'LIVE',
                style: TextStyle(
                  color: const Color(0xFF67E8C0),
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 5 : 7),
        _CommandIconButton(
          icon: Icons.restart_alt_rounded,
          tooltip: isArabic ? 'إعادة' : 'Restart',
          onTap: onRestart,
        ),
      ],
    ),
  );
}

class _CommandIconButton extends StatelessWidget {
  const _CommandIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.white.withValues(alpha: onTap == null ? .05 : .10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 36,
          child: Icon(
            icon,
            color: onTap == null ? Colors.white24 : Colors.white,
            size: 20,
          ),
        ),
      ),
    ),
  );
}

class GameplayMissionBanner extends StatelessWidget {
  const GameplayMissionBanner({
    super.key,
    required this.isBoss,
    required this.isArabic,
    required this.selectedCargo,
    required this.resolving,
    required this.accent,
    required this.primary,
    required this.compact,
  });

  final bool isBoss;
  final bool isArabic;
  final CargoItem? selectedCargo;
  final bool resolving;
  final Color accent;
  final Color primary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final detail = resolving
        ? (isArabic ? 'جارٍ نقل الشحنة' : 'CARGO IN TRANSIT')
        : selectedCargo != null
        ? '${selectedCargo!.name} → ${selectedCargo!.category}'
        : isBoss
        ? (isArabic ? 'مهمة مدينة الزعيم' : 'BOSS CITY MISSION')
        : (isArabic ? 'رتّب كل الشحنات' : 'SORT ALL CARGO');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 13,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .90),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isArabic ? 'المهمة مباشرة' : 'MISSION LIVE',
              style: TextStyle(
                color: primary,
                fontSize: compact ? 8 : 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isBoss ? accent : AppTheme.navy,
                fontSize: compact ? 9 : 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameplayBoosterDock extends StatelessWidget {
  const GameplayBoosterDock({
    super.key,
    required this.children,
    required this.compact,
  });

  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 5 : 7),
    decoration: BoxDecoration(
      color: const Color(0xFF0B1423).withValues(alpha: .92),
      borderRadius: BorderRadius.circular(compact ? 20 : 24),
      border: Border.all(color: Colors.white24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index != children.length - 1) SizedBox(width: compact ? 5 : 7),
        ],
      ],
    ),
  );
}

class GameplayBoosterButton extends StatelessWidget {
  const GameplayBoosterButton({
    super.key,
    required this.type,
    required this.label,
    required this.count,
    required this.onPressed,
    required this.accent,
    required this.compact,
    this.active = false,
  });

  final ThreeDIconType type;
  final String label;
  final int count;
  final VoidCallback? onPressed;
  final Color accent;
  final bool compact;
  final bool active;

  @override
  Widget build(BuildContext context) => GameButton(
    semanticLabel: '$label $count',
    onPressed: onPressed,
    enabled: onPressed != null,
    height: compact ? 48 : 56,
    expand: true,
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 5 : 7,
      vertical: compact ? 4 : 6,
    ),
    borderRadius: BorderRadius.circular(compact ? 15 : 18),
    gradient: active
        ? LinearGradient(
            colors: [accent, Color.lerp(accent, AppTheme.navy, .28)!],
          )
        : null,
    backgroundColor: active ? null : Colors.white,
    foregroundColor: active ? Colors.white : AppTheme.navy,
    border: Border.all(
      color: active
          ? Colors.white.withValues(alpha: .36)
          : accent.withValues(alpha: .20),
    ),
    shadowColor: active ? accent.withValues(alpha: .32) : Colors.black12,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThreeDGameIcon(
            type: type,
            size: compact ? 25 : 29,
            semanticLabel: label,
          ),
          SizedBox(width: compact ? 3 : 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 7 : 8,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                active ? 'ON • $count' : 'x$count',
                style: TextStyle(
                  color: active ? Colors.white70 : accent,
                  fontSize: compact ? 10 : 11,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class GameplayCargoBoard extends StatelessWidget {
  const GameplayCargoBoard({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.travellingIndex,
    required this.onTap,
    required this.compact,
    required this.isArabic,
    required this.accent,
    this.levelNumber = 1,
  });

  final List<CargoItem> items;
  final int? selectedIndex;
  final int? travellingIndex;
  final GameplayCargoTap onTap;
  final bool compact;
  final bool isArabic;
  final Color accent;
  final int levelNumber;

  @override
  Widget build(BuildContext context) => Container(
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
        _BoardHeader(
          title: isArabic ? 'منطقة الشحن' : 'CARGO BAY',
          trailing: selectedIndex == null
              ? (isArabic ? 'اختر شحنة' : 'SELECT CARGO')
              : (isArabic ? 'تم الاختيار' : 'SELECTED'),
          accent: accent,
          compact: compact,
        ),
        SizedBox(height: compact ? 5 : 7),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: compact ? 6 : 9,
              mainAxisSpacing: compact ? 6 : 9,
              childAspectRatio: compact ? 1.0 : .92,
            ),
            itemBuilder: (_, index) {
              final item = items[index];
              final selectedItem = index == selectedIndex;
              final travellingItem = index == travellingIndex;
              return Builder(
                builder: (tileContext) {
                  Offset? tapOrigin;
                  return InkWell(
                    key: ValueKey('cargo-${item.id}-$index'),
                    onTapDown: (details) => tapOrigin = details.globalPosition,
                    onTap: () => onTap(
                      item,
                      index,
                      tapOrigin ?? _globalCenter(tileContext),
                    ),
                    borderRadius: BorderRadius.circular(18),
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
                          borderRadius: BorderRadius.circular(18),
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
                              width: compact ? 28 : 36,
                              height: compact ? 28 : 36,
                              fallback: Icon(
                                item.icon,
                                color: Colors.white,
                                size: compact ? 25 : 33,
                              ),
                            ),
                            const SizedBox(height: 3),
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
                            if (!compact) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.category.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class GameplayWarehouseBoard extends StatelessWidget {
  const GameplayWarehouseBoard({
    super.key,
    required this.warehouses,
    required this.activeWarehouseId,
    required this.activeCargoId,
    required this.onTap,
    required this.compact,
    required this.isArabic,
    required this.accent,
    this.levelNumber = 1,
  });

  final List<CargoItem> warehouses;
  final int? activeWarehouseId;
  final int? activeCargoId;
  final GameplayWarehouseTap onTap;
  final bool compact;
  final bool isArabic;
  final Color accent;
  final int levelNumber;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      compact ? 7 : 10,
      compact ? 6 : 9,
      compact ? 7 : 10,
      compact ? 7 : 10,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF101C2D).withValues(alpha: .94),
      borderRadius: BorderRadius.circular(compact ? 22 : 28),
      border: Border.all(color: Colors.white24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x330B1423),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        _BoardHeader(
          title: isArabic ? 'أرصفة الفرز' : 'SORTING DOCKS',
          trailing: isArabic ? 'اختر الوجهة' : 'CHOOSE DESTINATION',
          accent: accent,
          compact: compact,
          dark: true,
        ),
        SizedBox(height: compact ? 5 : 7),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: warehouses.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: math.min(3, warehouses.length),
              crossAxisSpacing: compact ? 6 : 9,
              mainAxisSpacing: compact ? 6 : 9,
              childAspectRatio: compact ? 1.2 : 1.05,
            ),
            itemBuilder: (_, index) {
              final item = warehouses[index];
              final active = activeWarehouseId == item.id;
              final correct = active && activeCargoId == item.id;
              return Builder(
                builder: (tileContext) {
                  Offset? tapDestination;
                  return WarehouseMotionTarget(
                    active: active,
                    correct: correct,
                    child: InkWell(
                      key: ValueKey('warehouse-${item.id}'),
                      onTapDown: (details) =>
                          tapDestination = details.globalPosition,
                      onTap: () => onTap(
                        item,
                        tapDestination ?? _globalCenter(tileContext),
                      ),
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        padding: EdgeInsets.all(compact ? 5 : 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Color.lerp(Colors.white, item.accentColor, .14)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: active ? item.accentColor : item.color,
                            width: active ? 4 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withValues(alpha: .16),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CargoVisualAsset(
                                  item: item,
                                  levelNumber: levelNumber,
                                  width: compact ? 30 : 40,
                                  height: compact ? 30 : 40,
                                  fallback: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: compact ? 27 : 37,
                                  ),
                                ),
                                if (active)
                                  Icon(
                                    correct
                                        ? Icons.check_circle_rounded
                                        : Icons.route_rounded,
                                    color: correct
                                        ? const Color(0xFF20A66A)
                                        : item.accentColor,
                                    size: compact ? 15 : 18,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
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
            },
          ),
        ),
      ],
    ),
  );
}

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({
    required this.title,
    required this.trailing,
    required this.accent,
    required this.compact,
    this.dark = false,
  });

  final String title;
  final String trailing;
  final Color accent;
  final bool compact;
  final bool dark;

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
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: dark ? Colors.white : AppTheme.navy,
            fontSize: compact ? 9 : 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            trailing,
            style: TextStyle(
              color: dark ? Colors.white54 : Colors.black45,
              fontSize: compact ? 7 : 8,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
            ),
          ),
        ),
      ),
    ],
  );
}

class GameplayStatusPanel extends StatelessWidget {
  const GameplayStatusPanel({
    super.key,
    required this.moves,
    required this.matched,
    required this.total,
    required this.progress,
    required this.combo,
    required this.hearts,
    required this.skin,
    required this.shieldActive,
    required this.compact,
    required this.isArabic,
  });

  final int moves;
  final int matched;
  final int total;
  final double progress;
  final int combo;
  final int hearts;
  final GameSkin skin;
  final bool shieldActive;
  final bool compact;
  final bool isArabic;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      compact ? 9 : 13,
      compact ? 8 : 11,
      compact ? 9 : 13,
      compact ? 7 : 10,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0B1423),
          Color.lerp(const Color(0xFF0B1423), skin.primary, .64)!,
          Color.lerp(skin.primary, skin.secondary, .48)!,
        ],
      ),
      borderRadius: BorderRadius.circular(compact ? 22 : 28),
      border: Border.all(color: Colors.white24),
      boxShadow: [
        BoxShadow(
          color: skin.primary.withValues(alpha: .26),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Metric(
                key: const ValueKey('game-moves'),
                icon: Icons.touch_app_rounded,
                label: isArabic ? 'حركات' : 'MOVES',
                value: '$moves',
                compact: compact,
              ),
            ),
            Expanded(
              child: _Metric(
                icon: Icons.inventory_2_rounded,
                label: isArabic ? 'شحن' : 'CARGO',
                value: '$matched/$total',
                compact: compact,
              ),
            ),
            Expanded(
              child: _Metric(
                icon: Icons.local_fire_department_rounded,
                label: isArabic ? 'كومبو' : 'COMBO',
                value: 'x$combo',
                compact: compact,
              ),
            ),
            Expanded(
              child: _Metric(
                icon: shieldActive
                    ? Icons.shield_rounded
                    : Icons.favorite_rounded,
                label: shieldActive
                    ? (isArabic ? 'درع' : 'SHIELD')
                    : (isArabic ? 'قلوب' : 'HEARTS'),
                value: shieldActive ? 'ON' : '$hearts',
                compact: compact,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: compact ? 5 : 7,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(skin.accent),
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: compact ? 16 : 19),
        SizedBox(width: compact ? 3 : 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white54,
                fontSize: compact ? 6 : 7,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: .45,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 12 : 14,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class GameplayFlightCargo extends StatelessWidget {
  const GameplayFlightCargo({
    super.key,
    required this.item,
    this.levelNumber = 1,
  });

  final CargoItem item;
  final int levelNumber;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [item.accentColor, item.color]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: item.color.withValues(alpha: .46),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: CargoVisualAsset(
      item: item,
      levelNumber: levelNumber,
      width: 42,
      height: 42,
      fallback: Icon(item.icon, color: Colors.white, size: 32),
    ),
  );
}

Offset _globalCenter(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return Offset.zero;
  return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
}
