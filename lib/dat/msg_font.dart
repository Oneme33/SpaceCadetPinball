import 'dart:typed_data';

/// The bitmap font of the message boxes (`PBMSG_FT` in Pinball.exe, the
/// same format as PINBALL2.MID): the dotted letters of "Extra Ball
/// Available". The English game uses it (`TextBoxUseBitmapFont` = 1).
///
/// Format (`MsgFont` in the decompilation): gap width, an unknown short,
/// the height, 128 character widths, then for characters 32…127 a width
/// byte and width × height palette indices, top row first. Index 0 is
/// transparent.
class MsgFont {
  MsgFont._(this.gap, this.height, this.glyphs);

  /// Pixels between characters.
  final int gap;
  final int height;

  /// Character code → glyph, for codes 32…127.
  final Map<int, MsgGlyph> glyphs;

  static MsgFont parse(Uint8List bytes) {
    final d = ByteData.sublistView(bytes);
    final gap = d.getInt16(0, Endian.little);
    final height = d.getInt16(4, Endian.little);
    if (height <= 0 || height > 64) {
      throw const FormatException('bad font height');
    }
    var p = 6 + 128;
    final glyphs = <int, MsgGlyph>{};
    for (var c = 32; c < 128 && p < bytes.length; c++) {
      final width = bytes[p++];
      if (width != bytes[6 + c]) {
        throw const FormatException('font widths do not match');
      }
      final size = width * height;
      if (p + size > bytes.length) break;
      glyphs[c] = MsgGlyph(width, Uint8List.sublistView(bytes, p, p + size));
      p += size;
    }
    return MsgFont._(gap, height, glyphs);
  }

  /// Width of [c] including the gap after it, or null if the font lacks it.
  int? advance(int c) {
    final g = glyphs[c & 0x7F];
    return g == null ? null : g.width + gap;
  }

  /// `TTextBox::LayoutTextLine`: as much of [text] from [start] as fits in
  /// [width], broken at the last space; returns (end, line width), where
  /// end skips the spaces and the newline after the line.
  (int, int) layoutLine(String text, int start, int width) {
    var lineWidth = 0, wordWidth = 0;
    int? wordBoundary;
    var end = start;
    for (; end < text.length; end++) {
      final c = text.codeUnitAt(end) & 0x7F;
      if (c == 10) break;
      final a = advance(c);
      if (a == null) continue;
      final w = lineWidth + a;
      if (w > width) {
        if (wordBoundary != null) {
          end = wordBoundary;
          lineWidth = wordWidth;
        }
        break;
      }
      if (c == 32) {
        wordBoundary = end;
        wordWidth = w;
      }
      lineWidth = w;
    }
    while (end < text.length && text.codeUnitAt(end) & 0x7F == 32) {
      end++;
    }
    if (end < text.length && text.codeUnitAt(end) & 0x7F == 10) end++;
    return (end, lineWidth);
  }

  /// `TTextBox::Draw`: the lines of [text] that fit a [width] × [maxHeight]
  /// box, as (start, end) ranges.
  List<(int, int)> layout(String text, int width, int maxHeight) {
    final lines = <(int, int)>[];
    var start = 0;
    for (
      var y = 0;
      start < text.length && y + height <= maxHeight;
      y += height
    ) {
      final (end, _) = layoutLine(text, start, width);
      if (end == start) break;
      lines.add((start, end));
      start = end;
    }
    return lines;
  }
}

class MsgGlyph {
  const MsgGlyph(this.width, this.pixels);
  final int width;

  /// Palette indices, width × font height, top row first; 0 is see-through.
  final Uint8List pixels;
}
