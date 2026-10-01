import 'dart:typed_data';

import 'dat_file.dart';

/// An 8-bit indexed sprite. Rows are converted to top-down on load.
///
/// [x] and [y] are the sprite's position as stored in the DAT. Component
/// sprites are placed on screen at (x, y) minus the table sprite's own
/// (x, y), see [PinballData.spriteOffset].
class Bitmap8 {
  Bitmap8._(this.width, this.height, this.x, this.y, this.pixels);

  final int width;
  final int height;
  final int x;
  final int y;

  /// width × height palette indices, top row first, no padding.
  final Uint8List pixels;

  static Bitmap8 fromEntry(DatEntry e) {
    final d = e.data;
    final width = d.getInt16(1, Endian.little);
    final height = d.getInt16(3, Endian.little);
    final x = d.getInt16(5, Endian.little);
    final y = d.getInt16(7, Endian.little);
    final size = d.getInt32(9, Endian.little);
    final flags = d.getUint8(13);
    if (flags & 0x04 != 0) {
      throw DatFormatException('spliced bitmaps (Full Tilt) are not supported');
    }
    final stride = (width + 3) & ~3;
    if (size != stride * height) {
      throw DatFormatException('bitmap size $size != $stride × $height');
    }
    final src = Uint8List.sublistView(d, 14, 14 + size);
    final pixels = Uint8List(width * height);
    for (var row = 0; row < height; row++) {
      // Stored bottom-up.
      final from = (height - 1 - row) * stride;
      pixels.setRange(row * width, (row + 1) * width, src, from);
    }
    return Bitmap8._(width, height, x, y, pixels);
  }

  /// RGBA8888, top-down, ready for `decodeImageFromPixels`.
  Uint8List toRgba(Palette palette) {
    final out = Uint8List(width * height * 4);
    final colors = palette.rgba;
    for (var i = 0; i < pixels.length; i++) {
      final c = colors[pixels[i]];
      final o = i * 4;
      out[o] = c >> 24 & 0xff;
      out[o + 1] = c >> 16 & 0xff;
      out[o + 2] = c >> 8 & 0xff;
      out[o + 3] = c & 0xff;
    }
    return out;
  }
}

/// 16-bit depth map belonging to a sprite. Smaller is closer to the viewer.
/// Rows are converted to top-down on load, matching [Bitmap8].
class ZMap {
  ZMap._(this.width, this.height, this.depth);

  final int width;
  final int height;
  final Uint16List depth;

  static const empty = 0xFFFF;

  /// Returns null for the zeroed headers the 3D Pinball DAT contains in a
  /// couple of groups.
  static ZMap? fromEntry(DatEntry e) {
    final d = e.data;
    final width = d.getInt16(0, Endian.little);
    final height = d.getInt16(2, Endian.little);
    final stride = d.getInt16(4, Endian.little);
    final length = e.length - 14;
    if (width <= 0 || height <= 0 || stride * height * 2 != length) {
      return null;
    }
    final depth = Uint16List(width * height);
    for (var row = 0; row < height; row++) {
      final from = 14 + (height - 1 - row) * stride * 2;
      for (var x = 0; x < width; x++) {
        depth[row * width + x] = d.getUint16(from + x * 2, Endian.little);
      }
    }
    return ZMap._(width, height, depth);
  }

  int at(int x, int y) => depth[y * width + x];
}

/// The 256-colour palette as the original displays it: index 0 is
/// transparent, 1–9 are Windows system colours, 10–245 come from the DAT
/// (stored as BGRx), 255 is white.
class Palette {
  Palette._(this.rgba);

  /// 0xRRGGBBAA per index.
  final Uint32List rgba;

  static const _system = [
    0x00000000, 0x800000ff, 0x008000ff, 0x808000ff, 0x000080ff, //
    0x800080ff, 0x008080ff, 0xc0c0c0ff, 0xc0dcc0ff, 0xa6caf0ff,
  ];

  static Palette fromEntry(DatEntry e) {
    final rgba = Uint32List(256);
    for (var i = 0; i < _system.length; i++) {
      rgba[i] = _system[i];
    }
    final d = e.data;
    for (var i = 10; i < 246; i++) {
      final b = d.getUint8(i * 4);
      final g = d.getUint8(i * 4 + 1);
      final r = d.getUint8(i * 4 + 2);
      rgba[i] = r << 24 | g << 16 | b << 8 | 0xff;
    }
    rgba[255] = 0xffffffff;
    return Palette._(rgba);
  }
}
