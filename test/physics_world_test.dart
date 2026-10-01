import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d/forge2d.dart';
import 'package:space_cadet/game/physics/physics_world.dart';

/// Smoke tests for the native Box2D binding and our fixed-step wrapper.
void main() {
  setUpAll(PhysicsWorld.initialize);

  const r = Rect.fromLTRB(-8, -14, 8, 15);

  Body dropBall(PhysicsWorld physics) {
    physics.world
        .createBody(BodyDef())
        .createChain(
          ChainDef(
            isLoop: true,
            points: [
              Vector2(r.left, r.bottom),
              Vector2(r.right, r.bottom),
              Vector2(r.right, r.top),
              Vector2(r.left, r.top),
            ],
          ),
        );
    return physics.world.createBody(
      BodyDef(
        type: BodyType.dynamic,
        position: Vector2(0, -10),
        isBullet: true,
      ),
    )..createShape(Circle(radius: 0.3));
  }

  test('a ball falls under gravity and stays inside the table outline', () {
    final physics = PhysicsWorld(gravity: const (0, 12));
    final ball = dropBall(physics);
    final y0 = ball.position.y;
    for (var i = 0; i < 300; i++) {
      physics.advance(1 / 60);
    }
    // Gravity is +y, towards the drain.
    expect(ball.position.y, greaterThan(y0));
    expect(ball.position.y, lessThan(r.bottom));
    expect(ball.position.x, inInclusiveRange(r.left, r.right));
    physics.destroy();
  });

  test('the result does not depend on the frame rate', () {
    double heightAfterOneSecond(int fps) {
      final physics = PhysicsWorld(gravity: const (0, 12));
      final ball = dropBall(physics);
      for (var i = 0; i < fps; i++) {
        physics.advance(1 / fps);
      }
      final y = ball.position.y;
      physics.destroy();
      return y;
    }

    final at60 = heightAfterOneSecond(60);
    expect(heightAfterOneSecond(30), closeTo(at60, 0.05));
    expect(heightAfterOneSecond(144), closeTo(at60, 0.05));
  });
}
