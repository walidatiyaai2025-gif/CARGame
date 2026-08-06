import 'dart:math';

import 'package:flutter/material.dart';

class CargoItem {
  const CargoItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.accentColor,
    required this.icon,
  });

  final int id;
  final String name;
  final String category;
  final Color color;
  final Color accentColor;
  final IconData icon;
}

class LevelData {
  const LevelData({
    required this.number,
    required this.world,
    required this.moves,
    required this.items,
    required this.difficulty,
  });

  final int number;
  final int world;
  final int moves;
  final List<CargoItem> items;
  final int difficulty;
}

class GameWorld {
  const GameWorld({
    required this.number,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final int number;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
}

const gameWorlds = <GameWorld>[
  GameWorld(
    number: 1,
    name: 'Starter Depot',
    subtitle: 'Learn the sorting flow',
    icon: Icons.warehouse_rounded,
    startColor: Color(0xFF2D6CDF),
    endColor: Color(0xFF65A5FF),
  ),
  GameWorld(
    number: 2,
    name: 'City Logistics',
    subtitle: 'Faster routes and more cargo',
    icon: Icons.location_city_rounded,
    startColor: Color(0xFF7B43C6),
    endColor: Color(0xFFB778F2),
  ),
  GameWorld(
    number: 3,
    name: 'Harbor Terminal',
    subtitle: 'Busy docks and mixed shipments',
    icon: Icons.directions_boat_filled_rounded,
    startColor: Color(0xFF007C91),
    endColor: Color(0xFF27C2C9),
  ),
  GameWorld(
    number: 4,
    name: 'Desert Express',
    subtitle: 'Tighter move limits',
    icon: Icons.local_shipping_rounded,
    startColor: Color(0xFFD66A1F),
    endColor: Color(0xFFFFB347),
  ),
  GameWorld(
    number: 5,
    name: 'Sky Cargo Hub',
    subtitle: 'Advanced sorting operations',
    icon: Icons.flight_takeoff_rounded,
    startColor: Color(0xFF3151A3),
    endColor: Color(0xFF768DE4),
  ),
  GameWorld(
    number: 6,
    name: 'Global Command',
    subtitle: 'Expert international missions',
    icon: Icons.public_rounded,
    startColor: Color(0xFF162A47),
    endColor: Color(0xFF3B638D),
  ),
];

const productCatalog = <CargoItem>[
  CargoItem(
    id: 1,
    name: 'Premium Parcel',
    category: 'Packages',
    color: Color(0xFFF05A47),
    accentColor: Color(0xFFFF9A75),
    icon: Icons.inventory_2_rounded,
  ),
  CargoItem(
    id: 2,
    name: 'Travel Case',
    category: 'Travel',
    color: Color(0xFF3D6FD8),
    accentColor: Color(0xFF79A6FF),
    icon: Icons.luggage_rounded,
  ),
  CargoItem(
    id: 3,
    name: 'Fresh Produce',
    category: 'Food',
    color: Color(0xFF43A85B),
    accentColor: Color(0xFF80D28B),
    icon: Icons.eco_rounded,
  ),
  CargoItem(
    id: 4,
    name: 'Smart Device',
    category: 'Electronics',
    color: Color(0xFF7156C9),
    accentColor: Color(0xFFAA8FF2),
    icon: Icons.devices_rounded,
  ),
  CargoItem(
    id: 5,
    name: 'Fashion Box',
    category: 'Fashion',
    color: Color(0xFFDB4F8A),
    accentColor: Color(0xFFFF87B8),
    icon: Icons.checkroom_rounded,
  ),
  CargoItem(
    id: 6,
    name: 'Sports Gear',
    category: 'Sports',
    color: Color(0xFFEF8C22),
    accentColor: Color(0xFFFFBF62),
    icon: Icons.sports_basketball_rounded,
  ),
  CargoItem(
    id: 7,
    name: 'Book Crate',
    category: 'Books',
    color: Color(0xFF78624B),
    accentColor: Color(0xFFB99A75),
    icon: Icons.menu_book_rounded,
  ),
  CargoItem(
    id: 8,
    name: 'Toy Chest',
    category: 'Toys',
    color: Color(0xFF00A6A6),
    accentColor: Color(0xFF50D8D8),
    icon: Icons.toys_rounded,
  ),
  CargoItem(
    id: 9,
    name: 'Beauty Kit',
    category: 'Beauty',
    color: Color(0xFFC6539D),
    accentColor: Color(0xFFF69BD2),
    icon: Icons.spa_rounded,
  ),
  CargoItem(
    id: 10,
    name: 'Tool Case',
    category: 'Tools',
    color: Color(0xFF546675),
    accentColor: Color(0xFF91A8B8),
    icon: Icons.handyman_rounded,
  ),
  CargoItem(
    id: 11,
    name: 'Cold Drink',
    category: 'Beverages',
    color: Color(0xFF1488CC),
    accentColor: Color(0xFF69C7FF),
    icon: Icons.local_drink_rounded,
  ),
  CargoItem(
    id: 12,
    name: 'Gift Package',
    category: 'Gifts',
    color: Color(0xFFE34462),
    accentColor: Color(0xFFFF8A9E),
    icon: Icons.card_giftcard_rounded,
  ),
  CargoItem(
    id: 13,
    name: 'Home Decor',
    category: 'Home',
    color: Color(0xFF8A6BC2),
    accentColor: Color(0xFFC3A7F3),
    icon: Icons.chair_rounded,
  ),
  CargoItem(
    id: 14,
    name: 'Footwear',
    category: 'Fashion',
    color: Color(0xFF305A74),
    accentColor: Color(0xFF73A4C2),
    icon: Icons.ice_skating_rounded,
  ),
  CargoItem(
    id: 15,
    name: 'Pet Supplies',
    category: 'Pets',
    color: Color(0xFF9A653E),
    accentColor: Color(0xFFD5A172),
    icon: Icons.pets_rounded,
  ),
  CargoItem(
    id: 16,
    name: 'Medical Pack',
    category: 'Health',
    color: Color(0xFFDA3F45),
    accentColor: Color(0xFFFF8387),
    icon: Icons.medical_services_rounded,
  ),
  CargoItem(
    id: 17,
    name: 'Auto Parts',
    category: 'Automotive',
    color: Color(0xFF455A64),
    accentColor: Color(0xFF90A4AE),
    icon: Icons.settings_rounded,
  ),
  CargoItem(
    id: 18,
    name: 'Luxury Cargo',
    category: 'Premium',
    color: Color(0xFFC18A18),
    accentColor: Color(0xFFFFD565),
    icon: Icons.diamond_rounded,
  ),
];

final List<LevelData> levels = List<LevelData>.unmodifiable(
  List<LevelData>.generate(150, (index) => _generateLevel(index + 1)),
);

LevelData _generateLevel(int number) {
  final random = Random(number * 7919 + 2026);
  final world = ((number - 1) ~/ 25) + 1;
  final levelInWorld = ((number - 1) % 25) + 1;

  final availableProducts = min(6 + world * 2, productCatalog.length);
  final typeCount = min(2 + ((levelInWorld - 1) ~/ 5), min(6, availableProducts));
  final pairCount = min(2 + ((number - 1) ~/ 12), 8);

  final shuffledProducts = List<CargoItem>.of(
    productCatalog.take(availableProducts),
  )..shuffle(random);
  final selectedProducts = shuffledProducts.take(typeCount).toList();

  final items = <CargoItem>[];
  for (var pair = 0; pair < pairCount; pair++) {
    final product = selectedProducts[pair % selectedProducts.length];
    items
      ..add(product)
      ..add(product);
  }
  items.shuffle(random);

  final difficulty = min(10, 1 + ((number - 1) ~/ 15));
  final safetyMoves = max(2, 6 - world);
  final moves = items.length + safetyMoves + random.nextInt(3);

  return LevelData(
    number: number,
    world: world,
    moves: moves,
    items: List<CargoItem>.unmodifiable(items),
    difficulty: difficulty,
  );
}
