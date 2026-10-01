/// The high-level phases of a game, independent of rendering and physics.
enum GamePhase { loading, attract, playing, paused, ballLost, gameOver }

/// Everything that can move the game from one phase to another.
enum GameEvent {
  assetsLoaded,
  startGame,
  pause,
  resume,
  ballDrained,
  nextBallReady,
  noBallsLeft,
  backToAttract,
}

/// Pure state machine for [GamePhase]. No Flame imports, so it is testable
/// without a renderer.
///
/// Invalid transitions are ignored and return `false`: input such as a
/// pause key during loading must never crash or corrupt the state.
class GameStateMachine {
  GameStateMachine({this.onChanged});

  /// Called after every successful transition.
  final void Function(GamePhase from, GamePhase to)? onChanged;

  GamePhase _phase = GamePhase.loading;
  GamePhase get phase => _phase;

  /// The phase to return to when resuming. Pausing is allowed while playing
  /// and while a lost ball is being handled.
  GamePhase? _pausedFrom;

  bool get isPaused => _phase == GamePhase.paused;

  /// Physics and timers only advance in these phases.
  bool get isSimulating =>
      _phase == GamePhase.playing || _phase == GamePhase.ballLost;

  bool handle(GameEvent event) {
    final next = _next(event);
    if (next == null) return false;
    final previous = _phase;
    if (next == GamePhase.paused) _pausedFrom = previous;
    if (previous == GamePhase.paused) _pausedFrom = null;
    _phase = next;
    onChanged?.call(previous, next);
    return true;
  }

  GamePhase? _next(GameEvent event) {
    switch ((_phase, event)) {
      case (GamePhase.loading, GameEvent.assetsLoaded):
        return GamePhase.attract;
      case (GamePhase.attract, GameEvent.startGame):
      case (GamePhase.gameOver, GameEvent.startGame):
        return GamePhase.playing;
      case (GamePhase.playing, GameEvent.pause):
      case (GamePhase.ballLost, GameEvent.pause):
        return GamePhase.paused;
      case (GamePhase.paused, GameEvent.resume):
        return _pausedFrom;
      case (GamePhase.playing, GameEvent.ballDrained):
        return GamePhase.ballLost;
      case (GamePhase.ballLost, GameEvent.nextBallReady):
        return GamePhase.playing;
      case (GamePhase.ballLost, GameEvent.noBallsLeft):
        return GamePhase.gameOver;
      case (GamePhase.gameOver, GameEvent.backToAttract):
        return GamePhase.attract;
      default:
        return null;
    }
  }
}
