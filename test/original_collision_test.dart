import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d/forge2d.dart';
import 'package:space_cadet/game/physics/original_collision.dart';

/// `maths::basic_collision` and `TBall::EdgeCollision`, as the port uses
/// them for every hit.
void main() {
  final up = Vector2(0, -1); // wall below the ball, normal towards it

  test('a head-on hit comes back at elasticity × speed', () {
    final v = OriginalCollision.rebound(Vector2(0, 10), up, 0.6, 0.95);
    expect(v.x, closeTo(0, 1e-9));
    expect(v.y, closeTo(-6, 1e-9));
  });

  test('a ball sliding along a wall keeps its speed', () {
    final v = OriginalCollision.rebound(Vector2(10, 1e-6), up, 0.5, 0.5);
    expect(v.length, closeTo(10, 1e-4));
    expect(v.x, closeTo(10, 1e-3));
  });

  test('an oblique hit loses (1 − elasticity) of its approach', () {
    // 45°: approach 1/√2 of the speed; smoothness steers the direction.
    final v = OriginalCollision.rebound(Vector2(10, 10), up, 0.5, 0.95);
    final speed = Vector2(10, 10).length;
    expect(v.length, closeTo(speed * (1 - 0.5 * 0.7071), 1e-3));
    expect(v.y, lessThan(0), reason: 'rebounds');
    expect(v.x, greaterThan(-v.y), reason: 'mostly sliding on');
  });

  test('two balls swap the parts of their velocity along the line', () {
    final (a, b) = OriginalCollision.balls(
      Vector2(5, 1),
      Vector2(0, 0),
      Vector2(1, 0),
    );
    expect(a.x, closeTo(0, 1e-9));
    expect(a.y, closeTo(1, 1e-9));
    expect(b.x, closeTo(5, 1e-9));
  });
}
