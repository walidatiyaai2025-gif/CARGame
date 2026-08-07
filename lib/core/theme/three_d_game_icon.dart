import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets/game_manifest_asset_view.dart';

enum ThreeDIconType {
  heart,
  coin,
  star,
  gift,
  hint,
  extraMoves,
  shield,
  chest,
  city,
  boss,
}

class ThreeDGameIcon extends StatefulWidget {
  const ThreeDGameIcon({
    super.key,
    required this.type,
    this.size = 48,
    this.animate = false,
    this.semanticLabel,
  });

  final ThreeDIconType type;
  final double size;
  final bool animate;
  final String? semanticLabel;

  @override
  State<ThreeDGameIcon> createState() => _ThreeDGameIconState();
}

class _ThreeDGameIconState extends State<ThreeDGameIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ThreeDGameIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _manifestAssetId => switch (widget.type) {
    ThreeDIconType.heart => 'ui.heart',
    ThreeDIconType.coin => 'ui.coin',
    ThreeDIconType.star => 'ui.star',
    _ => null,
  };

  Widget _proceduralIcon() => SizedBox.square(
    dimension: widget.size,
    child: CustomPaint(painter: _ThreeDIconPainter(widget.type)),
  );

  @override
  Widget build(BuildContext context) {
    final procedural = _proceduralIcon();
    final assetId = _manifestAssetId;
    final visual = assetId == null
        ? procedural
        : GameManifestAssetView(
            assetId: assetId,
            width: widget.size,
            height: widget.size,
            semanticLabel: widget.semanticLabel ?? widget.type.name,
            fallback: procedural,
            errorFallback: procedural,
          );

    return Semantics(
      label: widget.semanticLabel ?? widget.type.name,
      image: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final lift = widget.animate
              ? math.sin(_controller.value * math.pi) * 3
              : 0.0;
          final scale = widget.animate ? 1 + _controller.value * .035 : 1.0;
          return Transform.translate(
            offset: Offset(0, -lift),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: ExcludeSemantics(child: visual),
      ),
    );
  }
}

class _ThreeDIconPainter extends CustomPainter {
  const _ThreeDIconPainter(this.type);

  final ThreeDIconType type;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintShadow(canvas, rect);

    switch (type) {
      case ThreeDIconType.heart:
        _paintHeart(canvas, rect);
        break;
      case ThreeDIconType.coin:
        _paintCoin(canvas, rect);
        break;
      case ThreeDIconType.star:
        _paintStar(canvas, rect);
        break;
      case ThreeDIconType.gift:
        _paintGift(canvas, rect);
        break;
      case ThreeDIconType.hint:
        _paintHint(canvas, rect);
        break;
      case ThreeDIconType.extraMoves:
        _paintExtraMoves(canvas, rect);
        break;
      case ThreeDIconType.shield:
        _paintShield(canvas, rect);
        break;
      case ThreeDIconType.chest:
        _paintChest(canvas, rect, false);
        break;
      case ThreeDIconType.city:
        _paintCity(canvas, rect);
        break;
      case ThreeDIconType.boss:
        _paintChest(canvas, rect, true);
        break;
    }

    _paintGloss(canvas, rect);
  }

  void _paintShadow(Canvas canvas, Rect rect) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom - rect.height * .08),
        width: rect.width * .72,
        height: rect.height * .19,
      ),
      Paint()
        ..color = const Color(0x39000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * .07),
    );
  }

  Paint _gradient(
    Rect rect,
    List<Color> colors, {
    Alignment begin = Alignment.topLeft,
  }) {
    return Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect);
  }

  void _paintHeart(Canvas canvas, Rect rect) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.bottom * .88)
      ..cubicTo(
        rect.left + rect.width * .08,
        rect.height * .61,
        rect.left,
        rect.height * .34,
        rect.left + rect.width * .25,
        rect.height * .22,
      )
      ..cubicTo(
        rect.width * .43,
        rect.height * .14,
        rect.center.dx,
        rect.height * .28,
        rect.center.dx,
        rect.height * .28,
      )
      ..cubicTo(
        rect.width * .58,
        rect.height * .13,
        rect.width * .83,
        rect.height * .14,
        rect.width * .93,
        rect.height * .34,
      )
      ..cubicTo(
        rect.width,
        rect.height * .58,
        rect.width * .76,
        rect.height * .73,
        rect.center.dx,
        rect.bottom * .88,
      )
      ..close();
    canvas.drawPath(
      path,
      _gradient(rect, const [
        Color(0xFFFF6B75),
        Color(0xFFE31845),
        Color(0xFF9C0E2E),
      ]),
    );
  }

  void _paintCoin(Canvas canvas, Rect rect) {
    final coin = Rect.fromCenter(
      center: rect.center,
      width: rect.width * .78,
      height: rect.height * .78,
    );
    canvas.drawOval(
      coin.shift(Offset(0, rect.height * .06)),
      Paint()..color = const Color(0xFFB96A00),
    );
    canvas.drawOval(
      coin,
      _gradient(coin, const [
        Color(0xFFFFF18A),
        Color(0xFFFFC107),
        Color(0xFFE48900),
      ]),
    );
    canvas.drawOval(
      coin.deflate(rect.width * .09),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * .055
        ..color = const Color(0xFFFFE66A),
    );
    _text(canvas, 'C', rect.center, rect.width * .38, const Color(0xFF9F5A00));
  }

  void _paintStar(Canvas canvas, Rect rect) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? rect.width * .44 : rect.width * .20;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point =
          rect.center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path.shift(Offset(0, rect.height * .05)),
      Paint()..color = const Color(0xFFB66B00),
    );
    canvas.drawPath(
      path,
      _gradient(rect, const [
        Color(0xFFFFF38B),
        Color(0xFFFFC400),
        Color(0xFFF28B00),
      ]),
    );
  }

  void _paintGift(Canvas canvas, Rect rect) {
    final box = Rect.fromLTWH(
      rect.width * .17,
      rect.height * .34,
      rect.width * .66,
      rect.height * .53,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(rect.width * .09)),
      _gradient(box, const [Color(0xFFFF6F61), Color(0xFFD91F3C)]),
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.width * .43, box.top, rect.width * .14, box.height),
      Paint()..color = const Color(0xFFFFD54F),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.width * .11,
          rect.height * .28,
          rect.width * .78,
          rect.height * .17,
        ),
        Radius.circular(rect.width * .07),
      ),
      _gradient(rect, const [Color(0xFFFF8A65), Color(0xFFE53935)]),
    );
    _paintBow(canvas, rect);
  }

  void _paintBow(Canvas canvas, Rect rect) {
    final paint = _gradient(rect, const [Color(0xFFFFF176), Color(0xFFFFB300)]);
    canvas.drawOval(
      Rect.fromLTWH(
        rect.width * .23,
        rect.height * .09,
        rect.width * .29,
        rect.height * .25,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        rect.width * .48,
        rect.height * .09,
        rect.width * .29,
        rect.height * .25,
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(rect.center.dx, rect.height * .25),
      rect.width * .10,
      Paint()..color = const Color(0xFFFFC107),
    );
  }

  void _paintHint(Canvas canvas, Rect rect) {
    final bulb = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.height * .42),
      width: rect.width * .56,
      height: rect.height * .58,
    );
    canvas.drawOval(
      bulb,
      _gradient(bulb, const [
        Color(0xFFFFFFB0),
        Color(0xFFFFD21F),
        Color(0xFFFF8F00),
      ]),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.width * .37,
          rect.height * .67,
          rect.width * .26,
          rect.height * .18,
        ),
        Radius.circular(rect.width * .05),
      ),
      _gradient(rect, const [Color(0xFF90A4AE), Color(0xFF455A64)]),
    );
    for (var i = 0; i < 3; i++) {
      final angle = i * math.pi / 2;
      final start =
          rect.center +
          Offset(math.cos(angle), math.sin(angle)) * rect.width * .38;
      final end =
          rect.center +
          Offset(math.cos(angle), math.sin(angle)) * rect.width * .48;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFFFC107)
          ..strokeWidth = rect.width * .045
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintExtraMoves(Canvas canvas, Rect rect) {
    final ticket = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.width * .07,
        rect.height * .22,
        rect.width * .86,
        rect.height * .61,
      ),
      Radius.circular(rect.width * .13),
    );
    canvas.drawRRect(
      ticket,
      _gradient(rect, const [
        Color(0xFFFFD54F),
        Color(0xFFFF9800),
        Color(0xFFE65100),
      ]),
    );
    canvas.drawRRect(
      ticket,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * .055
        ..color = const Color(0xFFFFF59D),
    );
    _text(canvas, '+5', rect.center, rect.width * .37, Colors.white);
  }

  void _paintShield(Canvas canvas, Rect rect) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.height * .08)
      ..lineTo(rect.width * .85, rect.height * .22)
      ..lineTo(rect.width * .78, rect.height * .67)
      ..quadraticBezierTo(
        rect.center.dx,
        rect.height * .92,
        rect.center.dx,
        rect.height * .94,
      )
      ..quadraticBezierTo(
        rect.width * .22,
        rect.height * .67,
        rect.width * .15,
        rect.height * .22,
      )
      ..close();
    canvas.drawPath(
      path,
      _gradient(rect, const [
        Color(0xFFF5F7FA),
        Color(0xFF90A4AE),
        Color(0xFF263238),
      ]),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * .055
        ..color = Colors.white70,
    );
  }

  void _paintChest(Canvas canvas, Rect rect, bool boss) {
    final base = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.width * .10,
        rect.height * .40,
        rect.width * .80,
        rect.height * .48,
      ),
      Radius.circular(rect.width * .08),
    );
    canvas.drawRRect(
      base,
      _gradient(
        rect,
        boss
            ? const [Color(0xFFFFD54F), Color(0xFFFF8F00), Color(0xFF8D3B00)]
            : const [Color(0xFFB87942), Color(0xFF6D3B1E)],
      ),
    );
    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.width * .10,
        rect.height * .20,
        rect.width * .80,
        rect.height * .31,
      ),
      Radius.circular(rect.width * .15),
    );
    canvas.drawRRect(
      lid,
      _gradient(
        rect,
        boss
            ? const [Color(0xFFFFF176), Color(0xFFFF9800)]
            : const [Color(0xFFD69A5D), Color(0xFF7A4321)],
      ),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        rect.width * .44,
        rect.height * .32,
        rect.width * .12,
        rect.height * .46,
      ),
      Paint()..color = boss ? const Color(0xFFFFF59D) : const Color(0xFFFFC107),
    );
    if (boss) {
      _text(
        canvas,
        '★',
        Offset(rect.center.dx, rect.height * .60),
        rect.width * .26,
        Colors.white,
      );
    }
  }

  void _paintCity(Canvas canvas, Rect rect) {
    final paint = _gradient(rect, const [
      Color(0xFF7FDBFF),
      Color(0xFF3367D6),
      Color(0xFF17356D),
    ]);
    final buildings = <Rect>[
      Rect.fromLTWH(
        rect.width * .12,
        rect.height * .38,
        rect.width * .22,
        rect.height * .48,
      ),
      Rect.fromLTWH(
        rect.width * .38,
        rect.height * .20,
        rect.width * .25,
        rect.height * .66,
      ),
      Rect.fromLTWH(
        rect.width * .67,
        rect.height * .32,
        rect.width * .21,
        rect.height * .54,
      ),
    ];
    for (final building in buildings) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(building, Radius.circular(rect.width * .04)),
        paint,
      );
      for (var row = 0; row < 3; row++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              building.left + building.width * .26,
              building.top + building.height * (.18 + row * .23),
              building.width * .48,
              building.height * .09,
            ),
            Radius.circular(rect.width * .015),
          ),
          Paint()..color = const Color(0xFFFFE082),
        );
      }
    }
  }

  void _paintGloss(Canvas canvas, Rect rect) {
    final gloss = Path()
      ..moveTo(rect.width * .18, rect.height * .20)
      ..quadraticBezierTo(
        rect.width * .42,
        rect.height * .02,
        rect.width * .67,
        rect.height * .16,
      )
      ..quadraticBezierTo(
        rect.width * .44,
        rect.height * .18,
        rect.width * .25,
        rect.height * .38,
      )
      ..close();
    canvas.drawPath(
      gloss,
      Paint()..color = Colors.white.withValues(alpha: .26),
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(
              color: Color(0x55000000),
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ThreeDIconPainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
