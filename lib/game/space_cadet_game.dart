import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../dat/pinball_data.dart';
import 'assets/original_assets.dart';
import 'audio/audio_manager.dart';
import 'debug/debug_layer.dart';
import 'game_config.dart';
import 'game_state.dart';
import 'gameplay/ball_manager.dart';
import 'gameplay/game_timers.dart';
import 'input/input_bindings.dart';
import 'physics/physics_world.dart';
import 'rules/control.dart';
import 'rules/score_manager.dart';
import 'table/ball_renderer.dart';
import 'table/camera_projection.dart';
import 'table/parts/part.dart';
import 'table/placeholder_table.dart';
import 'table/space_cadet_table.dart';
import 'table/table_art.dart';
import 'table/table_layout.dart';
import 'table/table_projection.dart';
import 'table/table_sprites.dart';
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

  /// `TPlunger`: the ball appears 0.96 s after the feed is requested.
  static const ballFeedDelay = 0.96;

  late final GameStateMachine gameState = GameStateMachine(onChanged: _onPhase);
  final InputState input = InputState();
  final BallManager ballManager = BallManager();
  final GameTimers timers = GameTimers();
  final ScoreManager score = ScoreManager();
  late final TextBox infoText = TextBox(
    onTimerExpired: () => control.handleTextBoxExpired(infoText),
  );
  late final TextBox missionText = TextBox(
    onTimerExpired: () => control.handleTextBoxExpired(missionText),
  );
  late final Control control;
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
  BallRenderer? ballRenderer;
  DebugLayer? _debugLayer;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    add(scoreboardCamera);
    _applyLayout();

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
      ..onPartEvent = _onPartEvent
      ..playSound = audio.play;
    control = Control(
      table: table,
      score: score,
      info: infoText,
      mission: missionText,
    );

    if (originals != null) {
      world.add(TableArt(originals));
      Future<void> sprite(ComponentType type, int Function(int) frame) async {
        final frames = await originals.framesFor(layout.ofType(type).first);
        world.add(ComponentSprite(frames, () => frame(frames.length)));
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
        world.add(ComponentSprite(allFrames[i], () => p.frame));
      }
      await sprite(ComponentType.plunger, (_) => table.plunger.frame);
      await sprite(ComponentType.flipperLeft, table.leftFlipper.frame);
      await sprite(ComponentType.flipperRight, table.rightFlipper.frame);
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

    gameState.handle(GameEvent.assetsLoaded);
  }

  Future<void> _addScoreboard(OriginalAssets? originals) async {
    Future<DigitField?> digits(String name) async {
      final field = originals?.data.scoreField(name);
      if (originals == null || field == null) return null;
      return DigitField(field, await originals.digits(field));
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
          ball: ballManager.ballNumber,
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
    _aim(camera, l.tableView, l.tableSource);
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

  void startGame() {
    if (!gameState.handle(GameEvent.startGame)) return;
    timers.clear();
    table
      ..removeAllBalls()
      ..releaseControls()
      ..reset();
    ballManager.startGame();
    score.reset();
    _scoreShown = true;
    infoText.clear();
    missionText.clear();
    audio.play(originals?.data.tableVisual.sound4);
    _feedBallSoon();
  }

  void _feedBallSoon() {
    table.playFeedSound();
    timers.set(ballFeedDelay, () {
      if (table.balls.isEmpty) table.feedBall();
    });
  }

  void _onTableEvent(TableEvent e) {
    switch (e) {
      case TableEvent.ballDrained:
        if (table.balls.isEmpty && gameState.handle(GameEvent.ballDrained)) {
          timers.set(layout.drain.delay, _afterDrain);
        }
      case TableEvent.ballLaunched:
      case TableEvent.flipperUp:
        // Phase 5: sounds and haptics.
        break;
    }
  }

  /// Most recent component event, for the debug HUD.
  PartEvent? lastPartEvent;

  void _onPartEvent(PartEvent e) {
    lastPartEvent = e;
    if (gameState.isSimulating) control.handle(e);
  }

  void _afterDrain() {
    if (ballManager.ballDrained()) {
      gameState.handle(GameEvent.nextBallReady);
      _feedBallSoon();
    } else {
      gameState.handle(GameEvent.noBallsLeft);
      audio.play(originals?.data.tableVisual.sound3);
    }
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
      case GameAction.leftFlipper:
      case GameAction.rightFlipper:
        if (_controlsLive) {
          table.setFlipper(
            left: action == GameAction.leftFlipper,
            pressed: true,
          );
        }
      case GameAction.plunger:
        if (_controlsLive) table.pressPlunger();
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
    // Pause when the app or tab loses focus, as the original does.
    if (state != AppLifecycleState.resumed &&
        gameState.phase == GamePhase.playing) {
      gameState.handle(GameEvent.pause);
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
