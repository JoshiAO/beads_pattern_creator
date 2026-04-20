import 'package:flutter/material.dart';

class BeadType {
  const BeadType({required this.name, required this.color, required this.size});

  final String name;
  final Color color;
  final double size;
}

const List<BeadType> defaultBeadTypes = [
  BeadType(name: 'Red 3mm', color: Color(0xFFD94343), size: 0.45),
  BeadType(name: 'Sky 3mm', color: Color(0xFF3F8EE8), size: 0.45),
  BeadType(name: 'Leaf 4mm', color: Color(0xFF2CA45D), size: 0.58),
  BeadType(name: 'Sun 4mm', color: Color(0xFFF0B429), size: 0.58),
  BeadType(name: 'Ink 3mm', color: Color(0xFF1D1D1F), size: 0.45),
];
