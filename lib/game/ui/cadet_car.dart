import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/extensions.dart';

import '../../dat/dat_bitmap.dart';

/// The cadet in his space car, cut out of the scoreboard art (where it sits
/// partly under the logo letters).
///
/// The cut-out is the connected area around the car body that is neither
/// dark background (so stars fall away) nor the violet of the logo letters
/// in the upper band (the cadet's suit is lower and redder). It is computed
/// from the classic bitmap and applied to the HD image too.
///
/// The glass dome over the cadet is see-through in the art, so the letters
/// show through it. Inside the dome the cut-out leaves them out and draws
/// the glass instead: a faint tint and the dome's rim, as an ellipse traced
/// on the art.
class CadetCar {
  CadetCar._(this.width, this.height, this._mask, this.rimColor);

  /// The car's area in classic scoreboard pixels.
  static const left = 55, top = 40, right = 193, bottom = 135;

  /// A pixel of the car body to grow the cut-out from.
  static const seedX = 120, seedY = 120;

  /// Below this scoreboard row nothing is taken for a letter.
  static const letterBand = 80;

  /// The dome, in classic scoreboard pixels: an ellipse fitted on its rim
  /// (top at y 53, sides at x 102 and 174 where it meets the car at y 82).
  static const domeX = 138.0, domeY = 82.0, domeA = 37.0, domeB = 29.0;

  /// The glass: a light blue at low opacity, 0xRRGGBBAA.
  static const glassColor = 0x8CB4EB30;

  final int width, height;
  final List<bool> _mask;

  /// The rim's grey, sampled from the art (0xRRGGBBAA).
  final int rimColor;

  /// Signed distance in classic pixels from the dome's rim, negative
  /// inside. Approximate, which is fine for a ring a pixel wide.
  static double domeDistance(double x, double y) {
    final dx = (x - domeX) / domeA, dy = (y - domeY) / domeB;
    return (math.sqrt(dx * dx + dy * dy) - 1) * (domeA + domeB) / 2;
  }

  /// Whether (x, y) lies under the glass (above the car body).
  static bool inDome(double x, double y) => y < domeY && domeDistance(x, y) < 0;

  /// Whether classic scoreboard pixel (x, y) belongs to the car.
  bool contains(int x, int y) {
    if (x < left || y < top || x >= right || y >= bottom) return false;
    return _mask[(y - top) * width + x - left];
  }

  static CadetCar fromScoreboard(Bitmap8 board, Palette palette) {
    const w = right - left, h = bottom - top;
    final colors = palette.rgba;
    int at(int x, int y) =>
        colors[board.pixels[(top + y) * board.width + left + x]];

    bool keep(int x, int y) {
      final c = at(x, y);
      final r = c >> 24 & 0xff, g = c >> 16 & 0xff, b = c >> 8 & 0xff;
      if ((c & 0xff) == 0 || [r, g, b].reduce((a, v) => a > v ? a : v) < 45) {
        return false;
      }
      return !(top + y < letterBand && _isViolet(r, g, b));
    }

    final mask = List<bool>.filled(w * h, false);
    final queue = <int>[(seedY - top) * w + (seedX - left)];
    mask[queue.first] = true;
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      final x = i % w, y = i ~/ w;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = x + dx, ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          final n = ny * w + nx;
          if (mask[n] || !keep(nx, ny)) continue;
          mask[n] = true;
          queue.add(n);
        }
      }
    }
    return CadetCar._(w, h, mask, _sampleRim(board, colors));
  }

  /// The average of the grey rim pixels along the dome's edge.
  static int _sampleRim(Bitmap8 board, Uint32List colors) {
    var r = 0, g = 0, b = 0, n = 0;
    for (var y = top; y < domeY; y++) {
      for (var x = left; x < right; x++) {
        if (domeDistance(x.toDouble(), y.toDouble()).abs() > 1.5) continue;
        final c = colors[board.pixels[y * board.width + x]];
        final cr = c >> 24 & 0xff, cg = c >> 16 & 0xff, cb = c >> 8 & 0xff;
        final mx = math.max(cr, math.max(cg, cb));
        final mn = math.min(cr, math.min(cg, cb));
        if (mx < 45 || mx - mn > 25) continue;
        r += cr;
        g += cg;
        b += cb;
        n++;
      }
    }
    if (n == 0) return 0xA0A0A8FF;
    return (r ~/ n) << 24 | (g ~/ n) << 16 | (b ~/ n) << 8 | 0xff;
  }

  /// Hue 0.66–0.9 with some saturation: the logo's lavender and its
  /// darker outlines.
  static bool _isViolet(int r, int g, int b) {
    final max = [r, g, b].reduce((a, v) => a > v ? a : v);
    final min = [r, g, b].reduce((a, v) => a < v ? a : v);
    if (max == min) return false;
    final d = (max - min).toDouble();
    final l = (max + min) / 510;
    final s = l > 0.5 ? d / (510 - max - min) : d / (max + min);
    double h;
    if (max == r) {
      h = ((g - b) / d) % 6;
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h /= 6;
    if (h < 0) h += 1;
    return h >= 0.66 && h <= 0.9 && s > 0.15;
  }

  /// The car from [image], a scoreboard at [scale] × the classic size
  /// (1 classic, 4 HD), with everything outside the cut-out transparent.
  ///
  /// At a larger scale the mask is sampled bilinearly, so the HD car gets
  /// smooth edges instead of the classic pixel steps, and the dome is drawn
  /// at full resolution.
  Future<ui.Image> cutOut(ui.Image image, int scale) async {
    final data = await image.toByteData();
    if (data == null) throw StateError('cannot read scoreboard pixels');
    final w = width * scale, h = height * scale;
    final out = Uint8List(w * h * 4);
    final src = data.buffer.asUint8List();

    double maskAt(int x, int y) =>
        x >= 0 && y >= 0 && x < width && y < height && _mask[y * width + x]
        ? 1
        : 0;
    double coverage(double fx, double fy) {
      if (scale == 1) return maskAt(fx.floor(), fy.floor());
      // Pixel centres: classic pixel i spans [i, i + 1).
      final gx = fx - 0.5, gy = fy - 0.5;
      final x0 = gx.floor(), y0 = gy.floor();
      final tx = gx - x0, ty = gy - y0;
      final m =
          maskAt(x0, y0) * (1 - tx) * (1 - ty) +
          maskAt(x0 + 1, y0) * tx * (1 - ty) +
          maskAt(x0, y0 + 1) * (1 - tx) * ty +
          maskAt(x0 + 1, y0 + 1) * tx * ty;
      return ((m - 0.25) * 2).clamp(0.0, 1.0);
    }

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        // Classic coordinates of this pixel's centre, relative to the crop.
        final fx = (x + 0.5) / scale, fy = (y + 0.5) / scale;
        final sx = left + fx, sy = top + fy;
        var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
        void over(double cr, double cg, double cb, double ca) {
          final na = ca + a * (1 - ca);
          if (na <= 0) return;
          r = (cr * ca + r * a * (1 - ca)) / na;
          g = (cg * ca + g * a * (1 - ca)) / na;
          b = (cb * ca + b * a * (1 - ca)) / na;
          a = na;
        }

        if (sy < domeY) {
          final d = domeDistance(sx, sy);
          if (d < 0) {
            over(
              (glassColor >> 24 & 0xff).toDouble(),
              (glassColor >> 16 & 0xff).toDouble(),
              (glassColor >> 8 & 0xff).toDouble(),
              (glassColor & 0xff) / 255,
            );
          }
          // A rim about a classic pixel wide, just inside the edge.
          final rim = (1 - ((d + 0.7).abs() - 0.5) * scale).clamp(0.0, 1.0);
          if (rim > 0) {
            over(
              (rimColor >> 24 & 0xff).toDouble(),
              (rimColor >> 16 & 0xff).toDouble(),
              (rimColor >> 8 & 0xff).toDouble(),
              rim,
            );
          }
        }
        final c = coverage(fx, fy);
        if (c > 0) {
          final s = ((top * scale + y) * image.width + left * scale + x) * 4;
          over(
            src[s].toDouble(),
            src[s + 1].toDouble(),
            src[s + 2].toDouble(),
            c * src[s + 3] / 255,
          );
        }
        if (a <= 0) continue;
        final o = (y * w + x) * 4;
        out[o] = r.round();
        out[o + 1] = g.round();
        out[o + 2] = b.round();
        out[o + 3] = (a * 255).round();
      }
    }
    return ImageExtension.fromPixels(out, w, h);
  }
}
