import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../dat/pinball_data.dart';
import 'assets/original_assets.dart';
import 'audio/audio_manager.dart';
import 'debug/debug_layer.dart';
import 'game_config.dart';
import 'feedback/haptic_manager.dart';
import 'game_state.dart';
import 'graphics.dart';
import 'settings.dart';
import 'gameplay/game_timers.dart';
import 'gameplay/nudge.dart';
import 'input/input_bindings.dart';
import 'physics/physics_world.dart';
import 'rules/message_code.dart';
import 'rules/original_rules.dart';
import 'rules/score_manager.dart';
import 'table/ball_renderer.dart';
import 'table/camera_projection.dart';
import 'table/parts/light_part.dart';
import 'table/parts/sensor_parts.dart';
import 'table/parts/solid_parts.dart';
import 'table/parts/table_proxies.dart';
import 'table/parts/part.dart';
import 'table/placeholder_table.dart';
import 'table/space_cadet_table.dart';
import 'table/table_art.dart';
import 'table/table_layout.dart';
import 'table/table_projection.dart';
import 'table/table_sprites.dart';
import 'ui/cadet_car.dart';
import 'ui/debug_hud.dart';
import 'ui/scoreboard.dart';
import 'ui/text_box.dart';
import 'ui/screen_layout.dart';

/// Flame entry point. Wires input, state, physics and rendering together;
/// the actual logic lives in the classes it owns.
///
/// The Flame world is in screen space (the original 600 × 416 virtual
/// screen). Physics runs separately in table space, see [PhysicsWorld].
///
/// Two cameras look at that world: [camera] shows the playfield (or, in
/// the original landscape layout, the whole screen) and [scoreboardCamera]
/// shows the scoreboard on top in portrait. [ScreenLayout] decides.
class SpaceCadetGame extends FlameGame with KeyboardEvents {
  SpaceCadetGame()
    : super(
        camera: CameraComponent(
          viewport: FixedSizeViewport(
            GameConfig.screenWidth,
            GameConfig.screenHeight,
          ),
        ),
      );

  static const pauseOverlay = 'pause';
  static const attractOverlay = 'attract';
  static const gameOverOverlay = 'gameOver';

  late final GameStateMachine gameState = GameStateMachine(onChanged: _onPhase);
  final InputState input = InputState();
  final GameTimers timers = GameTimers();
  final ScoreManager score = ScoreManager();
  late final TextBox infoText = TextBox(
    onTimerExpired: () => rules.infoPart.expired(),
  );
  late final TextBox missionText = TextBox(
    onTimerExpired: () => rules.missionPart.expired(),
  );

  /// The original Space Cadet rules (control.cpp).
  late final OriginalRules rules;
  late final AudioManager audio;

  /// The score is shown once a game has been started.
  bool _scoreShown = false;

  late final PhysicsWorld physics;
  late final TableLayout layout;
  late final TableProjection projection;
  late final SpaceCadetTable table;

  late final CameraComponent scoreboardCamera = CameraComponent(
    world: world,
    viewport: FixedSizeViewport(0, 0),
  );
  ScreenLayout layoutOnScreen = ScreenLayout.compute(
    const Size(GameConfig.screenWidth, GameConfig.screenHeight),
  );

  /// Null when the original files are not installed.
  OriginalAssets? originals;

  /// Classic or HD art.
  final Graphics graphics = Graphics();

  late final Settings settings;

  /// Table bumps and the tilt counter.
  late final Nudge nudge = Nudge(
    push: (dx, dy) => table.pushBalls(dx, dy),
    shift: (x, y) {
      _shiftX += x;
      _shiftY += y;
      _applyLayout();
    },
  );
  int _shiftX = 0, _shiftY = 0;
  late final HapticManager haptics = HapticManager(
    enabled: () => settings.haptics,
  );

  /// The cadet in his car, cut out of the scoreboard, for the menu: the
  /// classic and (once HD is loaded) the HD version.
  Image? _carClassic, _carHd;
  Image? get cadetCarImage =>
      graphics.hd ? (_carHd ?? _carClassic) : _carClassic;

  Future<void> _prepareCadetCar() async {
    final o = originals;
    if (o == null) return;
    try {
      final car = CadetCar.fromScoreboard(
        o.data.scoreboardBitmap,
        o.data.palette,
      );
      _carClassic = await car.cutOut(o.scoreboard, 1);
      final hd = graphics.hdImages[o.data.dat.indexOf('background')];
      if (hd != null) {
        _carHd = await car.cutOut(hd, hd.width ~/ o.scoreboard.width);
      }
    } on Object catch (e) {
      debugPrint('Cadet car not available: $e');
    }
  }

  /// Whether the HD set has been made (tool/make_hd.dart): checked once at
  /// load by looking for the playfield's HD bitmap.
  bool hdInstalled = false;

  void setSound(bool on) {
    settings.sound = on;
    audio.enabled = on;
    if (!on) audio.stopAll();
  }

  void setMusic(bool on) {
    settings.music = on;
    audio.musicEnabled = on;
  }

  /// Set by the first game: the original starts the music with a game
  /// (`pb::replay_level`) and keeps it looping from then on.
  bool _musicStarted = false;

  /// Longer flippers in easy mode, relative to the original.
  static const easyFlipperLength = 1.25;

  /// Whether the running game was played in easy mode at any point. Its
  /// scores then go to the easy high score table, so turning easy mode on
  /// for a moment and off again does not count as a normal game.
  bool _easyGame = false;

  /// Easy mode: the decompilation's "easy mode" cheat (the centre post
  /// stays up, the kickback gates stay open) plus longer flippers, which
  /// the original does not have.
  void setEasy(bool on) {
    settings.easy = on;
    if (on) _easyGame = true;
    for (final f in [table.leftFlipper, table.rightFlipper]) {
      f.length = on ? easyFlipperLength : 1;
    }
    rules.setEasyMode(on);
  }

  /// "New Game" in the pause menu: the running game ends, a new one
  /// starts.
  void newGameFromMenu() {
    gameState
      ..handle(GameEvent.resume)
      ..handle(GameEvent.ballDrained)
      ..handle(GameEvent.noBallsLeft);
    startGame();
  }

  /// Switches between classic and HD art, loading the HD set the first
  /// time. Does nothing when the HD set is not installed.
  Future<void> setHd(bool on) async {
    settings.hd = on;
    graphics.hdEnabled = on;
    final o = originals;
    if (on && !graphics.hdAvailable && o != null) {
      graphics.hdImages = await o.loadHd();
    }
    await _prepareCadetCar();
  }

  BallRenderer? ballRenderer;
  DebugLayer? _debugLayer;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    add(scoreboardCamera);
    _applyLayout();

    settings = await Settings.load();
    final originals = this.originals = await OriginalAssets.load();
    if (originals != null) {
      final camera = CameraProjection(originals.data.camera);
      layout = TableLayout.fromData(originals.data);
      projection = camera;
      ballRenderer = BallRenderer(
        camera,
        originals.ballSprites,
        layout.ballRadius,
        tableImage: originals.table,
        tableDepth: originals.tableDepth,
        zMin: originals.data.camera.zMin,
        zScaler: originals.data.camera.zScaler,
        tableGroup: originals.data.tableGroup,
        graphics: graphics,
      );
    } else {
      layout = TableLayout.placeholder();
      projection = LinearProjection(
        table: layout.bounds,
        screen: _fitted(layout.bounds, GameConfig.playfieldRect),
      );
    }

    physics = PhysicsWorld(
      gravity: layout.gravity,
      maxSpeed: layout.ballMaxSpeed,
    );
    audio = AudioManager(soundFiles: originals?.data.soundFiles ?? const {});
    table = SpaceCadetTable(physics, layout)
      ..onEvent = _onTableEvent
      ..playSound = audio.play
      ..soundDuration = ((g) => originals?.soundDurations[g] ?? -1)
      ..startSound = originals?.data.tableVisual.sound4
      ..gameOverSound = originals?.data.tableVisual.sound3
      ..tiltSound = originals?.data.tableVisual.hardHitSound;
    rules = OriginalRules(
      table: table,
      score: score,
      info: infoText,
      mission: missionText,
      strings: originals?.strings ?? const {},
      hooks: RulesHooks(
        onGameOver: _gameOver,
        onSpecialAward: () => haptics.play(Haptic.heavy),
        loadHighScores: () => settings.highScoresFor(easy: _easyGame),
        saveHighScores: (s) => settings.setHighScores(s, easy: _easyGame),
      ),
    );
    table
      ..onPartEvent = _onPartEvent
      ..onFlipperHit = (speed) {
        if (speed > 6) haptics.play(Haptic.heavy);
      };

    if (originals != null) {
      world.add(TableArt(originals, graphics));
      Future<void> sprite(ComponentType type, int Function(int) frame) async {
        final frames = await originals.framesFor(layout.ofType(type).first);
        world.add(
          ComponentSprite(frames, () => frame(frames.length), graphics),
        );
      }

      final withArt = [
        for (final p in table.parts)
          if (p.component.states.any((s) => s.bitmap != null)) p,
      ];
      final allFrames = await Future.wait([
        for (final p in withArt) originals.framesFor(p.component),
      ]);
      for (var i = 0; i < withArt.length; i++) {
        final p = withArt[i];
        world.add(ComponentSprite(allFrames[i], () => p.frame, graphics));
      }
      await sprite(ComponentType.plunger, (_) => table.plunger.frame);
      for (final (type, flipper) in [
        (ComponentType.flipperLeft, table.leftFlipper),
        (ComponentType.flipperRight, table.rightFlipper),
      ]) {
        final frames = await originals.framesFor(layout.ofType(type).first);
        final pivot = projection.toScreen(
          flipper.spec.originX,
          flipper.spec.originY,
        );
        world.add(FlipperSprite(frames, flipper, pivot, graphics));
      }
    } else {
      world
        ..add(PlaceholderTable())
        ..add(PlaceholderParts(table, projection));
    }
    world.add(BallsComponent(table, projection, ballRenderer));
    await _addScoreboard(originals);

    if (GameConfig.debug) {
      final layer = _debugLayer = DebugLayer(
        layout: layout,
        projection: projection,
        onPlaceBall: debugPlaceBall,
        flippers: [table.leftFlipper, table.rightFlipper],
      );
      world.add(layer);
      camera.viewport.add(DebugHud(game: this, layer: layer));
    }

    audio
      ..enabled = settings.sound
      ..musicEnabled = settings.music;
    if (originals != null) {
      try {
        await rootBundle.load(
          'assets/original/hd/g${originals.data.tableGroup}.png',
        );
        hdInstalled = true;
      } on Object {
        hdInstalled = false;
      }
    }
    if (settings.hd && hdInstalled) await setHd(true);
    await _prepareCadetCar();
    if (settings.easy) setEasy(true);

    gameState.handle(GameEvent.assetsLoaded);
  }

  Future<void> _addScoreboard(OriginalAssets? originals) async {
    Future<DigitField?> digits(String name) async {
      final field = originals?.data.scoreField(name);
      if (originals == null || field == null) return null;
      return DigitField(field, await originals.digits(field), graphics);
    }

    TextField? text(String name, TextBox box) {
      final r = originals?.data.textBoxRect(name);
      if (r == null) return null;
      final (x, y, w, h) = r;
      return TextField(
        box,
        Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
      );
    }

    world.add(
      ScoreboardComponent(
        score: await digits('score1'),
        ballCount: await digits('ballcount1'),
        playerNumber: await digits('player_number1'),
        info: text('info_text_box', infoText),
        mission: text('mission_text_box', missionText),
        values: () => (
          score: _scoreShown ? score.score : null,
          ball: _ballNumber,
          player: _scoreShown ? 1 : null,
        ),
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    layoutOnScreen = ScreenLayout.compute(Size(size.x, size.y));
    _applyLayout();
  }

  void _applyLayout() {
    final l = layoutOnScreen;
    // A table bump moves the board by a few pixels (`render::shift`).
    _aim(
      camera,
      l.tableView,
      l.tableSource.translate(-_shiftX * 1.0, -_shiftY * 1.0),
    );
    _aim(scoreboardCamera, l.scoreboardView, l.scoreboardSource);
  }

  static void _aim(CameraComponent cam, Rect? view, Rect? source) {
    if (view == null || source == null) {
      cam.viewport.size = Vector2.zero();
      return;
    }
    cam.viewport
      ..position = Vector2(view.left, view.top)
      ..size = Vector2(view.width, view.height);
    cam.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2(source.left, source.top)
      ..zoom = view.width / source.width;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState.isSimulating) {
      timers.update(dt);
      infoText.update(dt);
      missionText.update(dt);
      nudge.update(dt);
      if (!rules.t.tiltLockFlag) {
        if (nudge.count > Nudge.warnLevel) infoText.display(rules.rc(126), 2);
        if (nudge.count > Nudge.tiltLevel) rules.t.tilt();
      }
    }
    // In debug mode the table also runs outside a game, for testing.
    if (gameState.isSimulating || GameConfig.debug && !gameState.isPaused) {
      physics.advance(dt);
    }
  }

  @override
  void onRemove() {
    physics.destroy();
    super.onRemove();
  }

  // --- Game flow -----------------------------------------------------------

  /// The scoreboard's ball number: `MaxBallCount - BallCount + 1`, erased
  /// when no ball is left (`TPinballTable::ChangeBallCount`).
  int? get _ballNumber {
    final count = rules.t.ballCount;
    return count > 0 ? TableState.maxBallCount - count + 1 : null;
  }

  /// A new game the original way: `TPinballTable::Message(NewGame)` resets
  /// everything, runs the light show and then feeds the first ball.
  void startGame() {
    if (!gameState.handle(GameEvent.startGame)) return;
    timers.clear();
    table
      ..removeAllBalls()
      ..releaseControls()
      ..timers.clear();
    _scoreShown = true;
    _easyGame = settings.easy;
    _musicStarted = true;
    audio.playMusic();
    rules.t.message(MC.newGame, 1);
  }

  void _onTableEvent(TableEvent e) {
    switch (e) {
      case TableEvent.ballDrained:
        if (table.balls.isEmpty) gameState.handle(GameEvent.ballDrained);
      case TableEvent.ballFed:
        gameState.handle(GameEvent.nextBallReady);
        // `pb::tilt_no_more`.
        if (rules.t.tiltLockFlag) infoText.clear();
        rules.t.tiltLockFlag = false;
        nudge.reset();
      case TableEvent.ballLaunched:
        haptics.play(Haptic.heavy);
      case TableEvent.flipperUp:
        break;
    }
  }

  void _hapticFor(TablePart part) {
    switch (part) {
      case BumperPart():
        haptics.play(Haptic.medium);
      case WallPart() when part.visual.kicker.boost > 0:
        haptics.play(Haptic.medium);
      case PopupTargetPart() ||
          SoloTargetPart() ||
          RolloverPart() ||
          TripwirePart():
        haptics.play(Haptic.light);
      default:
        break;
    }
  }

  /// `EndGame_timeout`: the game is over.
  void _gameOver() {
    gameState
      ..handle(GameEvent.ballDrained)
      ..handle(GameEvent.noBallsLeft);
  }

  /// Most recent component event, for the debug HUD.
  PartEvent? lastPartEvent;

  void _onPartEvent(PartEvent e) {
    lastPartEvent = e;
    if (!gameState.isSimulating) return;
    // Tilted: the table reports nothing to the rules but the drain.
    if (rules.t.tiltLockFlag && e.part is! DrainPart) return;
    if (e.code == MC.controlCollision) _hapticFor(e.part);
    // A light only reports its timer when it has a control function
    // (`TLight::TimerExpired`: `if (light->Control)`).
    if (e.code == MC.controlTimerExpired &&
        e.part is LightPart &&
        !rules.controls.containsKey(e.part.name)) {
      return;
    }
    rules.handler(e.code, e.part);
  }

  void togglePause() {
    if (!gameState.handle(GameEvent.pause)) {
      gameState.handle(GameEvent.resume);
    }
  }

  /// Debug: put the ball at rest at a table position.
  void debugPlaceBall(double x, double y) {
    if (table.balls.isEmpty) {
      table.addBall(x, y);
    } else {
      table.balls.first.placeAt(x, y);
    }
  }

  // --- Input ---------------------------------------------------------------

  bool get _controlsLive =>
      gameState.isSimulating || GameConfig.debug && !gameState.isPaused;

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (_debugLayer case final layer?
        when event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyG) {
      layer.showWalls = !layer.showWalls;
      return KeyEventResult.handled;
    }
    final action = InputBindings.keyboard[event.logicalKey];
    if (action == null) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      if (input.press(action, event.logicalKey)) onActionPressed(action);
    } else if (event is KeyUpEvent) {
      if (input.release(action, event.logicalKey)) onActionReleased(action);
    }
    // Handled, so Space does not scroll the page on the web.
    return KeyEventResult.handled;
  }

  void onActionPressed(GameAction action) {
    // Browsers only allow audio after a user gesture.
    audio.start();
    switch (action) {
      case GameAction.pause:
        togglePause();
      case GameAction.start:
        startGame();
      case GameAction.nudgeLeft:
      case GameAction.nudgeRight:
      case GameAction.nudgeBottom:
        if (gameState.isSimulating && !rules.t.tiltLockFlag) {
          switch (action) {
            case GameAction.nudgeLeft:
              nudge.bumpLeft();
            case GameAction.nudgeRight:
              nudge.bumpRight();
            default:
              nudge.bumpBottom();
          }
          haptics.play(Haptic.medium);
        }
      case GameAction.leftFlipper:
      case GameAction.rightFlipper:
        if (_controlsLive && !rules.t.tiltLockFlag) {
          table.setFlipper(
            left: action == GameAction.leftFlipper,
            pressed: true,
          );
        }
      case GameAction.plunger:
        if (_controlsLive && !rules.t.tiltLockFlag) table.pressPlunger();
    }
  }

  void onActionReleased(GameAction action) {
    switch (action) {
      case GameAction.leftFlipper:
      case GameAction.rightFlipper:
        table.setFlipper(
          left: action == GameAction.leftFlipper,
          pressed: false,
        );
      case GameAction.plunger:
        table.releasePlunger();
      case GameAction.pause:
      case GameAction.start:
      case GameAction.nudgeLeft:
      case GameAction.nudgeRight:
      case GameAction.nudgeBottom:
        break;
    }
  }

  /// Raw pointer events from the widget, so several fingers work at once.
  ///
  /// Touch only (mouse clicks are for debug placement):
  /// - the scoreboard is the menu button: it pauses (the pause overlay
  ///   resumes);
  /// - the plunger lane pulls the plunger;
  /// - anywhere else, the left or right half works that flipper, including
  ///   the letterbox bands, so a thumb slightly off the table still flips.
  void handlePointer(PointerEvent e) {
    if (e.kind != PointerDeviceKind.touch) return;
    final source = ('touch', e.pointer);
    if (e is PointerDownEvent) {
      final screen = layoutOnScreen.toScreen(e.localPosition);
      if (screen != null && ScreenLayout.isScoreboard(screen)) {
        if (gameState.phase == GamePhase.playing ||
            gameState.phase == GamePhase.ballLost) {
          gameState.handle(GameEvent.pause);
        }
        return;
      }
      final action = screen != null
          ? _touchAction(screen.dx, screen.dy)
          : e.localPosition.dx < size.x / 2
          ? GameAction.leftFlipper
          : GameAction.rightFlipper;
      _touchActions[e.pointer] = action;
      if (input.press(action, source)) onActionPressed(action);
    } else if (e is PointerUpEvent || e is PointerCancelEvent) {
      final action = _touchActions.remove(e.pointer);
      if (action != null && input.release(action, source)) {
        onActionReleased(action);
      }
    }
  }

  final Map<int, GameAction> _touchActions = {};

  GameAction _touchAction(double x, double y) {
    final s = layout.plunger;
    final plunger = projection.toScreen((s.x1 + s.x2) / 2, s.y1);
    if ((x - plunger.dx).abs() < 30 && y > plunger.dy - 60) {
      return GameAction.plunger;
    }
    final mid = projection.toScreen(0, layout.leftFlipper.originY).dx;
    return x < mid ? GameAction.leftFlipper : GameAction.rightFlipper;
  }

  // --- State ---------------------------------------------------------------

  void _onPhase(GamePhase from, GamePhase to) {
    if (to == GamePhase.paused || to == GamePhase.gameOver) {
      input.releaseAll();
      table.releaseControls();
      audio.stopAll();
    }
    // `pb::pause_continue`: the music stops with a pause and comes back
    // after it; it plays on through game over.
    if (to == GamePhase.paused) {
      audio.pauseMusic();
    } else if (from == GamePhase.paused && _musicStarted) {
      audio.playMusic();
    }
    _overlay(pauseOverlay, to == GamePhase.paused);
    _overlay(attractOverlay, to == GamePhase.attract);
    _overlay(gameOverOverlay, to == GamePhase.gameOver);
    if (from == GamePhase.paused) physics.resetClock();
  }

  void _overlay(String name, bool show) =>
      show ? overlays.add(name) : overlays.remove(name);

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    // Pause when the app or tab loses focus, as the original does; the
    // music stops then too, also outside a game.
    if (state != AppLifecycleState.resumed &&
        gameState.phase == GamePhase.playing) {
      gameState.handle(GameEvent.pause);
    }
    if (state != AppLifecycleState.resumed) {
      audio.pauseMusic();
    } else if (_musicStarted && gameState.phase != GamePhase.paused) {
      audio.playMusic();
    }
  }

  /// [inner] scaled uniformly to fit centred in [outer]: never distort.
  static Rect _fitted(Rect inner, Rect outer) {
    final scale = (outer.width / inner.width) < (outer.height / inner.height)
        ? outer.width / inner.width
        : outer.height / inner.height;
    return Rect.fromCenter(
      center: outer.center,
      width: inner.width * scale,
      height: inner.height * scale,
    );
  }
}
