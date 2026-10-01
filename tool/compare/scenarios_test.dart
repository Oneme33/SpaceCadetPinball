// Plays the reference scenarios (see tool/compare/README.md) on this port
// and writes the ball's track as CSV, in the same format as the harness
// around the decompilation, so the two can be laid side by side.
//
//   SCENARIOS=tool/compare/scenarios.txt OUT=/tmp/port.csv \
//     flutter test tool/compare/scenarios_test.dart
//
// Skipped without SCENARIOS, so a plain `flutter test` leaves it alone.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d/forge2d.dart';
import 'package:space_cadet/dat/pinball_data.dart';
import 'package:space_cadet/game/physics/physics_world.dart';
import 'package:space_cadet/game/rules/message_code.dart';
import 'package:space_cadet/game/rules/original_rules.dart';
import 'package:space_cadet/game/rules/score_manager.dart';
import 'package:space_cadet/game/table/parts/light_part.dart';
import 'package:space_cadet/game/table/space_cadet_table.dart';
import 'package:space_cadet/game/table/table_layout.dart';
import 'package:space_cadet/game/ui/text_box.dart';

/// No random sideways push, as the harness runs the original without it.
class _NoRandom implements math.Random {
  _NoRandom(this._r);
  final math.Random _r;
  @override
  double nextDouble() => 0.5;
  @override
  bool nextBool() => _r.nextBool();
  @override
  int nextInt(int max) => _r.nextInt(max);
}

class _Scenario {
  _Scenario(this.name, this.duration);
  final String name;
  final double duration;
  List<double>? ball;
  final events = <(double, String)>[];
}

List<_Scenario> _read(String path) {
  final list = <_Scenario>[];
  _Scenario? cur;
  for (final raw in File(path).readAsLinesSync()) {
    final w = raw.trim().split(RegExp(r'\s+'));
    if (w.first.isEmpty || w.first.startsWith('#')) continue;
    switch (w.first) {
      case 'scenario':
        cur = _Scenario(w[1], double.parse(w[2]));
      case 'ball':
        cur!.ball = [for (final v in w.skip(1)) double.parse(v)];
      case 'at':
        cur!.events.add((double.parse(w[1]), w[2]));
      case 'end':
        list.add(cur!);
    }
  }
  return list;
}

void main() {
  final scenarios = Platform.environment['SCENARIOS'];
  final out = Platform.environment['OUT'];
  final dat = File('assets/original/PINBALL.DAT');
  final json = File('assets/original/strings.json');

  setUpAll(PhysicsWorld.initialize);

  test('reference scenarios', skip: scenarios == null || out == null, () {
    final strings = {
      for (final e in (jsonDecode(
        json.readAsStringSync(),
      ) as Map<String, dynamic>).entries)
        int.parse(e.key): e.value as String,
    };
    final data = PinballData.parse(dat.readAsBytesSync());
    final csv = StringBuffer('scenario,t,x,y,z,vx,vy,mask\n');
    for (final s in _read(scenarios!)) {
      final layout = TableLayout.fromData(data);
      final physics = PhysicsWorld(
        gravity: layout.gravity,
        maxSpeed: layout.ballMaxSpeed,
      );
      final table = SpaceCadetTable(
        physics,
        layout,
        random: _NoRandom(math.Random(1)),
      );
      late final OriginalRules rules;
      final info = TextBox(onTimerExpired: () => rules.infoPart.expired());
      final mission = TextBox(
        onTimerExpired: () => rules.missionPart.expired(),
      );
      rules = OriginalRules(
        table: table,
        score: ScoreManager(),
        info: info,
        mission: mission,
        strings: strings,
        hooks: const RulesHooks(),
        random: math.Random(1),
      );
      table.onPartEvent = (e) {
        if (e.code == MC.controlTimerExpired &&
            e.part is LightPart &&
            !rules.controls.containsKey(e.part.name)) {
          return;
        }
        rules.handler(e.code, e.part);
      };
      void step(double dt) {
        physics.advance(dt);
        info.update(dt);
        mission.update(dt);
      }

      rules.t.message(MC.newGame, 1);
      for (var i = 0; i < 800; i++) {
        step(0.01);
      }
      var ball = table.balls.first;
      if (s.ball case [final x, final y, final vx, final vy]) {
        // A fresh ball, as the harness places one.
        table.removeAllBalls();
        ball = table.addBall(x, y);
        ball.body.linearVelocity = Vector2(vx, vy);
      }
      var next = 0;
      final frames = (s.duration * 100).round();
      for (var i = 0; i <= frames; i++) {
        final t = i / 100;
        while (next < s.events.length && s.events[next].$1 <= t + 1e-6) {
          switch (s.events[next++].$2) {
            case 'leftDown':
              table.setFlipper(left: true, pressed: true);
            case 'leftUp':
              table.setFlipper(left: true, pressed: false);
            case 'rightDown':
              table.setFlipper(left: false, pressed: true);
            case 'rightUp':
              table.setFlipper(left: false, pressed: false);
            case 'plungerDown':
              table.pressPlunger();
            case 'plungerUp':
              table.releasePlunger();
          }
        }
        if (table.balls.contains(ball)) {
          final v = ball.body.linearVelocity;
          csv.writeln(
            '${s.name},${t.toStringAsFixed(4)},${ball.x.toStringAsFixed(4)},'
            '${ball.y.toStringAsFixed(4)},${ball.z.toStringAsFixed(4)},'
            '${v.x.toStringAsFixed(4)},${v.y.toStringAsFixed(4)},'
            '${ball.layers}',
          );
        } else {
          csv.writeln('${s.name},${t.toStringAsFixed(4)},,,,,,');
        }
        step(0.01);
      }
      physics.destroy();
    }
    File(out!).writeAsStringSync(csv.toString());

    // The walls in table space, for drawing the tracks over.
    if (Platform.environment['WALLS'] case final walls?) {
      List<Object> shape(WallShape w) => switch (w) {
        WallPolygon(:final points) => ['poly', ...points],
        WallLine(:final x1, :final y1, :final x2, :final y2) => [
          'line',
          x1,
          y1,
          x2,
          y2,
        ],
        WallCircle(:final x, :final y, :final radius) => [
          'circle',
          x,
          y,
          radius,
        ],
      };
      File(walls).writeAsStringSync(
        jsonEncode({
          'outline': TableLayout.fromData(data).outline,
          'walls': [
            for (final c in data.components)
              if (c.states.isNotEmpty)
                for (final w in c.states.first.walls)
                  {'name': c.name, 'type': c.type.name, 'shape': shape(w)},
          ],
        }),
      );
    }
  });
}
