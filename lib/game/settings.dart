import 'package:shared_preferences/shared_preferences.dart';

/// The player's settings, kept between sessions. Every read and write is
/// guarded: without storage (private browsing, tests) the defaults apply.
class Settings {
  Settings._(this._prefs);

  static Future<Settings> load() async {
    try {
      return Settings._(await SharedPreferences.getInstance());
    } on Object {
      return Settings._(null);
    }
  }

  /// For tests and fallbacks: defaults, nothing stored.
  factory Settings.memory() => Settings._(null);

  final SharedPreferences? _prefs;

  bool _get(String key, bool fallback) {
    try {
      return _prefs?.getBool(key) ?? fallback;
    } on Object {
      return fallback;
    }
  }

  void _set(String key, bool value) {
    try {
      _prefs?.setBool(key, value);
    } on Object {
      // Not stored; the value still applies for this session.
    }
  }

  late bool _hd = _get('graphics_hd', false);
  late bool _sound = _get('sound', true);
  late bool _music = _get('music', true);
  late bool _haptics = _get('haptics', true);
  late bool _easy = _get('easy_mode', false);

  /// HD graphics (upscaled originals) instead of the classic pixels.
  bool get hd => _hd;
  set hd(bool v) => _set('graphics_hd', _hd = v);

  bool get sound => _sound;
  set sound(bool v) => _set('sound', _sound = v);

  /// The music (the recording of PINBALL.MID), apart from the effects.
  bool get music => _music;
  set music(bool v) => _set('music', _music = v);

  bool get haptics => _haptics;
  set haptics(bool v) => _set('haptics', _haptics = v);

  /// Easy mode: longer flippers, the centre post up, kickbacks open.
  bool get easy => _easy;
  set easy(bool v) => _set('easy_mode', _easy = v);

  /// Easy mode keeps its own high scores.
  static String _scoresKey(bool easy) =>
      easy ? 'high_scores_easy' : 'high_scores';

  List<int> highScoresFor({required bool easy}) {
    try {
      return [
        for (final s
            in _prefs?.getStringList(_scoresKey(easy)) ?? const <String>[])
          ?int.tryParse(s),
      ];
    } on Object {
      return const [];
    }
  }

  void setHighScores(List<int> scores, {required bool easy}) {
    try {
      _prefs?.setStringList(_scoresKey(easy), [for (final s in scores) '$s']);
    } on Object {
      // Not stored.
    }
  }
}
