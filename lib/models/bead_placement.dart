class BeadPlacement {
  const BeadPlacement({
    required this.x,
    required this.y,
    required this.z,
    required this.colorValue,
    required this.size,
  });

  final int x;
  final int y;
  final int z;
  final int colorValue;
  final double size;

  String get key => '$x:$y:$z';

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z, 'colorValue': colorValue, 'size': size};
  }

  factory BeadPlacement.fromJson(Map<String, dynamic> json) {
    return BeadPlacement(
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
      colorValue: json['colorValue'] as int,
      size: (json['size'] as num).toDouble(),
    );
  }
}
