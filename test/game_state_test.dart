import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/game_state.dart';

void main() {
  late GameStateMachine sm;
  late List<(GamePhase, GamePhase)> changes;

  setUp(() {
    changes = [];
    sm = GameStateMachine(onChanged: (a, b) => changes.add((a, b)));
  });

  void go(List<GameEvent> events) {
    for (final e in events) {
      expect(sm.handle(e), isTrue, reason: '$e from ${sm.phase}');
    }
  }

  test('starts in loading and goes to attract once assets are loaded', () {
    expect(sm.phase, GamePhase.loading);
    go([GameEvent.assetsLoaded]);
    expect(sm.phase, GamePhase.attract);
    expect(changes, [(GamePhase.loading, GamePhase.attract)]);
  });

  test('a full game: play, lose a ball, next ball, game over, attract', () {
    go([
      GameEvent.assetsLoaded,
      GameEvent.startGame,
      GameEvent.ballDrained,
      GameEvent.nextBallReady,
      GameEvent.ballDrained,
      GameEvent.noBallsLeft,
    ]);
    expect(sm.phase, GamePhase.gameOver);
    go([GameEvent.backToAttract]);
    expect(sm.phase, GamePhase.attract);
  });

  test('a new game can start straight from game over', () {
    go([
      GameEvent.assetsLoaded,
      GameEvent.startGame,
      GameEvent.ballDrained,
      GameEvent.noBallsLeft,
      GameEvent.startGame,
    ]);
    expect(sm.phase, GamePhase.playing);
  });

  test('resume returns to the phase that was paused', () {
    go([GameEvent.assetsLoaded, GameEvent.startGame, GameEvent.pause]);
    expect(sm.isPaused, isTrue);
    go([GameEvent.resume]);
    expect(sm.phase, GamePhase.playing);

    go([GameEvent.ballDrained, GameEvent.pause, GameEvent.resume]);
    expect(sm.phase, GamePhase.ballLost);
  });

  test('only playing and ballLost simulate physics', () {
    expect(sm.isSimulating, isFalse);
    go([GameEvent.assetsLoaded]);
    expect(sm.isSimulating, isFalse);
    go([GameEvent.startGame]);
    expect(sm.isSimulating, isTrue);
    go([GameEvent.pause]);
    expect(sm.isSimulating, isFalse);
    go([GameEvent.resume, GameEvent.ballDrained]);
    expect(sm.isSimulating, isTrue);
  });

  test('invalid events are ignored without changing state', () {
    expect(sm.handle(GameEvent.pause), isFalse);
    expect(sm.handle(GameEvent.startGame), isFalse);
    expect(sm.phase, GamePhase.loading);

    go([GameEvent.assetsLoaded]);
    expect(sm.handle(GameEvent.pause), isFalse);
    expect(sm.handle(GameEvent.resume), isFalse);
    expect(sm.handle(GameEvent.ballDrained), isFalse);
    expect(sm.phase, GamePhase.attract);

    go([GameEvent.startGame]);
    expect(sm.handle(GameEvent.startGame), isFalse);
    expect(sm.handle(GameEvent.noBallsLeft), isFalse);
    expect(sm.phase, GamePhase.playing);
    expect(changes, hasLength(2));
  });
}
