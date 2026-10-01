import 'dart:math' as math;

import 'package:forge2d/forge2d.dart';

import '../../dat/pinball_data.dart' as dat;
import 'collision.dart';

/// Flipper geometry and timing from PINBALL.DAT (attributes 800–805).
class FlipperSpec {
  const FlipperSpec({
    required this.originX,
    required this.originY,
    required this.baseRadius,
    required this.restTipX,
    required this.restTipY,
    required this.tipRadius,
    required this.extendedTipX,
    required this.extendedTipY,
    required this.extendTime,
    required this.retractTime,
    required this.collisionMult,
    required this.material,
  });

  /// Reads a flipper component the way `TFlipper`/`TFlipperEdge` do.
  /// Radii are the real ones: the original adds the ball radius to them
  /// because it treats the ball as a point; Box2D does not need that.
  factory FlipperSpec.fromData(dat.PinballData data, dat.Component c) {
    List<double> attr(int code) =>
        data.floatAttribute(c.group, 0, code)!.toList();
    final o = attr(800), t1 = attr(801), t2 = attr(802);
    return FlipperSpec(
      originX: o[0],
      originY: o[1],
      baseRadius: o[2],
      restTipX: t1[0],
      restTipY: t1[1],
      tipRadius: t1[2],
      extendedTipX: t2[0],
      extendedTipY: t2[1],
      extendTime: attr(804)[0],
      retractTime: attr(805)[0],
      collisionMult: attr(803)[0],
      material: c.states.first.material,
    );
  }

  final double originX, originY, baseRadius;
  final double restTipX, restTipY, tipRadius;
  final double extendedTipX, extendedTipY;

  /// Seconds from rest to fully extended, and back (3D Pinball format).
  final double extendTime, retractTime;

  /// TODO: VERIFY AGAINST ORIGINAL SPACE CADET — the original scales the
  /// ball's rebound off a moving flipper by this; Box2D's kinematic contact
  /// handles momentum itself. Revisit when tuning (Phase 8).
  final double collisionMult;

  final dat.Material material;

  /// Signed rotation from rest to extended, as `TFlipperEdge::AngleMax`.
  double get angleMax {
    final ax = restTipX - originX, ay = restTipY - originY;
    final bx = extendedTipX - originX, by = extendedTipY - originY;
    return math.atan2(ax * by - ay * bx, ax * bx + ay * by);
  }
}

/// A physics-driven flipper: a kinematic body rotating about its pivot.
///
/// Kinematic means infinite mass and an exact, input-driven angular speed,
/// so the response is immediate and the ball gets the full momentum of the
/// swing. The shape is the original's: a circle at the pivot, a circle at
/// the tip and the quad between their tangent points.
class Flipper {
  Flipper(this.world, this.spec)
    : body = world.createBody(
        BodyDef(
          type: BodyType.kinematic,
          position: Vector2(spec.originX, spec.originY),
          enableSleep: false,
        ),
      ) {
    body.userData = this;
    _buildShapes();
  }

  void _buildShapes() {
    for (final shape in body.shapes) {
      shape.destroy();
    }
    final tip = Vector2(tipX, tipY);
    final base = spec.baseRadius * _length, end = spec.tipRadius * _length;
    final dir = tip.normalized();
    final perp = Vector2(-dir.y, dir.x);
    final def = ShapeDef(
      material: Collision.material(spec.material),
      filter: Collision.wall(Collision.playfield),
      enableContactEvents: true,
      userData: this,
    );
    body
      ..createShape(Circle(radius: base), def)
      ..createShape(Circle(center: tip, radius: end), def)
      ..createShape(
        Polygon([
          perp * base,
          tip + perp * end,
          tip - perp * end,
          -perp * base,
        ]),
        def,
      );
  }

  final World world;
  final FlipperSpec spec;
  final Body body;

  /// Held by the player.
  bool pressed = false;

  double _length = 1;

  /// Size relative to the original, scaled about the pivot: 1 is the
  /// original flipper. Not original: easy mode makes them longer.
  double get length => _length;
  set length(double v) {
    if (v == _length) return;
    _length = v;
    _buildShapes();
  }

  /// The tip at rest, relative to the pivot.
  double get tipX => (spec.restTipX - spec.originX) * _length;
  double get tipY => (spec.restTipY - spec.originY) * _length;

  /// Current rotation from rest, between 0 and [FlipperSpec.angleMax].
  double get angle => body.angle;

  /// 0 at rest, 1 fully extended.
  double get extension => (angle / spec.angleMax).clamp(0.0, 1.0);

  /// Sets the angular velocity for the coming step so the flipper moves at
  /// the original's constant speed and stops exactly at its end position.
  void beforeStep(double dt) {
    final max = spec.angleMax;
    final target = pressed ? max : 0.0;
    final speed = max.abs() / (pressed ? spec.extendTime : spec.retractTime);
    final delta = target - angle;
    body.angularVelocity = delta.abs() < 1e-6
        ? 0
        : delta.sign * math.min(speed, delta.abs() / dt);
  }

  /// Sprite index for [frames] frames, as `TFlipper::UpdateSprite`.
  int frame(int frames) =>
      (extension * (frames - 1) + 0.5).floor().clamp(0, frames - 1);

  /// The flipper outline in table space, for placeholders and debug.
  List<(double, double)> outline({int arcPoints = 6}) {
    final a = angle;
    final c = math.cos(a), s = math.sin(a);
    final pts = <(double, double)>[];
    final base = math.atan2(tipY, tipX);
    void arc(double cx, double cy, double r, double from) {
      for (var i = 0; i <= arcPoints; i++) {
        final t = from + math.pi * i / arcPoints;
        pts.add((cx + r * math.cos(t), cy + r * math.sin(t)));
      }
    }

    arc(tipX, tipY, spec.tipRadius * _length, base - math.pi / 2);
    arc(0, 0, spec.baseRadius * _length, base + math.pi / 2);
    return [
      for (final (x, y) in pts)
        (spec.originX + x * c - y * s, spec.originY + x * s + y * c),
    ];
  }
}
