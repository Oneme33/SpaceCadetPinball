import 'dart:math' as math;

import '../../dat/pinball_data.dart' show Component, ComponentType;
import '../gameplay/game_timers.dart';
import '../table/parts/group_parts.dart';
import '../table/parts/light_part.dart';
import '../table/parts/part.dart';
import '../table/parts/ramp_part.dart';
import '../table/parts/sensor_parts.dart';
import '../table/parts/solid_parts.dart';
import '../table/parts/table_proxies.dart';
import '../table/space_cadet_table.dart';
import '../ui/text_box.dart';
import 'message_code.dart';
import 'score_manager.dart';

part 'original_rules_port.dart';

/// The original Space Cadet rule set: `control.cpp` and the table-level
/// game flow of `TPinballTable::Message`, ported from the decompilation.
///
/// Every component event goes to [handler], which runs the component's
/// control function (scoring, lights, missions) and then `MissionControl`,
/// as the original does. The texts come from the user's own Pinball.exe.
class OriginalRules extends _RulesBase
    with _Components, _ScoreTables, _Functions {
  OriginalRules({
    required super.table,
    required super.score,
    required super.info,
    required super.mission,
    required super.strings,
    required super.hooks,
    super.random,
  });

  /// `control::handler`.
  void handler(int code, TablePart? part) {
    if (part != null) {
      final control = controls[part.name];
      control?.$1(code, part);
    }
    missionControl(code, part);
  }

  @override
  int _scoring(TablePart? part, int index) {
    if (part == null) return 0;
    final scores = controls[part.name]?.$2;
    if (scores == null || index < 0 || index >= scores.length) return 0;
    return scores[index];
  }
}

/// What the rules ask of the game around them.
class RulesHooks {
  const RulesHooks({this.onGameOver, this.onFeedBall, this.onDrainCollision});

  /// `TPinballTable::Message(GameOver)` finished (after its 3 s).
  final void Function()? onGameOver;

  /// The plunger feeds a new ball.
  final void Function()? onFeedBall;

  /// A ball went down the drain.
  final void Function()? onDrainCollision;
}

/// The table-level state the rules read and change (`TPinballTable`).
class TableState {
  // ignore: library_private_types_in_public_api
  TableState(this._rules);

  final _RulesBase _rules;
  ScoreManager get _score => _rules.score;

  static const maxBallCount = 3;

  int get scoreMultiplier => _score.multiplierIndex;
  set scoreMultiplier(int v) => _score.multiplierIndex = v;
  int get jackpotScore => _score.jackpot;
  set jackpotScore(int v) => _score.jackpot = v;
  bool get jackpotScoreFlag => _score.jackpotActive;
  set jackpotScoreFlag(bool v) => _score.jackpotActive = v;
  int get bonusScore => _score.bonus;
  set bonusScore(int v) => _score.bonus = v;
  bool get bonusScoreFlag => _score.bonusActive;
  set bonusScoreFlag(bool v) => _score.bonusActive = v;
  int get curScore => _score.score;

  int multiballCount = 0;
  int ballLockedCounter = 0;
  int reflexShotScore = 0;
  int extraBalls = 0;
  bool tiltLockFlag = false;
  int playerCount = 1;
  bool multiballFlag = false;
  int currentPlayer = 0;
  int ballCount = 0;
  int unknownP78 = 0;
  int cheatsUsed = 0;
  bool _replayActive = false;

  int? _lightShowTimer, _endGameTimer, _replayTimer;

  /// Every light on the table, for light shows (`TPinballTable::LightGroup`).
  late final AllLights lightGroup = AllLights(_rules.table);

  void changeBallCount(int count) => ballCount = count;

  /// Single player: player 0 is the current score; others do not exist.
  int playerScore(int player) => player == 0 ? curScore : -1;

  /// No high score table yet: nothing to show.
  int highScore(int index) => 0;

  /// `TPinballTable::Message` for the codes the game flow uses.
  int message(int code, double value) {
    final r = _rules;
    switch (code) {
      case MC.leftFlipperInputReleased:
      case MC.clearTiltLock:
        lightGroup.message(MC.tLightResetTimed, 0);
        tiltLockFlag = false;
      case MC.startGamePlayer1:
        lightGroup
          ..message(MC.tLightGroupReset, 0)
          ..message(MC.tLightResetAndTurnOff, 0);
        r.plungerPart.message(MC.plungerStartFeedTimer, 0);
        r.info.display(r.rc(127), -1);
      case MC.newGame:
        if (_endGameTimer case final t?) {
          r.timers.cancel(t);
          _endGameTimer = null;
        }
        if (_lightShowTimer case final t?) {
          r.timers.cancel(t);
          _lightShowTimer = null;
          message(MC.startGamePlayer1, 0);
        } else {
          cheatsUsed = 0;
          message(MC.reset, 0);
          playerCount = 1;
          currentPlayer = 0;
          _score.reset();
          ballCount = maxBallCount;
          changeBallCount(ballCount);
          jackpotScoreFlag = false;
          bonusScoreFlag = false;
          r.info.clear();
          r.mission.clear();
          lightGroup.message(MC.tLightGroupLightShowAnimation, 0.2);
          var time = r.table.playTableSound(start: true);
          if (time < 0) time = 5;
          _lightShowTimer = r.timers.set(time, () {
            _lightShowTimer = null;
            message(MC.startGamePlayer1, 0);
          });
        }
      case MC.plungerRelaunchBall:
        if (_replayTimer case final t?) r.timers.cancel(t);
        _replayTimer = r.timers.set(value.floorToDouble(), () {
          _replayTimer = null;
          _replayActive = false;
          r.plungerPart.message(MC.plungerRelaunchBall, 0);
        });
        _replayActive = true;
      case MC.switchToNextPlayer:
        // Single player: show who is up again.
        r.info.display(r.rc(127), -1);
        jackpotScoreFlag = false;
        bonusScoreFlag = false;
      case MC.gameOver:
        r.table.playTableSound(start: false);
        r.mission.clear();
        r.info.display(r.rc(135), -1);
        _endGameTimer = r.timers.set(3, () {
          _endGameTimer = null;
          r.hooks.onGameOver?.call();
        });
      case MC.reset:
        for (final p in r.table.parts) {
          p.message(MC.reset, 0);
        }
        r.plungerPart.message(MC.reset, 0);
        if (_replayTimer case final t?) r.timers.cancel(t);
        _replayTimer = null;
        if (_lightShowTimer case final t?) {
          r.timers.cancel(t);
          lightGroup.message(MC.tLightGroupReset, 0);
        }
        _lightShowTimer = null;
        scoreMultiplier = 0;
        _score.scoreAdded = 0;
        reflexShotScore = 0;
        bonusScore = 10000;
        bonusScoreFlag = false;
        jackpotScore = 20000;
        jackpotScoreFlag = false;
        extraBalls = 0;
        multiballCount = 0;
        ballLockedCounter = 0;
        multiballFlag = false;
        unknownP78 = 0;
        _replayActive = false;
        tiltLockFlag = false;
    }
    r.tableControlHandler(code);
    return 0;
  }

  bool get replayActive => _replayActive;
}

/// `TPinballTable::LightGroup`: every light, for light shows.
class AllLights {
  AllLights(this.table);
  final SpaceCadetTable table;

  late final List<LightPart> _lights = table.parts
      .whereType<LightPart>()
      .toList();

  int message(int code, double value) {
    switch (code) {
      case MC.tLightGroupLightShowAnimation:
        for (final l in _lights) {
          if (table.random.nextInt(100) > 70) {
            l.turnOnTimed(table.random.nextDouble() * value * 3 + 0.1);
          }
        }
      case MC.tLightGroupReset:
        for (final l in _lights) {
          l.resetTimed();
        }
      default:
        for (final l in _lights) {
          l.message(code, value);
        }
    }
    return 0;
  }
}

abstract class _RulesBase {
  _RulesBase({
    required this.table,
    required this.score,
    required this.info,
    required this.mission,
    required this.strings,
    required this.hooks,
    math.Random? random,
  }) : _random = random ?? math.Random();

  final SpaceCadetTable table;
  final ScoreManager score;
  final TextBox info, mission;

  /// Messages from Pinball.exe by resource id (see `STRINGnnn`).
  final Map<int, String> strings;
  final RulesHooks hooks;
  final math.Random _random;

  late final TableState t = TableState(this);

  late final TextBoxPart infoPart = _textBoxPart('info_text_box', info);
  late final TextBoxPart missionPart = _textBoxPart(
    'mission_text_box',
    mission,
  );

  TextBoxPart _textBoxPart(String name, TextBox box) => TextBoxPart(
    table.partContext,
    table.layout.byName(name) ??
        Component(
          type: ComponentType.textBox,
          group: -1,
          name: name,
          states: const [],
        ),
    box,
  );

  /// The table's physics-time timers (they stop with the simulation).
  GameTimers get timers => table.timers;

  bool get fullTiltMode => false;
  bool easyMode = false;
  bool tableUnlimitedBalls = false;
  int extraballLightFlag = 0;
  int waitingDeploymentFlag = 0;

  /// `control.cpp` rank and mission names, and mission select scores.
  List<int> get rankRcArray => _rankRcArray;
  List<int> get missionRcArray => _missionRcArray;
  List<int> get missionSelectScores => _missionSelectScores;

  int _scoring(TablePart? part, int index);

  TablePart _part(String name) =>
      table.part(name) ?? (throw StateError('missing component $name'));

  PlungerPart get plungerPart => table.plungerPart;

  /// `pb::get_rc_string(Msg::STRINGnnn)`: resource id nnn − 101.
  String rc(int msg) => strings[msg - 101] ?? '[STRING$msg]';

  /// `snprintf` for the original formats: %s, %d and %ld.
  String fmt(String format, List<Object?> args) {
    var i = 0;
    return format.replaceAllMapped(
      RegExp('%(ld|d|s)'),
      (_) => i < args.length ? '${args[i++]}' : '',
    );
  }

  int scoring(TablePart? part, int index) => _scoring(part, index);

  int addScore(int points) => score.add(points);

  /// C++ truthiness: 0, false and null are false.
  bool _b(Object? v) => switch (v) {
    null => false,
    final bool b => b,
    final int i => i != 0,
    _ => true,
  };

  double randFloat() => _random.nextDouble();
  int randInt() => _random.nextInt(0x7FFF);

  /// High scores are not kept yet.
  /// TODO: VERIFY AGAINST ORIGINAL SPACE CADET — high score table (Phase 7).
  bool checkHighScore() => false;

  void onGameOverMode() {}

  void tableControlHandler(int code);
}

const _rankRcArray = [185, 186, 187, 188, 189, 190, 191, 192, 193];
const _missionRcArray = [
  161, 162, 163, 164, 165, 166, 167, 168, 169, //
  170, 171, 172, 173, 174, 175, 176, 177,
];
const _missionSelectScores = [
  10000, 10000, 10000, 10000, 20000, 20000, 20000, 20000, 20000, //
  20000, 20000, 20000, 20000, 30000, 30000, 30000, 30000,
];
