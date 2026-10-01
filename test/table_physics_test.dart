import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/dat/pinball_data.dart';
import 'package:space_cadet/game/physics/physics_world.dart';
import 'package:space_cadet/game/physics/plunger.dart';
import 'package:space_cadet/game/table/parts/solid_parts.dart';
import 'package:space_cadet/game/table/space_cadet_table.dart';
import 'package:space_cadet/game/table/table_layout.dart';

/// Integration tests of the physical table. They run on the placeholder
/// layout (always available) and, when installed, on the original DAT.
void main() {
  setUpAll(PhysicsWorld.initialize);

  final dat = File('assets/original/PINBALL.DAT');
  final layouts = <String, TableLayout Function()>{
    'placeholder': TableLayout.placeholder,
    if (dat.existsSync())
      'original': () =>
          TableLayout.fromData(PinballData.parse(dat.readAsBytesSync())),
  };

  for (final MapEntry(key: name, value: makeLayout) in layouts.entries) {
    group('$name table', () {
      late PhysicsWorld physics;
      late SpaceCadetTable table;
      late List<TableEvent> events;

      setUp(() {
        final layout = makeLayout();
        physics = PhysicsWorld(
          gravity: layout.gravity,
          maxSpeed: layout.ballMaxSpeed,
        );
        table = SpaceCadetTable(physics, layout, random: math.Random(1));
        events = [];
        table.onEvent = events.add;
      });

      tearDown(() => physics.destroy());

      void run(double seconds) {
        for (var t = 0.0; t < seconds; t += 1 / 60) {
          physics.advance(1 / 60);
        }
      }

      test('a fed ball comes to rest on the plunger', () {
        final ball = table.feedBall();
        run(2);
        expect(table.plunger.touches(ball), isTrue);
        expect(ball.speed, lessThan(0.5));
        expect(table.balls, hasLength(1));
      });

      test('a full pull launches the ball up the lane at top speed', () {
        final ball = table.feedBall();
        run(1.5);
        table.plunger.press();
        run(2.6);
        expect(table.plunger.boost, Plunger.maxPullback);
        final y0 = ball.y;
        table.plunger.release();
        physics.advance(1 / 60);
        expect(events, contains(TableEvent.ballLaunched));
        expect(ball.body.linearVelocity.y, lessThan(-50));
        run(0.2);
        expect(ball.y, lessThan(y0 - 5));
      });

      test('flippers reach full extension in the original time', () {
        final f = table.leftFlipper;
        table.setFlipper(left: true, pressed: true);
        run(0.05);
        expect(f.extension, closeTo(1, 1e-3));
        expect(f.angle, closeTo(f.spec.angleMax, 1e-3));
        table.setFlipper(left: true, pressed: false);
        run(0.1);
        expect(f.extension, closeTo(0, 1e-3));
        expect(events, contains(TableEvent.flipperUp));
      });

      test('flippers are mirror images', () {
        final l = table.leftFlipper.spec, r = table.rightFlipper.spec;
        expect(l.originX, closeTo(-r.originX, 1e-3));
        expect(l.angleMax, closeTo(-r.angleMax, 1e-3));
      });

      test('a ball between the flippers drains', () {
        table.addBall(0, 12.5);
        run(2);
        expect(events, contains(TableEvent.ballDrained));
        expect(table.balls, isEmpty);
      });

      test('a flipper swing sends the ball up the table at speed', () {
        // Ball rolling down the lowered left flipper, then a swing.
        final f = table.layout.leftFlipper;
        final ball = table.addBall(
          (f.originX + f.restTipX) / 2,
          f.originY - 0.2,
        );
        run(0.5);
        expect(table.balls, hasLength(1));
        table.setFlipper(left: true, pressed: true);
        run(0.1);
        expect(ball.body.linearVelocity.y, lessThan(-40));
        expect(ball.y, lessThan(f.originY - 3));
      });

      // Easy mode: with the centre post up, the longer flippers close the
      // gaps beside it, so a ball falling between the flippers stays.
      for (final length in [1.0, 1.25]) {
        test('flippers of length $length beside the centre post', () {
          final post = table.parts.whereType<BlockerPart>().firstOrNull;
          if (post == null) return; // The placeholder has none.
          post.raise();
          table
            ..leftFlipper.length = length
            ..rightFlipper.length = length;
          var drained = 0;
          for (final x in [-0.5, -0.45, 0.0, 0.45, 0.5]) {
            events.clear();
            table.addBall(x, 12.0);
            run(3);
            if (events.contains(TableEvent.ballDrained)) drained++;
            table.removeAllBalls();
          }
          if (length == 1) {
            expect(drained, greaterThan(0));
          } else {
            expect(drained, 0);
          }
        });
      }
    });
  }
}
