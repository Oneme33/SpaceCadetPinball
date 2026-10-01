import 'dart:math' as math;
import 'dart:ui';

import '../physics/ball.dart';

/// The original's rescue for a stuck ball (`pb::timed_frame` and
/// `control::UnstuckBall`).
///
/// A free ball slower than 0.8 for more than half a second gets a small push
/// in a random direction every frame, unless it rests by a flipper or the
/// plunger, where balls may sit. When it has not moved half a radius for
/// more than 20 checks it is taken away and a new one is launched.
class StuckBallGuard {
  StuckBallGuard({
    required this.restAreas,
    required this.relaunch,
    math.Random? random,
  }) : _random = random ?? math.Random();

  /// Where balls may rest: flippers and the plunger, in table space.
  final List<Rect> restAreas;

  /// Takes [ball] away and launches a new one.
  final void Function(PinballBall ball) relaunch;
  final math.Random _random;

  static const slowSpeed = 0.8;
  static const stuckTime = 0.5;
  static const maxCount = 20;

  final Map<PinballBall, _Track> _tracks = {};

  /// Once per rendered frame (the original checks per frame).
  void check(Iterable<PinballBall> balls, double now) {
    _tracks.removeWhere((b, _) => !balls.contains(b));
    for (final b in balls.toList()) {
      final t = _tracks.putIfAbsent(b, () => _Track(now, b.x, b.y));
      if (b.isCaptured || b.speed >= slowSpeed) {
        if (t.count > 0) {
          final dx = b.x - t.x, dy = b.y - t.y;
          if (dx * dx + dy * dy > 4 * b.radius * b.radius) t.count = 0;
        }
        t.lastActive = now;
        continue;
      }
      if (now - t.lastActive <= stuckTime) continue;
      final dx = b.x - t.x, dy = b.y - t.y;
      t
        ..x = b.x
        ..y = b.y;
      final r2 = b.radius * b.radius / 4;
      t.count = dx * dx + dy * dy > r2 ? 0 : t.count + 1;
      if (restAreas.any(
        (r) => r.inflate(b.radius / 2).contains(Offset(b.x, b.y)),
      )) {
        continue;
      }
      if (t.count <= maxCount) {
        // throw_ball((0, −1), 90, 1, 0): speed 1, any direction.
        final angle = (1 - 2 * _random.nextDouble()) * 90;
        b.body.linearVelocity = b.body.linearVelocity
          ..setValues(-math.sin(angle), -math.cos(angle));
      } else {
        _tracks.remove(b);
        relaunch(b);
      }
    }
  }
}

class _Track {
  _Track(this.lastActive, this.x, this.y);
  double lastActive;
  double x, y;
  int count = 0;
}
