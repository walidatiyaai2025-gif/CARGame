import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../game/city_catalog.dart';
import '../game/level_data.dart';

typedef CapitalStarsForLevel = int Function(int levelNumber);
typedef CapitalLevelSelected = void Function(LevelData level);

class CapitalWorldMap extends StatefulWidget {
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
  State<CapitalWorldMap> createState() => _CapitalWorldMapState();
}

class _CapitalWorldMapState extends State<CapitalWorldMap> {
  static const _minScale = 1.0;
  static const _maxScale = 3.6;
  final TransformationController _controller = TransformationController();
  double _scale = _minScale;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setScale(double scale) {
    final next = scale.clamp(_minScale, _maxScale);
    _controller.value = Matrix4.identity()..scaleByDouble(next, next, 1, 1);
    setState(() => _scale = next);
  }

  void _zoomBy(double delta) => _setScale(_scale + delta);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width < 420 ? 330.0 : 410.0;
        final compact = width < 380;
        final nodeSize = compact ? 27.0 : 32.0;

        return Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD9B56B), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55031120),
                blurRadius: 26,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  boundaryMargin: const EdgeInsets.all(36),
                  onInteractionUpdate: (_) {
                    final next = _controller.value.getMaxScaleOnAxis();
                    if ((next - _scale).abs() > .01) {
                      setState(() => _scale = next);
                    }
                  },
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: SvgPicture.asset(
                            'assets/maps/world_continents_ai.svg',
                            fit: BoxFit.fill,
                            semanticsLabel: widget.isArabic
                                ? 'خريطة العالم الخيالية للقارات'
                                : 'Fantasy continent world map',
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CapitalRoutePainter(
                              levels: widget.levels,
                              highestUnlockedLevel: widget.highestUnlockedLevel,
                            ),
                          ),
                        ),
                        for (
                          var index = 0;
                          index < widget.levels.length;
                          index++
                        )
                          _positionedNode(
                            level: widget.levels[index],
                            index: index,
                            width: width,
                            height: height,
                            nodeSize: nodeSize,
                            compact: compact,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: 10,
                top: 10,
                child: _ContinentBadge(
                  isArabic: widget.isArabic,
                  highestUnlockedLevel: widget.highestUnlockedLevel,
                ),
              ),
              PositionedDirectional(
                end: 10,
                top: 10,
                child: _ZoomControls(
                  scale: _scale,
                  isArabic: widget.isArabic,
                  onZoomIn: () => _zoomBy(.45),
                  onZoomOut: () => _zoomBy(-.45),
                ),
              ),
              PositionedDirectional(
                start: 10,
                bottom: 9,
                child: _MapLegend(isArabic: widget.isArabic),
              ),
            ],
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
    final unlocked = level.number <= widget.highestUnlockedLevel;
    final completed = level.number < widget.highestUnlockedLevel;
    final current = level.number == widget.highestUnlockedLevel;
    final selected = level.number == widget.selectedLevel;

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
        stars: widget.starsForLevel(level.number),
        isArabic: widget.isArabic,
        accent: widget.accent,
        compact: compact,
        onTap: unlocked ? () => widget.onSelect(level) : null,
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

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.scale,
    required this.isArabic,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final double scale;
  final bool isArabic;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: isArabic ? 'أدوات تكبير الخريطة' : 'Map zoom controls',
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xE62B1E12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8B266)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const ValueKey('capital-map-zoom-in'),
              onPressed: scale >= _CapitalWorldMapState._maxScale
                  ? null
                  : onZoomIn,
              tooltip: isArabic ? 'تكبير' : 'Zoom in',
              icon: const Icon(Icons.add_circle, color: Color(0xFFFFD36A)),
            ),
            Text(
              '${scale.toStringAsFixed(1)}×',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            IconButton(
              key: const ValueKey('capital-map-zoom-out'),
              onPressed: scale <= _CapitalWorldMapState._minScale
                  ? null
                  : onZoomOut,
              tooltip: isArabic ? 'تصغير' : 'Zoom out',
              icon: const Icon(Icons.remove_circle, color: Color(0xFFFFD36A)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinentBadge extends StatelessWidget {
  const _ContinentBadge({
    required this.isArabic,
    required this.highestUnlockedLevel,
  });

  final bool isArabic;
  final int highestUnlockedLevel;

  @override
  Widget build(BuildContext context) {
    final chapter = ((highestUnlockedLevel - 1) ~/ 25).clamp(0, 5);
    const english = <String>[
      'North America',
      'South America',
      'Europe',
      'Africa',
      'Asia',
      'Australia',
    ];
    const arabic = <String>[
      'أمريكا الشمالية',
      'أمريكا الجنوبية',
      'أوروبا',
      'أفريقيا',
      'آسيا',
      'أستراليا',
    ];

    return IgnorePointer(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 145),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xE62B1E12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8B266)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.public_rounded,
              color: Color(0xFFFFD36A),
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isArabic ? arabic[chapter] : english[chapter],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        ? const Color(0xFF463D37)
        : completed
        ? const Color(0xFFB97A24)
        : current
        ? const Color(0xFF6E46C9)
        : const Color(0xFF3D7391);
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
                        ? const Color(0xFFFFD36A)
                        : Colors.white38,
                    width: selected ? 3 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected || current
                          ? accent.withValues(alpha: .70)
                          : Colors.black.withValues(alpha: .34),
                      blurRadius: selected || current ? 16 : 7,
                      spreadRadius: selected || current ? 3 : 0,
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
                      color: const Color(0xEB2B1E12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x66FFD36A)),
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
          color: const Color(0xE62B1E12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x66FFD36A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 12,
              color: Color(0xFFFFD36A),
            ),
            const SizedBox(width: 5),
            Text(
              isArabic ? 'كَبّرْ للاكتِشَافْ' : 'Zoom to Explore',
              style: const TextStyle(
                color: Colors.white,
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

class _CapitalRoutePainter extends CustomPainter {
  const _CapitalRoutePainter({
    required this.levels,
    required this.highestUnlockedLevel,
  });

  final List<LevelData> levels;
  final int highestUnlockedLevel;

  @override
  void paint(Canvas canvas, Size size) {
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
      final underlay = Paint()
        ..color = Colors.white.withValues(alpha: passed ? .92 : .26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = passed ? 5 : 3
        ..strokeCap = StrokeCap.round;
      final route = Paint()
        ..color = passed
            ? const Color(0xFFD94138)
            : const Color(0xFF3D3530).withValues(alpha: .58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = passed ? 2.6 : 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, underlay);
      canvas.drawLine(start, end, route);
    }
  }

  @override
  bool shouldRepaint(covariant _CapitalRoutePainter oldDelegate) {
    return oldDelegate.highestUnlockedLevel != highestUnlockedLevel ||
        oldDelegate.levels != levels;
  }
}
