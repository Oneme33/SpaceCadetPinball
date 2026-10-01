import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/rules/score_manager.dart';

void main() {
  test('adds points times the multiplier', () {
    final s = ScoreManager();
    expect(s.add(500), 500);
    s.multiplierIndex = 3;
    expect(s.multiplier, 5);
    expect(s.add(1000), 5000);
    expect(s.score, 5500);
  });

  test('the original multipliers are 1, 2, 3, 5 and 10', () {
    expect(ScoreManager.multipliers, [1, 2, 3, 5, 10]);
  });

  test('jackpot and bonus collect raw points up to their limit', () {
    final s = ScoreManager()
      ..jackpotActive = true
      ..bonusActive = true
      ..multiplierIndex = 4;
    s.add(1000);
    expect(s.jackpot, 1000);
    expect(s.bonus, 1000);
    expect(s.score, 10000);
    s.add(10000000);
    expect(s.jackpot, ScoreManager.jackpotLimit);
    expect(s.bonus, ScoreManager.bonusLimit);
  });

  test('inactive jackpot and bonus do not collect', () {
    final s = ScoreManager()..add(5000);
    expect(s.jackpot, 0);
    expect(s.bonus, 0);
  });

  test('a flat amount is added to every score', () {
    final s = ScoreManager()..scoreAdded = 10;
    expect(s.add(100), 110);
  });

  test('wraps into billions', () {
    final s = ScoreManager()..score = ScoreManager.wrap - 100;
    s.add(500);
    expect(s.scoreE9, 1);
    expect(s.score, 400);
  });

  test('reset clears everything', () {
    final s = ScoreManager()
      ..add(1234)
      ..multiplierIndex = 2
      ..jackpotActive = true
      ..reset();
    expect(s.score, 0);
    expect(s.multiplier, 1);
    expect(s.jackpotActive, isFalse);
  });

  test('formats with thousands separators', () {
    expect(ScoreManager.format(0), '0');
    expect(ScoreManager.format(999), '999');
    expect(ScoreManager.format(1000), '1,000');
    expect(ScoreManager.format(1234567), '1,234,567');
  });
}
