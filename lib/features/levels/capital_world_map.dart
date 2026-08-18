import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../game/city_catalog.dart';
import '../game/level_data.dart';

typedef CapitalStarsForLevel = int Function(int levelNumber);
typedef CapitalLevelSelected = void Function(LevelData level);

class CapitalWorldMap extends StatelessWidget {
  const CapitalWorldMap({
    super.key,
    required this.levels,
    required this.highestUnlockedLevel,
    required this.selectedLevel,
    required this.starsForLevel,
    required this.isArabic,
    required this.accent,
    required this.onSelect,
  });

  final List<LevelData> levels;
  final int highestUnlockedLevel;
  final int selectedLevel;
  final CapitalStarsForLevel starsForLevel;
  final bool isArabic;
  final Color accent;
  final CapitalLevelSelected onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width < 420 ? 310.0 : 390.0;
        final compact = width < 380;
        final nodeSize = compact ? 27.0 : 32.0;

        return Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: .72)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33031120),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 3.6,
            boundaryMargin: const EdgeInsets.all(24),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CapitalMapPainter(
                        levels: levels,
                        highestUnlockedLevel: highestUnlockedLevel,
                        accent: accent,
                      ),
                    ),
                  ),
                  for (var index = 0; index < levels.length; index++)
                    _positionedNode(
                      level: levels[index],
                      index: index,
                      width: width,
                      height: height,
                      nodeSize: nodeSize,
                      compact: compact,
                    ),
                  PositionedDirectional(
                    start: 10,
                    bottom: 9,
                    child: _MapLegend(isArabic: isArabic),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _positionedNode({
    required LevelData level,
    required int index,
    required double width,
    required double height,
    required double nodeSize,
    required bool compact,
  }) {
    final point = projectCapital(
      level.capitalStage.latitude,
      level.capitalStage.longitude,
      Size(width, height),
    );
    final offset = _collisionOffset(index);
    final unlocked = level.number <= highestUnlockedLevel;
    final completed = level.number < highestUnlockedLevel;
    final current = level.number == highestUnlockedLevel;
    final selected = level.number == selectedLevel;

    return Positioned(
      left: (point.dx + offset.dx - nodeSize / 2).clamp(
        2.0,
        width - nodeSize - 2,
      ),
      top: (point.dy + offset.dy - nodeSize / 2).clamp(
        2.0,
        height - nodeSize - 2,
      ),
      child: _CapitalNode(
        level: level,
        size: nodeSize,
        unlocked: unlocked,
        completed: completed,
        current: current,
        selected: selected,
        stars: starsForLevel(level.number),
        isArabic: isArabic,
        accent: accent,
        compact: compact,
        onTap: unlocked ? () => onSelect(level) : null,
      ),
    );
  }
}

Offset projectCapital(double latitude, double longitude, Size size) {
  final normalizedX = ((longitude + 180) / 360).clamp(0.0, 1.0);
  final normalizedY = ((82 - latitude) / 150).clamp(0.0, 1.0);
  return Offset(normalizedX * size.width, normalizedY * size.height);
}

Offset _collisionOffset(int index) {
  const offsets = <Offset>[
    Offset.zero,
    Offset(5, -5),
    Offset(-5, 5),
    Offset(7, 6),
    Offset(-7, -6),
  ];
  return offsets[index % offsets.length];
}

class _CapitalNode extends StatelessWidget {
  const _CapitalNode({
    required this.level,
    required this.size,
    required this.unlocked,
    required this.completed,
    required this.current,
    required this.selected,
    required this.stars,
    required this.isArabic,
    required this.accent,
    required this.compact,
    required this.onTap,
  });

  final LevelData level;
  final double size;
  final bool unlocked;
  final bool completed;
  final bool current;
  final bool selected;
  final int stars;
  final bool isArabic;
  final Color accent;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stage = level.capitalStage;
    final fill = !unlocked
        ? const Color(0xFF3D4858)
        : completed
        ? const Color(0xFFF2A81D)
        : current
        ? const Color(0xFF22A8E8)
        : const Color(0xFFF7C94B);
    final labelVisible = selected || current;

    return Semantics(
      button: unlocked,
      enabled: unlocked,
      selected: selected,
      label: stage.label(isArabic),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: labelVisible ? (compact ? 106 : 126) : size,
          height: labelVisible ? size + 29 : size,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : unlocked
                        ? const Color(0xFFFFE8A8)
                        : Colors.white38,
                    width: selected ? 3 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? accent.withValues(alpha: .62)
                          : Colors.black.withValues(alpha: .26),
                      blurRadius: selected ? 13 : 7,
                      spreadRadius: selected ? 2 : 0,
                    ),
                  ],
                ),
                child: !unlocked
                    ? Icon(
                        Icons.lock_rounded,
                        color: Colors.white70,
                        size: size * .47,
                      )
                    : completed
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: size * .56,
                      )
                    : Text(
                        '${level.number}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 8 : 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              if (labelVisible)
                Positioned(
                  top: size + 3,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: compact ? 104 : 124),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE60B2035),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stage.capital(isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 8 : 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          stage.country(isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: compact ? 7 : 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (unlocked && stars > 0 && !labelVisible)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD54F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 9,
                      color: Color(0xFF7D4B00),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xC70B2035),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public_rounded, size: 12, color: Colors.white70),
            const SizedBox(width: 5),
            Text(
              isArabic ? 'اسحب وكبّر الخريطة' : 'Pan & zoom map',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapitalMapPainter extends CustomPainter {
  const _CapitalMapPainter({
    required this.levels,
    required this.highestUnlockedLevel,
    required this.accent,
  });

  final List<LevelData> levels;
  final int highestUnlockedLevel;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final oceanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B9AC9), Color(0xFF0878AA), Color(0xFF054B7B)],
      ).createShader(rect);
    canvas.drawRect(rect, oceanPaint);

    _drawGrid(canvas, size);
    _drawLand(canvas, size);
    _drawRoutes(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;

    for (var longitude = -150; longitude <= 150; longitude += 30) {
      final x = ((longitude + 180) / 360) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var latitude = -60; latitude <= 60; latitude += 30) {
      final y = ((82 - latitude) / 150) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLand(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x33031E2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = const Color(0xFFE7D7A7)
      ..style = PaintingStyle.fill;
    final coast = Paint()
      ..color = const Color(0xFF55795B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    for (final polygon in _landMasses) {
      final path = Path();
      for (var index = 0; index < polygon.length; index++) {
        final point = projectCapital(
          polygon[index].latitude,
          polygon[index].longitude,
          size,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, shadow);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, coast);
    }
  }

  void _drawRoutes(Canvas canvas, Size size) {
    if (levels.length < 2) return;

    for (var index = 0; index < levels.length - 1; index++) {
      final from = levels[index];
      final to = levels[index + 1];
      final start = projectCapital(
        from.capitalStage.latitude,
        from.capitalStage.longitude,
        size,
      );
      final end = projectCapital(
        to.capitalStage.latitude,
        to.capitalStage.longitude,
        size,
      );
      final passed = to.number <= highestUnlockedLevel;
      final routePaint = Paint()
        ..color = passed
            ? const Color(0xFFFFD55C).withValues(alpha: .88)
            : const Color(0xFF0A314E).withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = passed ? 3.4 : 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CapitalMapPainter oldDelegate) {
    return oldDelegate.highestUnlockedLevel != highestUnlockedLevel ||
        oldDelegate.accent != accent ||
        oldDelegate.levels != levels;
  }
}

class _GeoPoint {
  const _GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

const _landMasses = <List<_GeoPoint>>[
  <_GeoPoint>[
    _GeoPoint(72, -168),
    _GeoPoint(70, -140),
    _GeoPoint(60, -124),
    _GeoPoint(54, -130),
    _GeoPoint(48, -124),
    _GeoPoint(32, -117),
    _GeoPoint(24, -106),
    _GeoPoint(20, -97),
    _GeoPoint(10, -85),
    _GeoPoint(18, -78),
    _GeoPoint(30, -82),
    _GeoPoint(45, -66),
    _GeoPoint(52, -55),
    _GeoPoint(62, -64),
    _GeoPoint(70, -90),
    _GeoPoint(76, -120),
  ],
  <_GeoPoint>[
    _GeoPoint(12, -81),
    _GeoPoint(9, -72),
    _GeoPoint(3, -67),
    _GeoPoint(-5, -52),
    _GeoPoint(-15, -45),
    _GeoPoint(-24, -48),
    _GeoPoint(-36, -57),
    _GeoPoint(-54, -68),
    _GeoPoint(-47, -75),
    _GeoPoint(-30, -71),
    _GeoPoint(-16, -75),
    _GeoPoint(-5, -81),
  ],
  <_GeoPoint>[
    _GeoPoint(37, -10),
    _GeoPoint(51, -10),
    _GeoPoint(59, -4),
    _GeoPoint(70, 20),
    _GeoPoint(69, 38),
    _GeoPoint(58, 42),
    _GeoPoint(48, 31),
    _GeoPoint(42, 28),
    _GeoPoint(36, 20),
    _GeoPoint(36, 8),
  ],
  <_GeoPoint>[
    _GeoPoint(37, -17),
    _GeoPoint(36, 10),
    _GeoPoint(31, 31),
    _GeoPoint(15, 43),
    _GeoPoint(12, 51),
    _GeoPoint(-4, 42),
    _GeoPoint(-18, 36),
    _GeoPoint(-35, 19),
    _GeoPoint(-29, 14),
    _GeoPoint(-12, 12),
    _GeoPoint(5, 9),
    _GeoPoint(14, -17),
    _GeoPoint(28, -13),
  ],
  <_GeoPoint>[
    _GeoPoint(76, 35),
    _GeoPoint(72, 75),
    _GeoPoint(68, 115),
    _GeoPoint(59, 142),
    _GeoPoint(48, 150),
    _GeoPoint(39, 132),
    _GeoPoint(30, 122),
    _GeoPoint(18, 109),
    _GeoPoint(8, 106),
    _GeoPoint(1, 103),
    _GeoPoint(8, 95),
    _GeoPoint(20, 88),
    _GeoPoint(24, 78),
    _GeoPoint(8, 77),
    _GeoPoint(23, 67),
    _GeoPoint(31, 55),
    _GeoPoint(40, 45),
    _GeoPoint(55, 50),
  ],
  <_GeoPoint>[
    _GeoPoint(-11, 113),
    _GeoPoint(-12, 134),
    _GeoPoint(-18, 153),
    _GeoPoint(-29, 153),
    _GeoPoint(-39, 145),
    _GeoPoint(-36, 115),
  ],
  <_GeoPoint>[
    _GeoPoint(60, -54),
    _GeoPoint(72, -48),
    _GeoPoint(82, -34),
    _GeoPoint(78, -18),
    _GeoPoint(64, -22),
  ],
  <_GeoPoint>[
    _GeoPoint(45, 141),
    _GeoPoint(40, 144),
    _GeoPoint(34, 140),
    _GeoPoint(36, 136),
  ],
  <_GeoPoint>[
    _GeoPoint(-34, 166),
    _GeoPoint(-42, 174),
    _GeoPoint(-47, 168),
    _GeoPoint(-40, 165),
  ],
];
