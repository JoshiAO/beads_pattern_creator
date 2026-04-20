import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'package:vector_math/vector_math_64.dart' as vmath;

class MeshFactory {
  // Procedurally builds a UV sphere so we do not need external OBJ assets.
  static cube.Mesh createSphere({
    required double radius,
    required Color color,
    int latSegments = 10,
    int lonSegments = 12,
  }) {
    final vertices = <vmath.Vector3>[];
    final indices = <cube.Polygon>[];

    for (var lat = 0; lat <= latSegments; lat++) {
      final theta = (lat / latSegments) * math.pi;
      final sinTheta = math.sin(theta);
      final cosTheta = math.cos(theta);

      for (var lon = 0; lon <= lonSegments; lon++) {
        final phi = (lon / lonSegments) * math.pi * 2;
        final sinPhi = math.sin(phi);
        final cosPhi = math.cos(phi);

        vertices.add(
          vmath.Vector3(
            radius * cosPhi * sinTheta,
            radius * cosTheta,
            radius * sinPhi * sinTheta,
          ),
        );
      }
    }

    for (var lat = 0; lat < latSegments; lat++) {
      for (var lon = 0; lon < lonSegments; lon++) {
        final a = lat * (lonSegments + 1) + lon;
        final b = a + lonSegments + 1;
        final c = a + 1;
        final d = b + 1;
        indices.add(cube.Polygon(a, b, c));
        indices.add(cube.Polygon(c, b, d));
      }
    }

    final material = cube.Material()
      ..diffuse = vmath.Vector3(color.r, color.g, color.b)
      ..opacity = color.a;

    return cube.Mesh(vertices: vertices, indices: indices, material: material);
  }

  static cube.Mesh createCube({
    required double width,
    required double height,
    required double depth,
    required Color color,
  }) {
    final hw = width / 2;
    final hh = height / 2;
    final hd = depth / 2;

    final vertices = <vmath.Vector3>[
      vmath.Vector3(-hw, -hh, -hd),
      vmath.Vector3(hw, -hh, -hd),
      vmath.Vector3(hw, hh, -hd),
      vmath.Vector3(-hw, hh, -hd),
      vmath.Vector3(-hw, -hh, hd),
      vmath.Vector3(hw, -hh, hd),
      vmath.Vector3(hw, hh, hd),
      vmath.Vector3(-hw, hh, hd),
    ];

    final indices = <cube.Polygon>[
      cube.Polygon(0, 1, 2),
      cube.Polygon(0, 2, 3),
      cube.Polygon(4, 6, 5),
      cube.Polygon(4, 7, 6),
      cube.Polygon(0, 4, 5),
      cube.Polygon(0, 5, 1),
      cube.Polygon(3, 2, 6),
      cube.Polygon(3, 6, 7),
      cube.Polygon(1, 5, 6),
      cube.Polygon(1, 6, 2),
      cube.Polygon(0, 3, 7),
      cube.Polygon(0, 7, 4),
    ];

    final material = cube.Material()
      ..diffuse = vmath.Vector3(color.r, color.g, color.b)
      ..opacity = color.a;

    return cube.Mesh(vertices: vertices, indices: indices, material: material);
  }

  static cube.Mesh createCylinder({
    required double radius,
    required double height,
    required Color color,
    int segments = 20,
  }) {
    final h = height / 2;
    final vertices = <vmath.Vector3>[];
    final indices = <cube.Polygon>[];

    final topCenterIndex = vertices.length;
    vertices.add(vmath.Vector3(0, h, 0));
    final bottomCenterIndex = vertices.length;
    vertices.add(vmath.Vector3(0, -h, 0));

    for (var i = 0; i < segments; i++) {
      final angle = (i / segments) * math.pi * 2;
      final x = math.cos(angle) * radius;
      final z = math.sin(angle) * radius;
      vertices.add(vmath.Vector3(x, h, z));
      vertices.add(vmath.Vector3(x, -h, z));
    }

    for (var i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      final topA = 2 + (i * 2);
      final botA = topA + 1;
      final topB = 2 + (next * 2);
      final botB = topB + 1;

      indices.add(cube.Polygon(topCenterIndex, topB, topA));
      indices.add(cube.Polygon(bottomCenterIndex, botA, botB));
      indices.add(cube.Polygon(topA, topB, botA));
      indices.add(cube.Polygon(botA, topB, botB));
    }

    final material = cube.Material()
      ..diffuse = vmath.Vector3(color.r, color.g, color.b)
      ..opacity = color.a;

    return cube.Mesh(vertices: vertices, indices: indices, material: material);
  }

  static cube.Mesh createDiamond({
    required double radiusX,
    required double radiusY,
    required double radiusZ,
    required Color color,
  }) {
    final vertices = <vmath.Vector3>[
      vmath.Vector3(0, radiusY, 0),
      vmath.Vector3(0, -radiusY, 0),
      vmath.Vector3(radiusX, 0, 0),
      vmath.Vector3(-radiusX, 0, 0),
      vmath.Vector3(0, 0, radiusZ),
      vmath.Vector3(0, 0, -radiusZ),
    ];

    final indices = <cube.Polygon>[
      cube.Polygon(0, 2, 4),
      cube.Polygon(0, 4, 3),
      cube.Polygon(0, 3, 5),
      cube.Polygon(0, 5, 2),
      cube.Polygon(1, 4, 2),
      cube.Polygon(1, 3, 4),
      cube.Polygon(1, 5, 3),
      cube.Polygon(1, 2, 5),
    ];

    final material = cube.Material()
      ..diffuse = vmath.Vector3(color.r, color.g, color.b)
      ..opacity = color.a;

    return cube.Mesh(vertices: vertices, indices: indices, material: material);
  }
}
