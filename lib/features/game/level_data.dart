import 'package:flutter/material.dart';

class CargoItem {
  const CargoItem(this.id, this.color, this.icon);
  final int id;
  final Color color;
  final IconData icon;
}

class LevelData {
  const LevelData({required this.number, required this.moves, required this.items});
  final int number;
  final int moves;
  final List<CargoItem> items;
}

const redCargo = CargoItem(1, Color(0xFFE94F37), Icons.local_shipping_rounded);
const blueCargo = CargoItem(2, Color(0xFF247BA0), Icons.inventory_2_rounded);
const greenCargo = CargoItem(3, Color(0xFF47A447), Icons.eco_rounded);
const purpleCargo = CargoItem(4, Color(0xFF8257C7), Icons.star_rounded);
const yellowCargo = CargoItem(5, Color(0xFFF2C14E), Icons.bolt_rounded);

const levels = <LevelData>[
  LevelData(number: 1, moves: 7, items: [redCargo, blueCargo, redCargo, blueCargo]),
  LevelData(number: 2, moves: 9, items: [greenCargo, redCargo, blueCargo, greenCargo, blueCargo, redCargo]),
  LevelData(number: 3, moves: 10, items: [purpleCargo, greenCargo, redCargo, purpleCargo, blueCargo, greenCargo]),
  LevelData(number: 4, moves: 12, items: [yellowCargo, purpleCargo, blueCargo, greenCargo, redCargo, yellowCargo, purpleCargo]),
  LevelData(number: 5, moves: 14, items: [redCargo, blueCargo, greenCargo, purpleCargo, yellowCargo, redCargo, blueCargo, greenCargo, purpleCargo, yellowCargo]),
];
