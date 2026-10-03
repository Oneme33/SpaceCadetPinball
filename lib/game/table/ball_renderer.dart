import 'dart:typed_data';
import 'dart:ui';

import '../../dat/dat_bitmap.dart';
import '../assets/original_assets.dart';
import '../graphics.dart';
import 'camera_projection.dart';

/// Draws a ball the way the original does (`TBall::Repaint`,
/// `render::paint_balls`):
///
/// - its centre is projected at its height (radius on the floor, more on a
///   ramp) and the sprite for its camera distance is picked, so it grows
///   towards the player;
/// - it is z-buffered against the playfield's depth map: a ball pixel only
///   shows where the table is farther away than the ball
///   (`zdrv::paint_flat`). So the ball disappears under ramps and rails
///   and sinks into saucers.
class BallRenderer {
  BallRenderer(
    this.projection,
    List<BallSprite> sprites,
    this.radius, {
    required this.tableImage,
    required this.tableDepth,
    required this.zMin,
    required this.zScaler,
    required this.tableGroup,
    required this.graphics,
  }) : _sprites = sprites,
       _thresholds = [
         for (final s in sprites)
           projection.depth(s.depthPoint.$1, s.depthPoint.$2, s.depthPoint.$3),
       ],
       _spans = [for (final s in sprites) _opaqueSpans(s.bitmap)];

  final CameraProjection projection;
  final double radius;
  final Image tableImage;
  final ZMap? tableDepth;
  final double zMin, zScaler;
  final int tableGroup;
  final Graphics graphics;
  final List<BallSprite> _sprites;
  final List<double> _thresholds;

  /// Per sprite, per row: opaque runs as (start, end) pairs.
  final List<List<Int32List>> _spans;

  int spriteIndexFor(double x, double y, double z) {
    final depth = projection.depth(x, y, z);
    var i = 0;
    for (; i < _sprites.length - 1; i++) {
      if (_thresholds[i] <= depth) break;
    }
    return i;
  }

  /// `proj::NormalizeDepth`.
  int normalizedDepth(double depth) {
    if (depth < zMin) return 0;
    final v = (depth - zMin) * zScaler;
    return v > 0xFFFF ? 0xFFFF : v.toInt();
  }

  void render(Canvas canvas, double x, double y, double z) {
    final index = spriteIndexFor(x, y, z);
    final sprite = _sprites[index];
    final image = sprite.image;
    final p = projection.toScreen3(x, y, z);
    final left = (p.dx - image.width ~/ 2).floor();
    final top = (p.dy - image.height ~/ 2).floor();
    final zmap = tableDepth;
    final depth = normalizedDepth(projection.depth(x, y, z));
    if (zmap != null && graphics.hdFor(sprite.group) != null) {
      _renderSmooth(canvas, sprite, left, top, zmap, depth);
      return;
    }
    graphics.drawBitmap(
      canvas,
      image,
      sprite.group,
      Offset(left.toDouble(), top.toDouble()),
    );

    if (zmap == null) return;
    // Paint the table back over every ball pixel the table is in front of.
    final spans = _spans[index];
    for (var row = 0; row < spans.length; row++) {
      final sy = top + row;
      if (sy < 0 || sy >= zmap.height) continue;
      final runs = spans[row];
      for (var r = 0; r < runs.length; r += 2) {
        var start = -1;
        for (var col = runs[r]; col <= runs[r + 1]; col++) {
          final sx = left + col;
          final hidden = sx >= 0 && sx < zmap.width && zmap.at(sx, sy) <= depth;
          if (hidden && start < 0) start = sx;
          if ((!hidden || col == runs[r + 1]) && start >= 0) {
            final end = hidden ? sx + 1 : sx;
            final rect = Rect.fromLTRB(
              start.toDouble(),
              sy.toDouble(),
              end.toDouble(),
              sy + 1.0,
            );
            graphics.drawBitmapRect(canvas, tableImage, tableGroup, rect, rect);
            start = -1;
          }
        }
      }
    }
  }

  /// HD: the same depth test, but the ball is clipped along a smooth
  /// outline through the hidden pixels instead of having whole classic
  /// pixels of table painted over it, which shows as steps on the smooth
  /// HD ball where it passes behind a rail.
  void _renderSmooth(
    Canvas canvas,
    BallSprite sprite,
    int left,
    int top,
    ZMap zmap,
    int depth,
  ) {
    final w = sprite.image.width, h = sprite.image.height;
    // Visibility at the pixel centres of the sprite plus a one-pixel ring.
    final gw = w + 2, gh = h + 2;
    final visible = List<bool>.filled(gw * gh, true);
    var hidden = 0;
    for (var gy = 0; gy < gh; gy++) {
      final sy = top + gy - 1;
      if (sy < 0 || sy >= zmap.height) continue;
      for (var gx = 0; gx < gw; gx++) {
        final sx = left + gx - 1;
        if (sx < 0 || sx >= zmap.width) continue;
        if (zmap.at(sx, sy) <= depth) {
          visible[gy * gw + gx] = false;
          hidden++;
        }
      }
    }
    void draw() => graphics.drawBitmap(
      canvas,
      sprite.image,
      sprite.group,
      Offset(left.toDouble(), top.toDouble()),
    );
    if (hidden == 0) return draw();
    if (hidden == gw * gh) return;

    // Marching squares between the pixel centres: per cell, its visible
    // corners and the midpoints of the edges where visibility changes,
    // in order around the cell.
    final path = Path();
    final ox = left - 0.5, oy = top - 0.5;
    for (var gy = 0; gy < gh - 1; gy++) {
      for (var gx = 0; gx < gw - 1; gx++) {
        final tl = visible[gy * gw + gx], tr = visible[gy * gw + gx + 1];
        final br = visible[(gy + 1) * gw + gx + 1];
        final bl = visible[(gy + 1) * gw + gx];
        if (!(tl || tr || br || bl)) continue;
        final x0 = ox + gx, y0 = oy + gy;
        final points = <Offset>[
          if (tl) Offset(x0, y0),
          if (tl != tr) Offset(x0 + 0.5, y0),
          if (tr) Offset(x0 + 1, y0),
          if (tr != br) Offset(x0 + 1, y0 + 0.5),
          if (br) Offset(x0 + 1, y0 + 1),
          if (br != bl) Offset(x0 + 0.5, y0 + 1),
          if (bl) Offset(x0, y0 + 1),
          if (bl != tl) Offset(x0, y0 + 0.5),
        ];
        path.addPolygon(points, true);
      }
    }
    canvas
      ..save()
      ..clipPath(path);
    draw();
    canvas.restore();
  }

  static List<Int32List> _opaqueSpans(Bitmap8 b) => [
    for (var y = 0; y < b.height; y++)
      () {
        final runs = <int>[];
        var start = -1;
        for (var x = 0; x <= b.width; x++) {
          final opaque = x < b.width && b.pixels[y * b.width + x] != 0;
          if (opaque && start < 0) start = x;
          if (!opaque && start >= 0) {
            runs
              ..add(start)
              ..add(x - 1);
            start = -1;
          }
        }
        return Int32List.fromList(runs);
      }(),
  ];
}
