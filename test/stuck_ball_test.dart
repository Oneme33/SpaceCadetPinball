import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d/forge2d.dart';
import 'package:space_cadet/game/physics/ball.dart';
import 'package:space_cadet/game/physics/physics_world.dart';
import 'package:space_cadet/game/table/stuck_ball.dart';

void main() {
  setUpAll(PhysicsWorld.initialize);

  late PhysicsWorld physics;
  late PinballBall ball;
  late List<PinballBall> relaunched;

  StuckBallGuard guard({List<Rect> rest = const []}) => StuckBallGuard(
    restAreas: rest,
    relaunch: relaunched.add,
    random: math.Random(1),
  );

  setUp(() {
    physics = PhysicsWorld(gravity: const (0, 12));
    // A narrow V-shaped pit the ball cannot climb out of with small pushes.
    physics.world
        .createBody(BodyDef())
        .createChain(
          ChainDef(
            isLoop: true,
            points: [
              Vector2(0, 0.3),
              Vector2(3, -3),
              Vector2(0, -3),
              Vector2(-3, -3),
            ],
          ),
        );
    ball = PinballBall(
      physics.world,
      x: 0,
      y: -0.5,
      radius: 0.3,
      gravityMult: 0.2,
    );
    relaunched = [];
  });

  tearDown(() => physics.destroy());

  void run(StuckBallGuard g, double seconds) {
    var t = 0.0;
    for (var i = 0; i < seconds * 60; i++) {
      physics.advance(1 / 60);
      t += 1 / 60;
      g.check([ball], t);
    }
  }

  test('a ball stuck in a pit is relaunched', () {
    final g = guard();
    run(g, 5);
    expect(relaunched, [ball]);
  });

  test('a ball resting by a flipper or the plunger is left alone', () {
    final g = guard(rest: [const Rect.fromLTRB(-1, -1, 1, 1)]);
    run(g, 5);
    expect(relaunched, isEmpty);
  });
}
