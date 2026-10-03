import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/audio/audio_manager.dart';

class _FakeBackend implements AudioBackend {
  int? voices;
  final played = <String>[];
  var stopped = 0;

  @override
  Future<void> init({required int voices}) async => this.voices = voices;

  @override
  Future<Object> load(
    String name,
    Uint8List bytes, {
    bool stream = false,
  }) async => name;

  @override
  void play(Object source) => played.add(source as String);

  @override
  void stopEffects() => stopped++;

  /// Looping sources by handle, and whether each is paused.
  final looping = <int, (String, bool)>{};

  @override
  Object playLooping(Object source, {required double volume}) {
    final handle = looping.length;
    looping[handle] = (source as String, false);
    return handle;
  }

  @override
  bool isPlaying(Object handle) => looping.containsKey(handle);

  @override
  void setPaused(Object handle, bool paused) =>
      looping[handle as int] = (looping[handle]!.$1, paused);
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);
  final Set<String> files;

  @override
  Future<ByteData> load(String key) async {
    if (!files.contains(key)) throw StateError('missing $key');
    return ByteData(4);
  }
}

void main() {
  late _FakeBackend backend;
  late AudioManager audio;

  setUp(() {
    backend = _FakeBackend();
    audio = AudioManager(
      soundFiles: const {10: 'SOUND1.WAV', 11: 'SOUND2.WAV'},
      backend: backend,
      bundle: _Bundle({'assets/original/SOUND1.WAV'}),
    );
  });

  test('nothing plays before the engine has started', () {
    audio.play(10);
    expect(backend.played, isEmpty);
  });

  test('a sound asked for while loading plays once ready', () async {
    // The web: the first tap starts the engine and a game at once, and the
    // game's start tune must not be lost.
    final starting = audio.start();
    audio.play(10);
    expect(backend.played, isEmpty);
    await starting;
    expect(backend.played, ['SOUND1.WAV']);
  });

  test('plays loaded sounds with a limited number of voices', () async {
    await audio.start();
    expect(backend.voices, AudioManager.voices);
    audio
      ..play(10)
      ..play(10);
    expect(backend.played, ['SOUND1.WAV', 'SOUND1.WAV']);
  });

  test('missing files and unknown records stay silent', () async {
    await audio.start();
    audio
      ..play(11)
      ..play(99)
      ..play(null);
    expect(backend.played, isEmpty);
  });

  test('can be muted and stopped', () async {
    await audio.start();
    audio
      ..enabled = false
      ..play(10)
      ..stopAll();
    expect(backend.played, isEmpty);
    expect(backend.stopped, 1);
  });

  test('start is idempotent', () async {
    await Future.wait([audio.start(), audio.start()]);
    expect(audio.isReady, isTrue);
  });

  group('music', () {
    late _FakeBackend backend;
    late AudioManager audio;

    setUp(() {
      backend = _FakeBackend();
      audio = AudioManager(
        soundFiles: const {10: 'SOUND1.WAV'},
        backend: backend,
        bundle: _Bundle({
          'assets/original/SOUND1.WAV',
          'assets/original/music.mp3',
        }),
      );
    });

    test('starts with a game, looping, and pauses with it', () async {
      await audio.start();
      expect(audio.hasMusic, isTrue);
      expect(backend.looping, isEmpty, reason: 'not before a game');
      audio.playMusic();
      expect(backend.looping, {0: ('music.mp3', false)});
      audio.pauseMusic();
      expect(backend.looping[0]!.$2, isTrue);
      audio.playMusic();
      expect(backend.looping, {0: ('music.mp3', false)}, reason: 'resumed');
    });

    test('is switched apart from the effects', () async {
      await audio.start();
      audio
        ..playMusic()
        ..enabled = false
        ..stopAll();
      expect(backend.looping[0]!.$2, isFalse, reason: 'effects only');
      audio.musicEnabled = false;
      expect(backend.looping[0]!.$2, isTrue);
      audio.musicEnabled = true;
      expect(backend.looping[0]!.$2, isFalse);
    });

    test('a game started before the engine gets its music', () async {
      audio.playMusic();
      await audio.start();
      expect(backend.looping, {0: ('music.mp3', false)});
    });

    test('no recording, no music', () async {
      final quiet = AudioManager(
        soundFiles: const {},
        backend: backend,
        bundle: _Bundle({}),
      );
      await quiet.start();
      quiet.playMusic();
      expect(quiet.hasMusic, isFalse);
      expect(backend.looping, isEmpty);
    });
  });
}
