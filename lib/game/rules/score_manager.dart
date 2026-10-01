/// The score of one player, as `TPinballTable::AddScore` keeps it.
///
/// Pure Dart: no physics, no rendering.
class ScoreManager {
  /// `TPinballTable::score_multipliers`.
  static const multipliers = [1, 2, 3, 5, 10];

  static const jackpotLimit = 5000000;
  static const bonusLimit = 5000000;

  /// The score wraps into [scoreE9] above one billion, as the original.
  static const wrap = 1000000000;

  int score = 0;
  int scoreE9 = 0;

  /// Index into [multipliers] (`ScoreMultiplier`), set by the rules.
  int multiplierIndex = 0;

  /// Flat amount added to every score (`ScoreAdded`).
  int scoreAdded = 0;

  bool jackpotActive = false;
  int jackpot = 0;
  bool bonusActive = false;
  int bonus = 0;

  int get multiplier => multipliers[multiplierIndex];

  /// Adds [points] and returns what was actually added.
  int add(int points) {
    if (jackpotActive) jackpot = _cap(jackpot + points, jackpotLimit);
    if (bonusActive) bonus = _cap(bonus + points, bonusLimit);
    final added = scoreAdded + points * multiplier;
    score += added;
    if (score > wrap) {
      scoreE9++;
      score -= wrap;
    }
    return added;
  }

  void reset() {
    score = 0;
    scoreE9 = 0;
    multiplierIndex = 0;
    scoreAdded = 0;
    jackpotActive = false;
    jackpot = 0;
    bonusActive = false;
    bonus = 0;
  }

  static int _cap(int v, int limit) => v > limit ? limit : v;

  /// `score::string_format`: 1,234,567.
  static String format(int value) {
    final s = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }
}
