import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle;

import '../game_config.dart';

/// Stand-in for the playfield and scoreboard art until the extractor
/// (Phase 2) produces them from PINBALL.DAT.
///
/// Deliberately plain and labelled, so it can never be mistaken for final
/// artwork. Sizes and positions are the real ones from the DAT.
class PlaceholderTable extends Component {
  static final _playfieldFill = Paint()..color = const Color(0xFF0B0F2A);
  static final _scoreboardFill = Paint()..color = const Color(0xFF15122B);
  static final _outline = Paint()
    ..color = const Color(0xFF5B4FA8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  static final _label = TextPaint(
    style: const TextStyle(color: Color(0xFF7D74C9), fontSize: 10),
  );

  @override
  void render(Canvas canvas) {
    for (final (rect, fill, text) in [
      (GameConfig.playfieldRect, _playfieldFill, 'PLACEHOLDER\nplayfield'),
      (GameConfig.scoreboardRect, _scoreboardFill, 'PLACEHOLDER\nscoreboard'),
    ]) {
      canvas
        ..drawRect(rect, fill)
        ..drawRect(rect, _outline);
      _label.render(
        canvas,
        text,
        Vector2(rect.center.dx, rect.center.dy),
        anchor: Anchor.center,
      );
    }
  }
}
