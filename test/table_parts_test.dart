import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d/forge2d.dart';
import 'package:space_cadet/dat/pinball_data.dart';
import 'package:space_cadet/game/physics/ball.dart';
import 'package:space_cadet/game/physics/physics_world.dart';
import 'package:space_cadet/game/table/parts/part.dart';
import 'package:space_cadet/game/table/parts/ramp_part.dart';
import 'package:space_cadet/game/table/parts/sensor_parts.dart';
import 'package:space_cadet/game/table/parts/solid_parts.dart';
import 'package:space_cadet/game/table/space_cadet_table.dart';
import 'package:space_cadet/game/table/table_layout.dart';
import 'package:space_cadet/game/rules/message_code.dart';

/// Behaviour of the table components on the original geometry. Skipped
/// when the original PINBALL.DAT is not installed.
void main() {
  final file = File('assets/original/PINBALL.DAT');
  final skip = file.existsSync() ? null : 'original PINBALL.DAT not installed';

  setUpAll(PhysicsWorld.initialize);

  group('table parts', skip: skip, () {
    late PhysicsWorld physics;
    late SpaceCadetTable table;
    late List<PartEvent> events;

    setUp(() {
      final layout = TableLayout.fromData(
        PinballData.parse(file.readAsBytesSync()),
      );
      physics = PhysicsWorld(
        gravity: layout.gravity,
        maxSpeed: layout.ballMaxSpeed,
      );
      table = SpaceCadetTable(physics, layout, random: math.Random(3));
      events = [];
      table.onPartEvent = events.add;
    });

    tearDown(() => physics.destroy());

    void run(double seconds) {
      for (var t = 0.0; t < seconds; t += 1 / 120) {
        physics.advance(1 / 120);
      }
    }

    T part<T extends TablePart>(String name) => table.part(name)! as T;

    PinballBall shoot(double x, double y, double vx, double vy) =>
        table.addBall(x, y)..body.linearVelocity = Vector2(vx, vy);

    bool reported(String name) => events.any((e) => e.part.name == name);

    test('every gameplay component has a part', () {
      final names = table.parts.map((p) => p.name).toSet();
      for (final n in [
        'a_bump1', 'a_targ1', 'a_targ10', 'v_rebo1', 'v_gate1', 'v_bloc1', //
        'a_kick1', 's_onewy1', 'a_roll1', 's_trip1', 'a_flag1', 'a_kout2',
        'v_sink1', 'ramp_hole', 'ramp', 's_ramp9',
      ]) {
        expect(names, contains(n));
      }
    });

    test('a bumper kicks the ball away and lights up', () {
      final b = part<BumperPart>('a_bump1');
      // a_bump1 is at (0.01, -3.72), radius 0.35. Hit it from below.
      final ball = shoot(0.01, -2.6, 0, -8);
      run(0.15);
      expect(reported('a_bump1'), isTrue);
      expect(ball.speed, greaterThan(12));
      expect(b.frame, 1);
      run(0.5);
      expect(b.frame, 0);
    });

    test('a drop target drops on a hard hit and comes back on reset', () {
      final t = part<PopupTargetPart>('a_targ1');
      final c = t.visual.walls.first as WallPolygon;
      var cx = 0.0, cy = 0.0;
      for (var i = 0; i < c.points.length; i += 2) {
        cx += c.points[i] / c.length;
        cy += c.points[i + 1] / c.length;
      }
      // Come at it hard from the playfield side.
      shoot(cx - 1.2, cy + 0.6, 30, -15);
      run(0.2);
      expect(t.isDown, isTrue);
      expect(t.frame, -1);
      table.reset();
      expect(t.isDown, isFalse);
    });

    test('the centre post is down at the start and blocks when raised', () {
      final post = part<BlockerPart>('v_bloc1');
      expect(post.active, isFalse);
      // Straight down the middle drains with the post down...
      shoot(0, 12.4, 0, 2);
      run(1);
      expect(table.balls, isEmpty);
      // ...and is stopped with it up.
      post.raise();
      shoot(0, 12.4, 0, 2);
      run(1);
      expect(table.balls, hasLength(1));
    });

    test('a rollover reports the ball once per pass', () {
      final r = part<RolloverPart>('a_roll1');
      // a_roll1 covers x 0.80…1.71, y −9.84…−9.16.
      final ball = table.addBall(1.25, -10.6);
      ball.body.linearVelocity = Vector2(0, 4);
      run(0.6);
      expect(events.where((e) => e.part == r), hasLength(1));
    });

    test('a kickout catches the ball and throws it out', () {
      final k = part<KickoutPart>('a_kout2');
      // a_kout2 at (−3.27, −9.49): drop the ball in from just beside it.
      final ball = table.addBall(-3.0, -9.3);
      run(0.5);
      expect(reported('a_kout2'), isTrue);
      expect(ball.isCaptured, isTrue);
      // It stays until the rules say otherwise…
      run(3);
      expect(ball.isCaptured, isTrue);
      // …and comes out after the default hold time when they do.
      k.message(MC.tKickoutRestartTimer, -1);
      run(KickoutPart.holdTime + 0.1);
      expect(ball.isCaptured, isFalse);
      expect(ball.speed, greaterThan(1));
      expect(k.active, isTrue);
    });

    test('the gravity well is off until the rules switch it on', () {
      expect(part<KickoutPart>('a_kout1').active, isFalse);
    });

    test('a wormhole swallows the ball and gives it back', () {
      final s = part<SinkPart>('v_sink1');
      final l = s.visual.walls.first as WallLine;
      // Roll straight at the middle of its one-sided line, from its open
      // side (the side its normal points to).
      final dx = l.x2 - l.x1, dy = l.y2 - l.y1;
      final len = math.sqrt(dx * dx + dy * dy);
      final nx = dy / len, ny = -dx / len;
      final mx = (l.x1 + l.x2) / 2, my = (l.y1 + l.y2) / 2;
      shoot(mx + nx * 0.6, my + ny * 0.6, -nx * 6, -ny * 6);
      run(0.4);
      expect(reported('v_sink1'), isTrue);
      expect(table.balls, isEmpty);
      s.message(MC.tSinkResetTimer, -1);
      run(s.timerTime + 0.1);
      expect(table.balls, hasLength(1));
    });

    test('ramps are built from their planes', () {
      final r = part<RampPart>('ramp');
      expect(r.planes, hasLength(18));
      expect(r.rampLayers, 2);
      expect(part<RampPart>('s_ramp9').planes, hasLength(2));
    });

    PinballBall shootUpRamp(double speed) {
      // Bottom end of "ramp", aimed up it.
      final ball = table.addBall(2.39, 1.6);
      ball.body.linearVelocity =
          (Vector2(4.4 - 2.39, -0.7 - 1.6)..normalize()) * speed;
      return ball;
    }

    test(
      'a weak ramp shot climbs, rolls back and returns to the playfield',
      () {
        final ball = shootUpRamp(10);
        var maxZ = 0.0, onRamp = false;
        for (var i = 0; i < 120; i++) {
          physics.advance(1 / 120);
          maxZ = math.max(maxZ, ball.z);
          onRamp |= ball.layers == 2;
        }
        expect(onRamp, isTrue);
        expect(maxZ, greaterThan(ball.radius + 0.3));
        expect(ball.layers, 1);
        expect(ball.rampPlane, isNull);
      },
    );

    test('a strong ramp shot reaches the upper level and its bumpers', () {
      final ball = shootUpRamp(35);
      run(2);
      expect(ball.layers, 4);
      expect(reported('ramp'), isTrue);
      expect(
        events.any(
          (e) => ['a_bump5', 'a_bump6', 'a_bump7'].contains(e.part.name),
        ),
        isTrue,
      );
    });

    test('a ball touching two segments of a part is kicked once', () {
      final kicks = <String, int>{};
      table.onPartEvent = (e) {
        if (e.code == MC.controlCollision) {
          kicks[e.part.name] = (kicks[e.part.name] ?? 0) + 1;
        }
      };
      final t = part<PopupTargetPart>('a_targ8');
      final c = t.visual.walls.first as WallPolygon;
      // Straight at a corner.
      shoot(c.points[0] - 0.9, c.points[1] + 0.9, 20, -20);
      run(0.3);
      expect(kicks['a_targ8'] ?? 0, lessThanOrEqualTo(1));
    });

    test('a slingshot kicks', () {
      final s = part<WallPart>('v_rebo1');
      final poly = s.visual.walls.first as WallPolygon;
      var cx = 0.0, cy = 0.0;
      for (var i = 0; i < poly.points.length; i += 2) {
        cx += poly.points[i] / poly.length;
        cy += poly.points[i + 1] / poly.length;
      }
      // Fire at its centre from the inner side of the table.
      final dirX = -cx.sign;
      final ball = shoot(cx + dirX * 1.5, cy - 0.3, -dirX * 12, 2);
      run(0.3);
      expect(reported('v_rebo1'), isTrue);
      expect(ball.speed, greaterThan(10));
    });
  });
}
