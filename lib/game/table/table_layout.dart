import 'dart:ui';

import '../../dat/pinball_data.dart';
import '../physics/flipper.dart';
import '../physics/plunger.dart';

/// The table's element map in table space: everything physics and gameplay
/// need to know about where things are, before any body exists.
///
/// Built from PINBALL.DAT when the originals are installed. Without them a
/// stand-in is used whose numbers were read from the original DAT, so the
/// game stays playable (and testable) in a fresh clone: the outline,
/// flippers, plunger and drain are to scale; only the inner walls and the
/// art are missing.
class TableLayout {
  TableLayout._({
    required this.outline,
    required this.gravity,
    required this.gravityMult,
    required this.ballRadius,
    required this.leftFlipper,
    required this.rightFlipper,
    required this.plunger,
    required this.drain,
    required this.components,
  });

  factory TableLayout.fromData(PinballData data) {
    Component one(ComponentType t) =>
        data.components.firstWhere((c) => c.type == t);
    final poly = data.tableWalls.whereType<WallPolygon>().first;
    return TableLayout._(
      outline: poly.points,
      gravity: data.gravity,
      gravityMult: data.gravityMult,
      ballRadius: data.ballRadius,
      leftFlipper: FlipperSpec.fromData(data, one(ComponentType.flipperLeft)),
      rightFlipper: FlipperSpec.fromData(data, one(ComponentType.flipperRight)),
      plunger: PlungerSpec.fromData(data, one(ComponentType.plunger)),
      drain: Drain.fromData(data, one(ComponentType.drain)),
      components: data.components,
    );
  }

  factory TableLayout.placeholder() {
    FlipperSpec flipper(double side) => FlipperSpec(
      originX: 2.489 * side,
      originY: 12.063,
      baseRadius: 0.311,
      restTipX: 0.961 * side,
      restTipY: 13.131,
      tipRadius: 0.193,
      extendedTipX: 0.961 * side,
      extendedTipY: 11.007,
      extendTime: 0.04,
      retractTime: 0.08,
      collisionMult: 0.9,
      material: const Material(elasticity: 0.75, smoothness: 0.5),
    );
    return TableLayout._(
      outline: const [8, 15, -8, 15, -8, -14, 8, -14],
      gravity: (0, 11.9856),
      gravityMult: 0.2,
      ballRadius: 0.3,
      leftFlipper: flipper(1),
      rightFlipper: flipper(-1),
      plunger: const PlungerSpec(
        x1: -8.003,
        y1: 11.975,
        x2: -6.384,
        y2: 11.975,
        feedX: -7.021,
        feedY: 10.085,
        frames: 8,
      ),
      drain: const Drain(y: 14.437, delay: 1.82),
      components: const [],
    );
  }

  /// The table's own boundary polygon (x0, y0, x1, y1, …).
  final List<double> outline;

  /// Table-space gravity. +y points towards the drain.
  final (double, double) gravity;

  /// Speed-proportional braking of the table's field effect.
  final double gravityMult;

  final double ballRadius;

  /// `pb::BallMaxSpeed`: 200 ball radii per second.
  double get ballMaxSpeed => ballRadius * 200;

  final FlipperSpec leftFlipper;
  final FlipperSpec rightFlipper;
  final PlungerSpec plunger;
  final Drain drain;
  final List<Component> components;

  bool get hasOriginalData => components.isNotEmpty;

  late final Rect bounds = () {
    var (l, t, r, b) = (outline[0], outline[1], outline[0], outline[1]);
    for (var i = 2; i < outline.length; i += 2) {
      final (x, y) = (outline[i], outline[i + 1]);
      if (x < l) l = x;
      if (x > r) r = x;
      if (y < t) t = y;
      if (y > b) b = y;
    }
    return Rect.fromLTRB(l, t, r, b);
  }();

  Iterable<Component> ofType(ComponentType type) =>
      components.where((c) => c.type == type);

  Component? byName(String name) {
    for (final c in components) {
      if (c.name == name) return c;
    }
    return null;
  }
}
