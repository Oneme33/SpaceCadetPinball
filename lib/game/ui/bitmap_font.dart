import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/extensions.dart';

import '../../dat/dat_bitmap.dart';
import '../../dat/msg_font.dart';
import '../graphics.dart';

/// The message font as one image strip in the game's palette, drawn the
/// way `TTextBox::Draw` does: lines wrapped to the box from the top left,
/// glyph after glyph with the font's gap, as many lines as fit.
class BitmapFont {
  BitmapFont._(this.font, this._atlas, this._rects);

  final MsgFont font;
  final Image _atlas;
  final Map<int, Rect> _rects;

  static Future<BitmapFont> create(MsgFont font, Palette palette) async {
    final width = font.glyphs.values.fold(0, (w, g) => w + g.width);
    final h = font.height;
    final rgba = Uint8List(width * h * 4);
    final rects = <int, Rect>{};
    var x0 = 0;
    for (final MapEntry(key: c, value: g) in font.glyphs.entries) {
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < g.width; x++) {
          final index = g.pixels[y * g.width + x];
          if (index == 0) continue; // see-through
          final c = palette.rgba[index];
          final o = (y * width + x0 + x) * 4;
          rgba
            ..[o] = c >> 24 & 0xff
            ..[o + 1] = c >> 16 & 0xff
            ..[o + 2] = c >> 8 & 0xff
            ..[o + 3] = 0xff;
        }
      }
      rects[c] = Rect.fromLTWH(
        x0.toDouble(),
        0,
        g.width.toDouble(),
        h.toDouble(),
      );
      x0 += g.width;
    }
    final atlas = await ImageExtension.fromPixels(rgba, width, h);
    return BitmapFont._(font, atlas, rects);
  }

  int get height => font.height;

  /// Draws [text] into [box] (screen pixels) as the original does. [paint]
  /// may smooth the pixels when the font is drawn scaled.
  void render(Canvas canvas, String text, Rect box, [Paint? paint]) {
    final lines = font.layout(text, box.width.floor(), box.height.floor());
    var y = box.top;
    for (final (start, end) in lines) {
      var x = box.left;
      for (var i = start; i < end; i++) {
        final c = text.codeUnitAt(i) & 0x7F;
        final r = _rects[c];
        if (r == null) continue;
        canvas.drawImageRect(
          _atlas,
          r,
          Rect.fromLTWH(x, y, r.width, r.height),
          paint ?? Graphics.classicPaint,
        );
        x += r.width + font.gap;
      }
      y += font.height;
    }
  }
}
