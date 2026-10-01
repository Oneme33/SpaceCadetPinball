import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/gameplay/ball_manager.dart';

void main() {
  test('three balls per game, numbered from 1', () {
    final m = BallManager()..startGame();
    expect(m.maxBalls, 3);
    expect(m.ballNumber, 1);
    expect(m.ballDrained(), isTrue);
    expect(m.ballNumber, 2);
    expect(m.ballDrained(), isTrue);
    expect(m.ballNumber, 3);
    expect(m.ballDrained(), isFalse);
    expect(m.hasBallsLeft, isFalse);
  });

  test('an extra ball adds one more drain', () {
    final m = BallManager()..startGame();
    m.ballDrained();
    m.ballDrained();
    m.awardExtraBall();
    expect(m.ballDrained(), isTrue);
    expect(m.ballDrained(), isFalse);
  });

  test('a new game resets the count', () {
    final m = BallManager()..startGame();
    while (m.ballDrained()) {}
    m.startGame();
    expect(m.ballsLeft, 3);
    expect(m.ballNumber, 1);
  });

  test('draining with no balls left stays at zero', () {
    final m = BallManager();
    expect(m.ballDrained(), isFalse);
    expect(m.ballsLeft, 0);
  });

  test('no ball number outside a game', () {
    final m = BallManager();
    expect(m.ballNumber, isNull);
    m.startGame();
    while (m.ballDrained()) {}
    expect(m.ballNumber, isNull);
  });
}
