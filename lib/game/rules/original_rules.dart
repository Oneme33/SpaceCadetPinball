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

  /// Longest wait from New Game to the first ball (see `NewGame`).
  static const startDelay = 1.0;

  /// Length of the high score table.
  static const highScoreCount = _RulesBase.highScoreCount;

  /// `control::handler`.
  void handler(int code, TablePart? part) {
    if (part != null) {
      final control = controls[part.name];
      control?.$1(code, part);
    }
    missionControl(code, part);
  }

  /// The "easy mode" cheat of the decompilation (control.cpp, typed as a
  /// cheat or picked from its debug menu): the centre post goes up for
  /// good and the kickback gates open, and with [easyMode] set neither
  /// times out. `PlungerControl` raises the post again for every new ball.
  void setEasyMode(bool on) {
    if (easyMode == on) return;
    easyMode = on;
    if (on) {
      drainBallBlockerControl(MC.tBlockerEnable, block1);
      gate1.message(MC.tGateDisable, 0.0);
      gate2.message(MC.tGateDisable, 0.0);
    } else {
      drainBallBlockerControl(MC.controlTimerExpired, block1);
    }
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
  const RulesHooks({
    this.onGameOver,
    this.onSpecialAward,
    this.loadHighScores,
    this.saveHighScores,
  });

  /// The high score table, best first (kept by the game's settings).
  final List<int> Function()? loadHighScores;
  final void Function(List<int> scores)? saveHighScores;

  /// `TPinballTable::Message(GameOver)` finished (after its 3 s).
  final void Function()? onGameOver;

  /// Extra ball, replay or jackpot: a special award (for haptics).
  final void Function()? onSpecialAward;
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

  bool get tiltLockFlag => _rules.table.tilted;
  set tiltLockFlag(bool v) => _rules.table.tilted = v;
  int playerCount = 1;
  bool multiballFlag = false;
  int currentPlayer = 0;
  int ballCount = 0;
  int unknownP78 = 0;
  int cheatsUsed = 0;
  bool _replayActive = false;

  int? _lightShowTimer, _endGameTimer, _replayTimer, _tiltTimer;

  /// `TPinballTable::tilt`: the table locks until the ball drains.
  void tilt() {
    final r = _rules;
    if (tiltLockFlag || r.table.drainPart.waiting) return;
    r.info.clear();
    r.mission.clear();
    r.info.display(r.rc(136), -1);
    r.table.playTableSound(tilt: true);
    if (_tiltTimer case final t?) r.timers.cancel(t);
    _tiltTimer = r.timers.set(30, () {
      _tiltTimer = null;
      if (tiltLockFlag) r.table.drainAll();
    });
    for (final p in r.table.parts) {
      p.message(MC.setTiltLock, 0);
    }
    lightGroup.message(MC.tLightTurnOffTimed, 0);
    tiltLockFlag = true;
    r.tableControlHandler(MC.setTiltLock);
  }

  /// Every light on the table, for light shows (`TPinballTable::LightGroup`).
  late final AllLights lightGroup = AllLights(_rules.table);

  void changeBallCount(int count) => ballCount = count;

  /// Single player: player 0 is the current score; others do not exist.
  int playerScore(int player) => player == 0 ? curScore : -1;

  /// `high_score::highscore_table[index].Score`: 0 when empty.
  int highScore(int index) {
    final scores = _rules.hooks.loadHighScores?.call() ?? const <int>[];
    return index < scores.length ? scores[index] : 0;
  }

  /// `TPinballTable::Message` for the codes the game flow uses.
  int message(int code, double value) {
    final r = _rules;
    switch (code) {
      case MC.leftFlipperInputReleased:
      case MC.clearTiltLock:
        lightGroup.message(MC.tLightResetTimed, 0);
        if (tiltLockFlag) {
          tiltLockFlag = false;
          if (_tiltTimer case final t?) r.timers.cancel(t);
          _tiltTimer = null;
        }
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
          // Not original: the original feeds the first ball only when the
          // start tune (several seconds) has played; here after at most
          // [OriginalRules.startDelay], the tune and light show play on.
          time = math.min(time, OriginalRules.startDelay);
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

  /// Places of the high score table (`high_score.cpp`).
  static const highScoreCount = 5;

  /// `pb::chk_highscore`: enters the current score in the table when it
  /// makes the top five. The original then asks for a name; names are not
  /// kept here.
  bool checkHighScore() {
    final current = score.score;
    if (current <= 0) return false;
    final scores = [...?hooks.loadHighScores?.call()];
    if (scores.length >= highScoreCount && current <= scores.last) {
      return false;
    }
    scores
      ..add(current)
      ..sort((a, b) => b.compareTo(a));
    hooks.saveHighScores?.call(scores.take(highScoreCount).toList());
    return true;
  }

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
