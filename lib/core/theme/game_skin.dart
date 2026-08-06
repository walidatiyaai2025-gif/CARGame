import 'package:flutter/material.dart';

class GameSkin {
  const GameSkin({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.backgroundTop,
    required this.backgroundBottom,
  });

  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color backgroundTop;
  final Color backgroundBottom;

  LinearGradient get heroGradient => LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get backgroundGradient => LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

const gameSkins = <GameSkin>[
  GameSkin(
    id: 'classic',
    name: 'Classic Cargo',
    primary: Color(0xFF142A47),
    secondary: Color(0xFF2D6CDF),
    accent: Color(0xFFFF9800),
    backgroundTop: Color(0xFFEAF4FF),
    backgroundBottom: Color(0xFFF8F3EA),
  ),
  GameSkin(
    id: 'sunset',
    name: 'Sunset Express',
    primary: Color(0xFF8C2F1B),
    secondary: Color(0xFFD85B24),
    accent: Color(0xFFFFC857),
    backgroundTop: Color(0xFFFFE7D6),
    backgroundBottom: Color(0xFFFFF7EA),
  ),
  GameSkin(
    id: 'neon',
    name: 'Neon Future',
    primary: Color(0xFF241047),
    secondary: Color(0xFF006D77),
    accent: Color(0xFF6FFFE9),
    backgroundTop: Color(0xFFE9E4FF),
    backgroundBottom: Color(0xFFE5FFFB),
  ),
];

GameSkin gameSkinById(String id) => gameSkins.firstWhere(
      (skin) => skin.id == id,
      orElse: () => gameSkins.first,
    );
