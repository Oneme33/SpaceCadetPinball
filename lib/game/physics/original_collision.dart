import 'dart:math' as math;

import 'package:forge2d/forge2d.dart';

import '../../dat/pinball_data.dart' as dat;
import 'flipper.dart';

/// The original's collision response, used instead of Box2D's.
///
/// Box2D finds the contacts and keeps the ball out of the walls; every
/// material has restitution and friction 0, so a contact only stops the
/// ball's approach. For a hit the table then sets the ball's velocity the
/// way 3D Pinball does, from its velocity before the step. Measured against
/// the decompilation (tool/compare), this is what makes a ball roll off a
/// flipper and leave a wall at the original's speed: the original has no
/// friction, smoothness only steers the rebound.
abstract final class OriginalCollision {
  /// `maths::basic_collision` without the kicker part. [normal] points from
  /// the wall to the ball.
  ///
  /// The rebound direction mixes the sliding part (× smoothness) with the
  /// bounce (× elasticity); the speed loses (1 − elasticity) of the
  /// approach. A ball sliding along a wall keeps its speed.
  static Vector2 rebound(
    Vector2 velocity,
    Vector2 normal,
    double elasticity,
    double smoothness,
  ) {
    final speed = velocity.length;
    if (speed == 0) return Vector2.zero();
    final dir = velocity / speed;
    var proj = -dir.dot(normal);
    Vector2 out;
    if (proj < 0) {
      // Moving away already: no rebound, but the speed loss still applies.
      proj = -proj;
      out = dir;
    } else {
      final n = normal * proj;
      out = (n + dir) * smoothness + n * elasticity;
      final len = out.length;
      out = len == 0 ? Vector2.zero() : out / len;
    }
    return out * (speed - (1 - elasticity) * proj * speed);
  }

  /// `TFlipperEdge::EdgeCollision`: a ball hit by (or hitting) [flipper].
  ///
  /// A flipper that is not moving is a plain wall. One moving towards the
  /// ball rebounds it and adds a boost along the normal of
  /// collisionMult · |ω| · (distance from the pivot ÷ flipper length),
  /// so a hit near the tip is strongest. A ball caught by the back of a
  /// moving flipper rebounds the less the further out it is.
  static Vector2 flipper(
    Flipper flipper,
    Vector2 velocity,
    Vector2 normal,
    Vector2 ballPos,
    double ballRadius,
  ) {
    final spec = flipper.spec;
    final e = spec.material.elasticity, s = spec.material.smoothness;
    final omega = flipper.body.angularVelocity;
    if (omega == 0) return rebound(velocity, normal, e, s);

    final pivot = flipper.body.position;
    final r = ballPos - pivot;
    final distSq = r.length2;
    final baseR = spec.baseRadius * flipper.length + ballRadius;
    // `DistanceDiv`: pivot to tip, plus the tip circle and the ball.
    final length =
        math.sqrt(flipper.tipX * flipper.tipX + flipper.tipY * flipper.tipY) +
        ballRadius +
        spec.tipRadius * flipper.length;
    final outside = baseR * baseR * 1.01 < distSq;
    final ratio = math.sqrt(distSq) / length;

    // The surface at the ball moves along ω × r; towards the ball is a
    // front hit.
    final surface = Vector2(-omega * r.y, omega * r.x);
    if (surface.dot(normal) > 0) {
      var boost = 0.0;
      if (outside) {
        // The face's normal on the moving side (`CollisionLinePerp`).
        final a = flipper.body.angle;
        final ax = flipper.tipX * math.cos(a) - flipper.tipY * math.sin(a);
        final ay = flipper.tipX * math.sin(a) + flipper.tipY * math.cos(a);
        final perp = Vector2(-ay, ax)..normalize();
        if (perp.dot(surface) < 0) perp.negate();
        final dot = perp.dot(normal);
        if (dot >= 0) boost = spec.collisionMult * dot * omega.abs() * ratio;
      }
      final v = rebound(velocity, normal, e, s);
      // Threshold −1 in the original: the boost always applies.
      return boost > 0 ? v + normal * boost : v;
    }
    return rebound(velocity, normal, outside ? (1 - ratio) * e : e, s);
  }

  /// `TBall::EdgeCollision`: two balls swap the parts of their velocity
  /// along the line between them. [normal] points from [a] to [b].
  static (Vector2, Vector2) balls(Vector2 a, Vector2 b, Vector2 normal) {
    final pa = a.dot(normal), pb = b.dot(normal);
    final delta = normal * (pb - pa);
    return (a + delta, b - delta);
  }

  /// The table outline's material (`TTableLayer`: elasticity 0.5, the
  /// default smoothness).
  static const tableMaterial = dat.Material(elasticity: 0.5);

  /// `TPlunger` forces elasticity and smoothness to 0.5.
  static const plungerMaterial = dat.Material(elasticity: 0.5, smoothness: 0.5);
}
