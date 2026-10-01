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
  late bool _haptics = _get('haptics', true);

  /// HD graphics (upscaled originals) instead of the classic pixels.
  bool get hd => _hd;
  set hd(bool v) => _set('graphics_hd', _hd = v);

  bool get sound => _sound;
  set sound(bool v) => _set('sound', _sound = v);

  bool get haptics => _haptics;
  set haptics(bool v) => _set('haptics', _haptics = v);

  List<int> get highScores {
    try {
      return [
        for (final s
            in _prefs?.getStringList('high_scores') ?? const <String>[])
          ?int.tryParse(s),
      ];
    } on Object {
      return const [];
    }
  }

  set highScores(List<int> scores) {
    try {
      _prefs?.setStringList('high_scores', [for (final s in scores) '$s']);
    } on Object {
      // Not stored.
    }
  }
}
