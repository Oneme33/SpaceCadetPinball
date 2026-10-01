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

/// The ported Space Cadet rules on the original table, with the messages
/// from the user's Pinball.exe. Skipped when the originals are missing.
void main() {
  final dat = File('assets/original/PINBALL.DAT');
  final json = File('assets/original/strings.json');
  final skip = dat.existsSync() && json.existsSync()
      ? null
      : 'original PINBALL.DAT / strings.json not installed';

  setUpAll(PhysicsWorld.initialize);

  group('original rules', skip: skip, () {
    late PhysicsWorld physics;
    late SpaceCadetTable table;
    late OriginalRules rules;
    late ScoreManager score;
    late TextBox info, mission;
    late int gameOvers;
    var highScores = <int>[];

    setUp(() {
      final layout = TableLayout.fromData(
        PinballData.parse(dat.readAsBytesSync()),
      );
      physics = PhysicsWorld(
        gravity: layout.gravity,
        maxSpeed: layout.ballMaxSpeed,
      );
      table = SpaceCadetTable(physics, layout, random: math.Random(7));
      score = ScoreManager();
      gameOvers = 0;
      highScores = [];
      final strings = {
        for (final e in (jsonDecode(
          json.readAsStringSync(),
        ) as Map<String, dynamic>).entries)
          int.parse(e.key): e.value as String,
      };
      late final OriginalRules r;
      info = TextBox(onTimerExpired: () => r.infoPart.expired());
      mission = TextBox(onTimerExpired: () => r.missionPart.expired());
      r = rules = OriginalRules(
        table: table,
        score: score,
        info: info,
        mission: mission,
        strings: strings,
        hooks: RulesHooks(
          onGameOver: () => gameOvers++,
          loadHighScores: () => highScores,
          saveHighScores: (s) => highScores = s,
        ),
        random: math.Random(7),
      );
      table.onPartEvent = (e) {
        if (e.code == MC.controlTimerExpired &&
            e.part is LightPart &&
            !rules.controls.containsKey(e.part.name)) {
          return;
        }
        rules.handler(e.code, e.part);
      };
    });

    tearDown(() => physics.destroy());

    void run(double seconds) {
      for (var t = 0.0; t < seconds; t += 1 / 60) {
        physics.advance(1 / 60);
        info.update(1 / 60);
        mission.update(1 / 60);
      }
    }

    /// New game, light show (5 s without sound lengths) and first ball.
    void newGame() {
      rules.t.message(MC.newGame, 1);
      run(6.5);
    }

    void drainNow() {
      final b = table.balls.first;
      b.placeAt(0, 13.9);
      b.body.linearVelocity = Vector2(0, 8);
      run(0.3);
    }

    test('every control function is linked to a component', () {
      for (final name in rules.controls.keys) {
        expect(table.part(name), isNotNull, reason: name);
      }
    });

    test('a new game greets player 1 and feeds the first ball', () {
      newGame();
      expect(info.text, 'Player 1');
      expect(table.balls, hasLength(1));
      expect(rules.t.ballCount, TableState.maxBallCount);
      expect(rules.lite200.isLit, isTrue, reason: 'Re-Deploy lit');
    });

    test('an attack bumper scores 500 through BumperControl', () {
      newGame();
      table.removeAllBalls();
      final scored = <String, int>{};
      final handler = table.onPartEvent!;
      table.onPartEvent = (e) {
        final before = score.score;
        handler(e);
        if (score.score != before) {
          scored[e.part.name] =
              (scored[e.part.name] ?? 0) + score.score - before;
        }
      };
      table.addBall(0.01, -2.6).body.linearVelocity = Vector2(0, -8);
      run(0.2);
      expect(scored['a_bump1'], 500);
    });

    test('a drain while Re-Deploy is lit costs no ball', () {
      newGame();
      drainNow();
      expect(info.text, 'Re-Deploy');
      run(3.5);
      expect(rules.t.ballCount, TableState.maxBallCount);
      expect(table.balls, hasLength(1));
    });

    test('a drain without Re-Deploy costs a ball and feeds the next', () {
      newGame();
      rules.lite200.message(MC.tLightResetAndTurnOff, 0);
      drainNow();
      expect(rules.t.ballCount, TableState.maxBallCount - 1);
      run(3.5);
      expect(table.balls, hasLength(1));
    });

    test('three lost balls end the game', () {
      newGame();
      for (var i = 0; i < 3; i++) {
        rules.lite200.message(MC.tLightResetAndTurnOff, 0);
        drainNow();
        run(3.5);
      }
      expect(rules.t.ballCount, 0);
      expect(info.text, 'Game Over');
      run(3.5);
      expect(gameOvers, 1);
    });

    test('a game over with a score enters the high score table', () {
      newGame();
      score.add(12345);
      for (var i = 0; i < 3; i++) {
        rules.lite200.message(MC.tLightResetAndTurnOff, 0);
        drainNow();
        run(3.5);
      }
      expect(highScores.first, greaterThanOrEqualTo(12345));
      expect(highScores, hasLength(1));
    });

    test('the high score table keeps the best five', () {
      highScores = [50000, 40000, 30000, 20000, 10000];
      score.score = 25000;
      expect(rules.checkHighScore(), isTrue);
      expect(highScores, [50000, 40000, 30000, 25000, 20000]);
      score.score = 5000;
      expect(rules.checkHighScore(), isFalse);
    });

    test('a long game runs every rule without errors', () {
      newGame();
      final random = math.Random(11);
      // Launch, then flip whenever the ball is near the flippers, for two
      // minutes of game time, refeeding as the rules do.
      table.pressPlunger();
      run(1.2);
      table.releasePlunger();
      for (var t = 0.0; t < 120; t += 1 / 60) {
        final near = table.balls.any((b) => b.y > 10.8 && b.y < 13.2);
        final flip = near && random.nextDouble() < 0.9;
        table
          ..setFlipper(left: true, pressed: flip)
          ..setFlipper(left: false, pressed: flip);
        if (table.balls.any((b) => b.x < -6.3 && b.y > 11 && b.speed < 0.5)) {
          table.pressPlunger();
          run(1);
          table.releasePlunger();
        }
        physics.advance(1 / 60);
        info.update(1 / 60);
        mission.update(1 / 60);
      }
      expect(score.score, greaterThan(0));
    });
  });
}
