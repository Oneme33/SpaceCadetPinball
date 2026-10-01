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
  Future<Object> load(String name, Uint8List bytes) async => name;

  @override
  void play(Object source) => played.add(source as String);

  @override
  void stopAll() => stopped++;
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
}
