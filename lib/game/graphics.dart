import 'dart:ui';

/// Which art is drawn: the classic original pixels, or the HD set (the
/// same bitmaps upscaled 4× with Real-ESRGAN, made by tool/make_hd.dart).
///
/// HD images are drawn into exactly the rectangle of their original, so
/// positions, physics and depth are the same in both modes.
class Graphics {
  /// HD bitmaps by DAT group index, when installed and loaded.
  Map<int, Image> hdImages = const {};

  bool hdEnabled = false;

  bool get hdAvailable => hdImages.isNotEmpty;
  bool get hd => hdEnabled && hdAvailable;

  /// HD image of a DAT bitmap group, or null to use the classic one.
  Image? hdFor(int group) => hd ? hdImages[group] : null;

  /// Classic pixels stay hard; HD is smoothed.
  static final classicPaint = Paint()..filterQuality = FilterQuality.none;
  static final hdPaint = Paint()..filterQuality = FilterQuality.medium;

  Paint get paint => hd ? hdPaint : classicPaint;

  /// Draws [classic] at [at], or its HD version scaled into the same box.
  void drawBitmap(Canvas canvas, Image classic, int group, Offset at) {
    final hd = hdFor(group);
    if (hd == null) {
      canvas.drawImage(classic, at, classicPaint);
      return;
    }
    canvas.drawImageRect(
      hd,
      Rect.fromLTWH(0, 0, hd.width.toDouble(), hd.height.toDouble()),
      Rect.fromLTWH(
        at.dx,
        at.dy,
        classic.width.toDouble(),
        classic.height.toDouble(),
      ),
      hdPaint,
    );
  }

  /// Draws the part [src] (in classic pixels) of a bitmap into [dst].
  void drawBitmapRect(
    Canvas canvas,
    Image classic,
    int group,
    Rect src,
    Rect dst,
  ) {
    final hd = hdFor(group);
    if (hd == null) {
      canvas.drawImageRect(classic, src, dst, classicPaint);
      return;
    }
    final k = hd.width / classic.width;
    canvas.drawImageRect(
      hd,
      Rect.fromLTRB(src.left * k, src.top * k, src.right * k, src.bottom * k),
      dst,
      hdPaint,
    );
  }
}
