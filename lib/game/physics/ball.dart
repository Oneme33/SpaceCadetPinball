import 'dart:math' as math;

import 'package:forge2d/forge2d.dart';

import 'collision.dart';
import 'ramp_plane.dart';

/// A pinball, simulated like the original's `TBall`:
///
/// - it slides rather than rolls (the original ball has no spin), so
///   rotation is fixed;
/// - the table's field effect (`TTableLayer::FieldEffect`) brakes it in
///   proportion to its speed (gravityMult, 0.2) and adds a small random
///   sideways push of up to ±0.5 · speed · gravityMult. The braking is
///   Box2D's linear damping; the push, and the extra fields of ramps and
///   kickouts, are applied as a force before every step;
/// - it is on one collision layer at a time ([layers], the original's
///   `CollisionMask`) and has a height [z] for drawing, which ramps raise.
class PinballBall {
  PinballBall(
    this.world, {
    required double x,
    required double y,
    required this.radius,
    required this.gravityMult,
    math.Random? random,
  }) : _random = random ?? math.Random(),
       z = radius,
       prevX = x,
       prevY = y,
       body = world.createBody(
         BodyDef(
           type: BodyType.dynamic,
           position: Vector2(x, y),
           isBullet: true,
           fixedRotation: true,
           linearDamping: gravityMult,
           enableSleep: false,
         ),
       ) {
    body.userData = this;
    _shape = body.createShape(
      Circle(radius: radius),
      ShapeDef(
        material: Collision.ballMaterial,
        filter: Collision.ball(Collision.playfield),
        enableContactEvents: true,
        enableHitEvents: true,
        userData: this,
      ),
    );
  }

  final World world;
  final double radius;
  final double gravityMult;
  final Body body;
  final math.Random _random;
  late final Shape _shape;

  /// Height above the playfield for drawing; radius when on the floor.
  double z;

  /// Position before the current step, for trigger lines.
  double prevX, prevY;

  /// Velocity at the start of the current step, for the original's
  /// collision response.
  final Vector2 preVelocity = Vector2.zero();

  /// Acceleration from extra fields (ramps, kickouts), summed per step.
  final Vector2 fieldAccel = Vector2.zero();

  /// Set while a kickout, sink or hole holds the ball.
  Object? capturedBy;

  /// The ramp plane the ball is rolling on (`CollisionFlag`), or null on
  /// a flat level.
  RampPlane? rampPlane;

  int _layers = Collision.playfield;

  /// Collision layers the ball is on (the original's `CollisionMask`).
  int get layers => _layers;
  set layers(int value) {
    if (value == _layers) return;
    _layers = value;
    _shape.filter = Collision.ball(value);
  }

  double get x => body.position.x;
  double get y => body.position.y;
  double get speed => body.linearVelocity.length;
  bool get isCaptured => capturedBy != null;

  final Vector2 _force = Vector2.zero();

  /// Applies the random sideways push of the table field plus any extra
  /// field acceleration collected in [fieldAccel]. Call before each step.
  void applyFields() {
    final s = speed;
    _force
      ..setFrom(fieldAccel)
      ..x += s == 0 ? 0 : -(0.5 - _random.nextDouble()) * s * gravityMult;
    fieldAccel.setZero();
    if (_force.x == 0 && _force.y == 0) return;
    body.applyForce(_force..scale(body.mass), wake: true);
  }

  /// Puts the ball at rest at (x, y), for feeding and debug placement.
  void placeAt(double x, double y) {
    body
      ..setTransform(Vector2(x, y), const Rot.identity())
      ..linearVelocity = Vector2.zero();
    prevX = x;
    prevY = y;
  }

  /// Takes the ball out of the simulation and holds it at (x, y).
  void capture(Object by, double x, double y, {double? z}) {
    capturedBy = by;
    placeAt(x, y);
    if (z != null) this.z = z;
    body.isEnabled = false;
  }

  /// Puts a captured ball back into play with velocity (vx, vy).
  void release(double vx, double vy, {double? z}) {
    capturedBy = null;
    body
      ..isEnabled = true
      ..linearVelocity = Vector2(vx, vy);
    if (z != null) this.z = z;
  }

  void destroy() => body.destroy();
}
