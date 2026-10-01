import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../dat/pinball_data.dart';
import '../game_config.dart';
import '../physics/flipper.dart';
import '../table/table_layout.dart';
import '../table/table_projection.dart';

/// Debug-only layer over the playfield.
///
/// - Draws every wall from PINBALL.DAT through the projection, coloured by
///   collision layer. If the projection is right, the lines sit exactly on
///   the art. Toggle with G.
/// - A mouse click puts the ball there (or adds one), at rest. Touch is left
///   to the flipper controls.
class DebugLayer extends PositionComponent
    with TapCallbacks, PointerMoveCallbacks {
  DebugLayer({
    required this.layout,
    required this.projection,
    required this.onPlaceBall,
    this.flippers = const [],
  }) : super(
         position: Vector2.zero(),
         size: Vector2(
           GameConfig.playfieldRect.width,
           GameConfig.playfieldRect.height,
         ),
       );

  final TableLayout layout;
  final TableProjection projection;
  final void Function(double x, double y) onPlaceBall;

  /// Moving bodies, drawn every frame at their current angle.
  final List<Flipper> flippers;

  bool showWalls = true;

  static Paint _stroke(int color) => Paint()
    ..color = Color(color)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.75;

  /// Collision layers seen in the DAT: 1 = playfield, 2 and 4 = raised
  /// levels (ramps, upper area).
  static final _layerPaints = {
    1: _stroke(0xFF00FF66),
    2: _stroke(0xFF00D8FF),
    4: _stroke(0xFFFF4FD8),
    6: _stroke(0xFFFFFFFF),
  };
  static final _otherPaint = _stroke(0xFFFFE14F);
  static final _outlinePaint = _stroke(0xFFFF8000);
  static final _flipperPaint = _stroke(0xFFFFE14F);

  /// Pre-projected wall paths, built once.
  late final List<(Path, Paint)> _wallPaths = [
    (_polygonPath(layout.outline), _outlinePaint),
    for (final c in layout.components)
      if (c.states.isNotEmpty)
        for (final w in c.states.first.walls)
          (
            _wallPath(w),
            _layerPaints[c.states.first.collisionMask] ?? _otherPaint,
          ),
  ];

  @override
  void onTapDown(TapDownEvent event) {
    if (event.deviceKind != PointerDeviceKind.mouse) return;
    final p = event.localPosition;
    final (x, y) = projection.toTable(Offset(p.x, p.y));
    if (layout.bounds.deflate(layout.ballRadius).contains(Offset(x, y))) {
      onPlaceBall(x, y);
    }
  }

  /// Table coordinates under the pointer, for the HUD.
  (double, double)? pointerTable;

  @override
  void onPointerMove(PointerMoveEvent event) {
    final p = event.localPosition;
    pointerTable = projection.toTable(Offset(p.x, p.y));
  }

  @override
  void render(Canvas canvas) {
    if (showWalls) {
      for (final (path, paint) in _wallPaths) {
        canvas.drawPath(path, paint);
      }
      for (final f in flippers) {
        final o = f.outline();
        canvas.drawPath(
          _polygonPath([
            for (final (x, y) in o) ...[x, y],
          ]),
          _flipperPaint,
        );
      }
    }
  }

  Path _wallPath(WallShape w) => switch (w) {
    WallPolygon(:final points) => _polygonPath(points),
    WallLine(:final x1, :final y1, :final x2, :final y2) =>
      Path()
        ..moveTo(projection.toScreen(x1, y1).dx, projection.toScreen(x1, y1).dy)
        ..lineTo(
          projection.toScreen(x2, y2).dx,
          projection.toScreen(x2, y2).dy,
        ),
    WallCircle(:final x, :final y, :final radius) => _circlePath(x, y, radius),
  };

  Path _polygonPath(List<double> pts) {
    final path = Path();
    for (var i = 0; i < pts.length; i += 2) {
      final s = projection.toScreen(pts[i], pts[i + 1]);
      i == 0 ? path.moveTo(s.dx, s.dy) : path.lineTo(s.dx, s.dy);
    }
    return path..close();
  }

  /// A circle on the table plane is an ellipse on screen: project it as a
  /// polygon so perspective is exact.
  Path _circlePath(double cx, double cy, double r) {
    const n = 16;
    final pts = <double>[];
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi;
      pts
        ..add(cx + r * math.cos(a))
        ..add(cy + r * math.sin(a));
    }
    return _polygonPath(pts);
  }
}
