import 'package:flutter/material.dart';

/// Keeps a bounded game composition on-screen without introducing a scroll
/// container. Content renders at its natural size when possible and scales
/// down uniformly only when the available viewport is smaller.
class GameFitView extends StatelessWidget {
  const GameFitView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = MediaQuery.sizeOf(context);
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : viewport.width;
          final height = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : viewport.height;

          return SizedBox(
            width: width,
            height: height,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
