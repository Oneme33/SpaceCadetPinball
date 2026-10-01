import 'dart:math' as math;

import 'package:forge2d/forge2d.dart';

import '../../dat/pinball_data.dart' as dat;
import 'ball.dart';
import 'collision.dart';

/// The launcher, as `TPlunger`.
///
/// In the original the plunger never moves physically. Holding it builds a
/// boost of 1 every 25 ms up to 100 (2.5 s); on release, for 25 ms, a ball
/// touching the plunger line gets that boost (+0–10 % random) along the
/// line's normal. The ball's top speed (60) caps the result, so anything
/// above 60 % pull is a full-strength launch, as in the original.
class Plunger {
  Plunger(this.world, this.spec, {math.Random? random})
    : _random = random ?? math.Random(),
      body = world.createBody(BodyDef()) {
    final a = Vector2(spec.x1, spec.y1), b = Vector2(spec.x2, spec.y2);
    final d = (b - a)..normalize();
    body.createChain(
      ChainDef(
        points: [a - d * 0.1, a, b, b + d * 0.1],
        // TPlunger forces elasticity and smoothness to 0.5.
        materials: [
          Collision.material(
            const dat.Material(elasticity: 0.5, smoothness: 0.5),
          ),
        ],
        filter: Collision.wall(Collision.playfield),
        userData: 'plunger',
      ),
    );
    // Solid side is to the right of the line direction.
    _normal = Vector2(d.y, -d.x);
  }

  static const double maxPullback = 100;
  static const double pullbackDelay = 0.025;

  final World world;
  final PlungerSpec spec;
  final Body body;

  int get frames => spec.frames;
  final math.Random _random;
  late final Vector2 _normal;

  /// 3D Pinball floors the increment: 100 / (8 frames × 8) → 1.
  late final double pullbackIncrement = (maxPullback / (frames * 8))
      .floorToDouble();

  bool _pulling = false;
  double boost = 0;
  double _pullTimer = 0;
  double _releaseWindow = 0;

  bool get pulling => _pulling;

  void press() {
    if (_pulling) return;
    _pulling = true;
    boost = 0;
    _pullTimer = 0;
    _releaseWindow = 0;
    _pull();
  }

  void release() {
    if (!_pulling) return;
    _pulling = false;
    _releaseWindow = pullbackDelay;
  }

  void _pull() {
    boost = math.min(boost + pullbackIncrement, maxPullback);
  }

  /// Sprite index, as `TPlunger::PullbackTimer`.
  int get frame => _pulling ? ((frames - 1) * boost / maxPullback).floor() : 0;

  /// Returns true when [ball] was launched this step.
  bool beforeStep(double dt, Iterable<PinballBall> balls) {
    if (_pulling) {
      _pullTimer += dt;
      while (_pullTimer >= pullbackDelay && boost < maxPullback) {
        _pullTimer -= pullbackDelay;
        _pull();
      }
      return false;
    }
    if (_releaseWindow <= 0) return false;
    _releaseWindow -= dt;
    var launched = false;
    for (final ball in balls) {
      if (!touches(ball)) continue;
      final kick = boost + _random.nextDouble() * boost * 0.1;
      ball.body.linearVelocity = ball.body.linearVelocity + _normal * kick;
      launched = true;
    }
    if (launched || _releaseWindow <= 0) {
      boost = 0;
      _releaseWindow = 0;
    }
    return launched;
  }

  /// Ball resting on (or right at) the plunger face.
  bool touches(PinballBall ball) {
    final PlungerSpec(:x1, :y1, :x2, :y2) = spec;
    final ax = x2 - x1, ay = y2 - y1;
    final t = (((ball.x - x1) * ax + (ball.y - y1) * ay) / (ax * ax + ay * ay))
        .clamp(0.0, 1.0);
    final px = x1 + ax * t, py = y1 + ay * t;
    final dx = ball.x - px, dy = ball.y - py;
    final onSolidSide = dx * _normal.x + dy * _normal.y >= 0;
    return onSolidSide && math.sqrt(dx * dx + dy * dy) <= ball.radius + 0.05;
  }
}

/// Plunger face line, ball feed position (`PlungerPosition`, attribute
/// 601) and sprite frame count.
class PlungerSpec {
  const PlungerSpec({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.feedX,
    required this.feedY,
    required this.frames,
  });

  factory PlungerSpec.fromData(dat.PinballData data, dat.Component c) {
    final line = c.states.first.walls.whereType<dat.WallLine>().first;
    final feed = data.floatAttribute(c.group, 0, 601)!;
    return PlungerSpec(
      x1: line.x1,
      y1: line.y1,
      x2: line.x2,
      y2: line.y2,
      feedX: feed[0],
      feedY: feed[1],
      frames: c.states.length,
    );
  }

  final double x1, y1, x2, y2, feedX, feedY;
  final int frames;
}

/// The drain line (`TDrain`). A ball whose edge crosses it is lost; the
/// original waits [delay] seconds (attribute 407) before the next ball.
class Drain {
  const Drain({required this.y, required this.delay});

  factory Drain.fromData(dat.PinballData data, dat.Component c) {
    final line = c.states.first.walls.whereType<dat.WallLine>().first;
    return Drain(
      y: math.min(line.y1, line.y2),
      delay: data.floatAttribute(c.group, 0, 407)?[0] ?? 1.82,
    );
  }

  final double y;
  final double delay;

  bool swallows(PinballBall ball) => ball.y + ball.radius >= y;
}
