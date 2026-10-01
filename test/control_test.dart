import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d/forge2d.dart';
import 'package:space_cadet/dat/pinball_data.dart';
import 'package:space_cadet/game/physics/physics_world.dart';
import 'package:space_cadet/game/rules/control.dart';
import 'package:space_cadet/game/rules/score_manager.dart';
import 'package:space_cadet/game/table/parts/solid_parts.dart';
import 'package:space_cadet/game/table/space_cadet_table.dart';
import 'package:space_cadet/game/table/table_layout.dart';
import 'package:space_cadet/game/ui/text_box.dart';

/// The ported rules on the original table. Skipped without the DAT.
void main() {
  final file = File('assets/original/PINBALL.DAT');
  final skip = file.existsSync() ? null : 'original PINBALL.DAT not installed';
  setUpAll(PhysicsWorld.initialize);

  group('control', skip: skip, () {
    late PhysicsWorld physics;
    late SpaceCadetTable table;
    late ScoreManager score;

    setUp(() {
      final layout = TableLayout.fromData(
        PinballData.parse(file.readAsBytesSync()),
      );
      physics = PhysicsWorld(
        gravity: layout.gravity,
        maxSpeed: layout.ballMaxSpeed,
      );
      table = SpaceCadetTable(physics, layout, random: math.Random(5));
      score = ScoreManager();
      final control = Control(
        table: table,
        score: score,
        info: TextBox(),
        mission: TextBox(),
      );
      table.onPartEvent = control.handle;
    });

    tearDown(() => physics.destroy());

    void run(double s) {
      for (var t = 0.0; t < s; t += 1 / 120) {
        physics.advance(1 / 120);
      }
    }

    test('an attack bumper scores by its level', () {
      table.addBall(0.01, -2.6).body.linearVelocity = Vector2(0, -8);
      run(0.15);
      expect(score.score, 500);

      (table.part('a_bump1')! as BumperPart).setLevel(3);
      table.removeAllBalls();
      run(0.5);
      table.addBall(0.01, -2.6).body.linearVelocity = Vector2(0, -8);
      run(0.15);
      expect(score.score, 500 + 2000);
    });

    test('a lower slingshot scores 500 and flashes its light', () {
      final s = table.part('v_rebo1')!;
      final poly = s.visual.walls.first as WallPolygon;
      var cx = 0.0, cy = 0.0;
      for (var i = 0; i < poly.points.length; i += 2) {
        cx += poly.points[i] / poly.length;
        cy += poly.points[i + 1] / poly.length;
      }
      final dir = -cx.sign;
      table.addBall(cx + dir * 1.5, cy - 0.3).body.linearVelocity = Vector2(
        -dir * 12,
        2,
      );
      run(0.3);
      expect(score.score, greaterThanOrEqualTo(500));
      expect(score.score % 500, 0);
    });
  });
}
