import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Plays the original sound effects, by sound record (the DAT's sound
/// groups, see `PinballData.soundFiles`).
///
/// - Sounds are loaded once into memory, so playing one is immediate.
/// - Many sounds can play at once, but like the original (`Sound.cpp`) the
///   number of voices is limited; the oldest gives way.
/// - A missing file stays silent and is logged once. Nothing is ever
///   substituted for an original sound.
/// - On the web, audio can only start after a user gesture, so [start] is
///   called on the first input.
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

  bool enabled = true;

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
    _ready = true;
  }

  /// Plays sound record [group]; null or unknown records are ignored.
  void play(int? group) {
    if (group == null || !enabled || !_ready) return;
    final source = _loaded[group];
    if (source == null) {
      if (_reportedMissing.add(group)) {
        debugPrint('Sound ${soundFiles[group] ?? '#$group'} not available.');
      }
      return;
    }
    _backend.play(source);
  }

  /// Stops everything, e.g. on pause.
  void stopAll() {
    if (_ready) _backend.stopAll();
  }
}

/// The audio engine behind [AudioManager]; replaced by a fake in tests.
abstract interface class AudioBackend {
  Future<void> init({required int voices});
  Future<Object> load(String name, Uint8List bytes);
  void play(Object source);
  void stopAll();
}

class SoLoudBackend implements AudioBackend {
  SoLoud get _s => SoLoud.instance;

  @override
  Future<void> init({required int voices}) async {
    if (!_s.isInitialized) await _s.init();
    _s.setMaxActiveVoiceCount(voices);
  }

  @override
  Future<Object> load(String name, Uint8List bytes) => _s.loadMem(name, bytes);

  @override
  void play(Object source) => _s.play(source as AudioSource);

  @override
  void stopAll() => _s.stopAll();
}
