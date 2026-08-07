import 'package:flutter/material.dart';

import '../home/home_ambient_background.dart';

/// Reuses the production living backdrop on the world map without duplicating
/// animation controllers or painter logic.
class WorldMapAmbientBackground extends StatelessWidget {
  const WorldMapAmbientBackground({
    super.key,
    required this.startColor,
    required this.endColor,
  });

  final Color startColor;
  final Color endColor;

  @override
  Widget build(BuildContext context) =>
      HomeAmbientBackground(startColor: startColor, endColor: endColor);
}
