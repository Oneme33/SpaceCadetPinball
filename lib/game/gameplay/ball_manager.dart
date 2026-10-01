/// Ball count for one player, as `TPinballTable` keeps it.
///
/// Pure Dart: no physics, no rendering.
class BallManager {
  BallManager({this.maxBalls = 3});

  /// `TPinballTable::MaxBallCount`.
  final int maxBalls;

  int _ballsLeft = 0;

  /// Balls still to play, including the one in play.
  int get ballsLeft => _ballsLeft;

  /// The number the scoreboard shows: 1 for the first ball
  /// (`MaxBallCount - BallCount + 1`), or null when no ball is in play
  /// (the original erases the counter then).
  int? get ballNumber => _ballsLeft > 0 ? maxBalls - _ballsLeft + 1 : null;

  bool get hasBallsLeft => _ballsLeft > 0;

  void startGame() => _ballsLeft = maxBalls;

  /// The ball in play drained. Returns true when another ball follows.
  ///
  /// TODO: VERIFY AGAINST ORIGINAL SPACE CADET — shoot-again and ball save
  /// (control.cpp, Phase 6) can return the ball without using one up.
  bool ballDrained() {
    if (_ballsLeft > 0) _ballsLeft--;
    return _ballsLeft > 0;
  }

  /// Extra ball award (Phase 6).
  void awardExtraBall() => _ballsLeft++;
}
