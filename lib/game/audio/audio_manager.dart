import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Plays the original sound effects, by sound record (the DAT's sound
/// groups, see `PinballData.soundFiles`), and the music.
///
/// - Sounds are loaded once into memory, so playing one is immediate.
/// - Many sounds can play at once, but like the original (`Sound.cpp`) the
///   number of voices is limited; the oldest gives way.
/// - A missing file stays silent and is logged once. Nothing is ever
///   substituted for an original sound.
/// - On the web, audio can only be heard after a user gesture: the engine
///   loads during the splash and the page resumes it on the first tap
///   (web/index.html). Sounds asked for while it is still loading play
///   when it is ready, if they are recent: the start tune of a first game
///   begun with the very first tap is not lost.
class AudioManager {
  AudioManager({
    required this.soundFiles,
    AudioBackend? backend,
    AssetBundle? bundle,
  }) : _backend = backend ?? SoLoudBackend(),
       _bundle = bundle ?? rootBundle;

  /// Voices playing at the same time.
  /// TODO: VERIFY AGAINST ORIGINAL SPACE CADET — the original mixes a
  /// configurable number of channels; 8 is the decompilation's default.
  static const voices = 8;

  static const assetDir = 'assets/original';

  final Map<int, String> soundFiles;
  final AudioBackend _backend;
  final AssetBundle _bundle;

  final Map<int, Object> _loaded = {};
  final Set<int> _reportedMissing = {};
  Future<void>? _starting;
  bool _ready = false;

  /// Sounds asked for while loading, with the time they were asked for.
  final List<(int, Duration)> _waiting = [];
  final Stopwatch _clock = Stopwatch()..start();

  /// How long a sound asked for while loading may still start late.
  static const lateLimit = Duration(milliseconds: 1500);

  /// Sound effects on.
  bool enabled = true;

  /// The recording of PINBALL.MID (tool/music/render.sh), if installed.
  static const musicFiles = ['music.mp3', 'music.wav'];

  /// Music below the effects, as the original's MIDI sits under them.
  static const musicVolume = 0.55;

  Object? _music;
  Object? _musicHandle;
  bool _musicWanted = false;
  bool _musicEnabled = true;

  bool get hasMusic => _music != null;

  /// Music on. Off stops it; on resumes it if a game wants it.
  bool get musicEnabled => _musicEnabled;
  set musicEnabled(bool on) {
    _musicEnabled = on;
    _updateMusic();
  }

  bool get isReady => _ready;

  /// Initialises the audio engine and loads every sound. Safe to call more
  /// than once.
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    try {
      await _backend.init(voices: voices);
    } on Object catch (e) {
      debugPrint('Audio unavailable: $e');
      return;
    }
    for (final MapEntry(key: group, value: file) in soundFiles.entries) {
      try {
        final data = await _bundle.load('$assetDir/$file');
        _loaded[group] = await _backend.load(
          file,
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } on Object {
        // Missing or unreadable: reported when first played.
      }
    }
    // The effects are ready now; the music follows.
    _ready = true;
    final now = _clock.elapsed;
    for (final (group, at) in _waiting) {
      if (now - at <= lateLimit) play(group);
    }
    _waiting.clear();
    for (final file in musicFiles) {
      try {
        final data = await _bundle.load('$assetDir/$file');
        // Streamed: decoding 8 minutes of music up front would take
        // seconds and some 180 MB of memory.
        _music = await _backend.load(
          file,
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          stream: true,
        );
        break;
      } on Object {
        // Not rendered: no music.
      }
    }
    _updateMusic();
  }

  /// `midi::music_play`: from a new game on, the music loops (through game
  /// over too) while music is on.
  void playMusic() {
    _musicWanted = true;
    _updateMusic();
  }

  /// `midi::music_stop` on pause and when the app goes to the background.
  /// Unlike the original's MIDI, the recording continues where it was.
  void pauseMusic() {
    _musicWanted = false;
    _updateMusic();
  }

  void _updateMusic() {
    if (!_ready) return;
    final music = _music;
    if (music == null) return;
    final on = _musicWanted && _musicEnabled;
    final handle = _musicHandle;
    if (handle != null && _backend.isPlaying(handle)) {
      _backend.setPaused(handle, !on);
    } else if (on) {
      _musicHandle = _backend.playLooping(music, volume: musicVolume);
    }
  }

  /// Plays sound record [group]; null or unknown records are ignored.
  void play(int? group) {
    if (group == null || !enabled) return;
    if (!_ready) {
      // Capped: if the engine never comes up, this must not grow.
      if (_starting != null && _waiting.length < 16) {
        _waiting.add((group, _clock.elapsed));
      }
      return;
    }
    final source = _loaded[group];
    if (source == null) {
      if (_reportedMissing.add(group)) {
        debugPrint('Sound ${soundFiles[group] ?? '#$group'} not available.');
      }
      return;
    }
    _backend.play(source);
  }

  /// Stops the sound effects, e.g. on pause; the music has its own
  /// controls.
  void stopAll() {
    _waiting.clear();
    if (_ready) _backend.stopEffects();
  }
}

/// The audio engine behind [AudioManager]; replaced by a fake in tests.
abstract interface class AudioBackend {
  Future<void> init({required int voices});

  /// Loads a sound; [stream] decodes it while it plays instead of up front
  /// (for long music).
  Future<Object> load(String name, Uint8List bytes, {bool stream = false});
  void play(Object source);

  /// Starts [source] looping and returns its handle. It must not be cut
  /// off when the effects use up the voices.
  Object playLooping(Object source, {required double volume});
  bool isPlaying(Object handle);
  void setPaused(Object handle, bool paused);
  void stopEffects();
}

class SoLoudBackend implements AudioBackend {
  SoLoud get _s => SoLoud.instance;

  @override
  Future<void> init({required int voices}) async {
    if (!_s.isInitialized) await _s.init();
    _s.setMaxActiveVoiceCount(voices);
  }

  @override
  Future<Object> load(String name, Uint8List bytes, {bool stream = false}) =>
      _s.loadMem(name, bytes, mode: stream ? LoadMode.disk : LoadMode.memory);

  final List<SoundHandle> _effects = [];

  @override
  void play(Object source) {
    _effects
      ..removeWhere((h) => !_s.getIsValidVoiceHandle(h))
      ..add(_s.play(source as AudioSource));
  }

  @override
  Object playLooping(Object source, {required double volume}) {
    final handle = _s.play(
      source as AudioSource,
      volume: volume,
      looping: true,
    );
    _s.setProtectVoice(handle, true);
    // SoundHandle is an extension type; box it for the interface.
    return handle as Object;
  }

  @override
  bool isPlaying(Object handle) =>
      _s.getIsValidVoiceHandle(handle as SoundHandle);

  @override
  void setPaused(Object handle, bool paused) =>
      _s.setPause(handle as SoundHandle, paused);

  @override
  void stopEffects() {
    for (final h in _effects) {
      if (_s.getIsValidVoiceHandle(h)) _s.stop(h);
    }
    _effects.clear();
  }
}
