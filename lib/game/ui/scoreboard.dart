import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../dat/pinball_data.dart' show ScoreField;
import '../graphics.dart';
import 'text_box.dart';

/// The scoreboard's live parts, drawn over the scoreboard art: score, ball
/// number and player number in the original digit sprites
/// (`score::update`), and the two message boxes.
class ScoreboardComponent extends Component {
  ScoreboardComponent({
    required this.score,
    required this.ballCount,
    required this.playerNumber,
    required this.info,
    required this.mission,
    required this.values,
  });

  final DigitField? score, ballCount, playerNumber;
  final TextField? info, mission;

  /// Current score, ball and player; null hides a field.
  final ({int? score, int? ball, int? player}) Function() values;

  @override
  void render(Canvas canvas) {
    final v = values();
    score?.render(canvas, v.score);
    ballCount?.render(canvas, v.ball);
    playerNumber?.render(canvas, v.player);
    info?.render(canvas);
    mission?.render(canvas);
  }
}

/// Digits right-aligned in a box, as `score::update`.
class DigitField {
  DigitField(this.field, this.digits, this.graphics);

  final ScoreField field;
  final List<Image> digits;
  final Graphics graphics;

  void render(Canvas canvas, int? value) {
    if (value == null || value < 0) return;
    var x = (field.x + field.width).toDouble();
    final text = value.toString();
    for (var i = text.length - 1; i >= 0; i--) {
      final d = text.codeUnitAt(i) - 0x30;
      final image = digits[d];
      x -= image.width;
      // The digits stay classic in HD too: upscaled they lose their
      // dot-matrix look.
      canvas.drawImage(
        image,
        Offset(x, field.y.toDouble()),
        Graphics.classicPaint,
      );
    }
  }
}

/// A message box. 3D Pinball drew these with the Windows system font in
/// white (`TextBoxColor` = 255 255 255), wrapped to the box.
///
/// TODO: VERIFY AGAINST ORIGINAL SPACE CADET — font face and size; the
/// original used the system's default GUI font, which is not part of the
/// game files.
class TextField {
  TextField(this.box, this.rect);

  final TextBox box;
  final Rect rect;

  static const _style = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 10,
    height: 1.2,
  );

  String? _laidOut;
  final TextPainter _painter = TextPainter(textDirection: TextDirection.ltr);

  void render(Canvas canvas) {
    final text = box.text;
    if (text == null) return;
    if (text != _laidOut) {
      _painter
        ..text = TextSpan(text: text, style: _style)
        ..layout(maxWidth: rect.width);
      _laidOut = text;
    }
    canvas
      ..save()
      ..clipRect(rect);
    _painter.paint(canvas, rect.topLeft);
    canvas.restore();
  }
}
