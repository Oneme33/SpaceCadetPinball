import 'dart:convert';

import 'package:flame/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../dat/dat_bitmap.dart';
import '../../dat/pinball_data.dart';

/// The user's own original game data, decoded for rendering.
///
/// Installed into `assets/original/` by `dart run tool/install_originals.dart`
/// (git-ignored). When it is missing, [load] returns null and the game shows
/// labelled placeholders instead.
class OriginalAssets {
  OriginalAssets._(
    this.strings,
    this.soundDurations,
    this.data,
    this.table,
    this.scoreboard,
    this.ballSprites,
  );

  /// The game's messages from Pinball.exe, by resource id.
  final Map<int, String> strings;

  /// Length in seconds per sound record, from the WAV headers, as
  /// `loader::get_sound_id` computes it.
  final Map<int, double> soundDurations;

  /// Seconds of audio in a WAV file: data size / (channels · bytes per
  /// sample) / sample rate. −1 when the header is not understood.
  static double wavDuration(ByteData b) {
    if (b.lengthInBytes < 44) return -1;
    final channels = b.getUint16(22, Endian.little);
    final rate = b.getUint32(24, Endian.little);
    final bits = b.getUint16(34, Endian.little);
    final dataSize = b.getUint32(40, Endian.little);
    if (channels == 0 || rate == 0 || bits == 0) return -1;
    return dataSize / (channels * bits / 8) / rate;
  }

  static const datAsset = 'assets/original/PINBALL.DAT';

  final PinballData data;
  final Image table;
  final Image scoreboard;

  /// The playfield's depth map, for z-buffering the ball.
  late final ZMap? tableDepth = data.zMap(data.tableGroup);

  /// Ball sprites, far to near, with the depth from which each applies.
  final List<BallSprite> ballSprites;

  final Map<int, List<SpriteFrame?>> _frames = {};
  final Map<int, List<Image>> _digits = {};

  /// The ten digit bitmaps of a score field, 0–9.
  Future<List<Image>> digits(ScoreField field) async {
    final cached = _digits[field.digitGroup];
    if (cached != null) return cached;
    final images = await Future.wait([
      for (var i = 0; i < 10; i++)
        () {
          final b = data.bitmap(field.digitGroup + i)!;
          return ImageExtension.fromPixels(
            b.toRgba(data.palette),
            b.width,
            b.height,
          );
        }(),
    ]);
    return _digits[field.digitGroup] = images;
  }

  /// Screen-space sprite frames of a component, one per visual state
  /// (null where a state has no bitmap). Decoded once and cached.
  Future<List<SpriteFrame?>> framesFor(Component c) async {
    final cached = _frames[c.group];
    if (cached != null) return cached;
    final (ox, oy) = data.spriteOffset;
    final frames = await Future.wait([
      for (final s in c.states)
        if (s.bitmap case final b?)
          ImageExtension.fromPixels(
            b.toRgba(data.palette),
            b.width,
            b.height,
          ).then(
            (image) => SpriteFrame(
              image,
              Offset((b.x - ox).toDouble(), (b.y - oy).toDouble()),
            ),
          )
        else
          Future<SpriteFrame?>.value(),
    ]);
    return _frames[c.group] = frames;
  }

  static Future<OriginalAssets?> load({AssetBundle? bundle}) async {
    final Uint8List bytes;
    try {
      final b = await (bundle ?? rootBundle).load(datAsset);
      bytes = b.buffer.asUint8List(b.offsetInBytes, b.lengthInBytes);
    } on Object catch (e) {
      debugPrint('Original assets not installed ($e); using placeholders.');
      return null;
    }
    final data = PinballData.parse(bytes);
    var strings = const <int, String>{};
    try {
      final json = await (bundle ?? rootBundle).loadString(
        'assets/original/strings.json',
      );
      strings = {
        for (final e in (jsonDecode(json) as Map<String, dynamic>).entries)
          int.parse(e.key): e.value as String,
      };
    } on Object {
      debugPrint('Messages not installed; run tool/install_originals.dart.');
    }
    final durations = <int, double>{};
    for (final MapEntry(key: group, value: file) in data.soundFiles.entries) {
      try {
        final b = await (bundle ?? rootBundle).load('assets/original/$file');
        durations[group] = wavDuration(b);
      } on Object {
        // Missing: unknown length.
      }
    }
    final palette = data.palette;
    Future<Image> image(Bitmap8 b) =>
        ImageExtension.fromPixels(b.toRgba(palette), b.width, b.height);

    return OriginalAssets._(
      strings,
      durations,
      data,
      await image(data.tableBitmap),
      await image(data.scoreboardBitmap),
      [
        for (final (bmp, (x, y, z)) in data.ballSprites)
          BallSprite(await image(bmp), bmp, (x, y, z)),
      ],
    );
  }
}

/// A sprite and where it goes on the 600 × 416 screen.
class SpriteFrame {
  const SpriteFrame(this.image, this.offset);
  final Image image;
  final Offset offset;
}

class BallSprite {
  BallSprite(this.image, this.bitmap, this.depthPoint);

  final Image image;

  /// The indexed source, for the opaque mask used in z-buffering.
  final Bitmap8 bitmap;

  /// Table-space point whose camera depth is this sprite's threshold.
  final (double, double, double) depthPoint;
}
