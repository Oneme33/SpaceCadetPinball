import 'package:forge2d/forge2d.dart';

import '../../dat/pinball_data.dart';
import 'collision.dart';

/// Turns DAT wall geometry into Box2D shapes.
///
/// In the original a wall line is solid on the right of its direction
/// (`maths::line_init`: clockwise perpendicular). Box2D chains are solid on
/// the right of their winding too, so polygons and lines become one-sided
/// chains in their original order and keep their original sidedness —
/// one-way gates included. Only the table outline is reversed, as
/// `TTableLayer` does. Circles are solid posts.
abstract final class TableWalls {
  /// Length of the invisible ghost segments that cap an open chain.
  static const _ghost = 0.1;

  /// Points closer than this are merged; Box2D rejects tiny segments.
  static const _minEdge = 0.01;

  /// The table's outer boundary, on its own static body.
  static Body buildOutline(World world, List<double> outline) {
    final body = world.createBody(BodyDef(userData: 'table'));
    body.createChain(
      ChainDef(
        points: _points(outline).reversed.toList(),
        isLoop: true,
        materials: [Collision.material(const Material(elasticity: 0.5))],
        filter: Collision.wall(Collision.playfield),
        userData: 'table',
      ),
    );
    return body;
  }

  static void addShapes(
    Body body,
    Iterable<WallShape> walls, {
    required SurfaceMaterial material,
    required Filter filter,
  }) {
    for (final w in walls) {
      switch (w) {
        case WallCircle(:final x, :final y, :final radius):
          body.createShape(
            Circle(center: Vector2(x, y), radius: radius),
            ShapeDef(material: material, filter: filter),
          );
        case WallLine(:final x1, :final y1, :final x2, :final y2):
          addLine(body, x1, y1, x2, y2, material: material, filter: filter);
        case WallPolygon(:final points):
          var pts = _clean(_points(points));
          if (pts.length < 2) continue;
          // A loop chain needs at least 4 points: split edges if needed.
          while (pts.length < 4) {
            pts = [
              for (var i = 0; i < pts.length; i++) ...[
                pts[i],
                (pts[i] + pts[(i + 1) % pts.length]) * 0.5,
              ],
            ];
          }
          body.createChain(
            ChainDef(
              points: pts,
              isLoop: true,
              materials: [material],
              filter: filter,
            ),
          );
      }
    }
  }

  /// A one-sided segment: an open chain with ghost ends.
  static void addLine(
    Body body,
    double x1,
    double y1,
    double x2,
    double y2, {
    required SurfaceMaterial material,
    required Filter filter,
  }) {
    final a = Vector2(x1, y1), b = Vector2(x2, y2);
    final d = (b - a)..normalize();
    body.createChain(
      ChainDef(
        points: [a - d * _ghost, a, b, b + d * _ghost],
        materials: [material],
        filter: filter,
      ),
    );
  }

  static List<Vector2> _points(List<double> xy) => [
    for (var i = 0; i < xy.length; i += 2) Vector2(xy[i], xy[i + 1]),
  ];

  static List<Vector2> _clean(List<Vector2> pts) {
    final out = <Vector2>[];
    for (final p in pts) {
      if (out.isEmpty || out.last.distanceTo(p) >= _minEdge) out.add(p);
    }
    while (out.length > 1 && out.first.distanceTo(out.last) < _minEdge) {
      out.removeLast();
    }
    return out;
  }
}
