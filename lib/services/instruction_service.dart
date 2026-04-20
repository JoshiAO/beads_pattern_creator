import '../models/bead_placement.dart';

class InstructionService {
  static String generateInstructions(Iterable<BeadPlacement> placements) {
    final sorted = placements.toList()
      ..sort((a, b) {
        final z = a.z.compareTo(b.z);
        if (z != 0) return z;
        final y = a.y.compareTo(b.y);
        if (y != 0) return y;
        return a.x.compareTo(b.x);
      });

    if (sorted.isEmpty) {
      return 'No beads placed yet. Drag a bead from the palette onto the 3D mesh.';
    }

    final buffer = StringBuffer();
    final groupedByLayer = <int, List<BeadPlacement>>{};
    for (final bead in sorted) {
      groupedByLayer.putIfAbsent(bead.z, () => []).add(bead);
    }

    for (final layer in groupedByLayer.keys.toList()..sort()) {
      final layerBeads = groupedByLayer[layer]!;
      buffer.writeln('Layer ${layer + 1} (z=$layer):');

      final rowMap = <int, List<BeadPlacement>>{};
      for (final bead in layerBeads) {
        rowMap.putIfAbsent(bead.y, () => []).add(bead);
      }

      for (final row in rowMap.keys.toList()..sort()) {
        final rowBeads = rowMap[row]!..sort((a, b) => a.x.compareTo(b.x));
        final red = rowBeads
            .where((b) => _nameFromColor(b.colorValue) == 'red')
            .length;
        final blue = rowBeads
            .where((b) => _nameFromColor(b.colorValue) == 'blue')
            .length;
        final green = rowBeads
            .where((b) => _nameFromColor(b.colorValue) == 'green')
            .length;
        final yellow = rowBeads
            .where((b) => _nameFromColor(b.colorValue) == 'yellow')
            .length;
        final black = rowBeads
            .where((b) => _nameFromColor(b.colorValue) == 'black')
            .length;

        final parts = <String>[];
        if (red > 0) parts.add('$red red');
        if (blue > 0) parts.add('$blue blue');
        if (green > 0) parts.add('$green green');
        if (yellow > 0) parts.add('$yellow yellow');
        if (black > 0) parts.add('$black black');
        if (parts.isEmpty) parts.add('${rowBeads.length} mixed');

        buffer.writeln(
          '  - Row ${row + 1}: Place ${rowBeads.length} beads (${parts.join(', ')}) at x positions ${rowBeads.map((b) => b.x + 1).join(', ')}.',
        );
      }

      final perColor = <String, int>{};
      for (final bead in layerBeads) {
        final name = _nameFromColor(bead.colorValue);
        perColor[name] = (perColor[name] ?? 0) + 1;
      }

      final summary = perColor.entries
          .map((e) => '${e.value} ${e.key}')
          .join(', ');
      buffer.writeln('  Summary: $summary');
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _nameFromColor(int value) {
    final hex = value & 0x00FFFFFF;
    if (hex == 0x00D94343) return 'red';
    if (hex == 0x003F8EE8) return 'blue';
    if (hex == 0x002CA45D) return 'green';
    if (hex == 0x00F0B429) return 'yellow';
    if (hex == 0x001D1D1F) return 'black';
    return 'custom';
  }
}
