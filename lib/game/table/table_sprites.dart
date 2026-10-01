import 'dart:ui';

import 'package:flame/components.dart';

import '../assets/original_assets.dart';
import '../graphics.dart';
import 'ball_renderer.dart';
import 'space_cadet_table.dart';
import 'table_projection.dart';

/// An original component sprite whose frame follows game state, e.g. a
/// flipper's angle or the plunger's pullback. [frame] returns -1 to hide.
class ComponentSprite extends Component {
  ComponentSprite(this.frames, this.frame, this.graphics);

  final List<SpriteFrame?> frames;
  final int Function() frame;
  final Graphics graphics;

  @override
  void render(Canvas canvas) {
    final i = frame();
    if (i < 0 || i >= frames.length) return;
    final f = frames[i];
    if (f != null) graphics.drawBitmap(canvas, f.image, f.group, f.offset);
  }
}

/// Draws every ball on the table: the original sprites by depth when
/// available, otherwise a plain circle.
class BallsComponent extends Component {
  BallsComponent(this.table, this.projection, this.renderer);

  final SpaceCadetTable table;
  final TableProjection projection;
  final BallRenderer? renderer;

  static final _fallback = Paint()..color = const Color(0xFFC8C8D0);

  @override
  void render(Canvas canvas) {
    for (final b in table.balls) {
      final r = renderer;
      if (r != null) {
        r.render(canvas, b.x, b.y, b.z);
      } else {
        canvas.drawCircle(
          projection.toScreen(b.x, b.y),
          projection.scaleAt(b.x, b.y, b.radius),
          _fallback,
        );
      }
    }
  }
}

/// Without original art: flippers and plunger as plain projected shapes, so
/// the table is still playable.
class PlaceholderParts extends Component {
  PlaceholderParts(this.table, this.projection);

  final SpaceCadetTable table;
  final TableProjection projection;

  static final _flipper = Paint()..color = const Color(0xFFE0E0E8);
  static final _plunger = Paint()
    ..color = const Color(0xFFE0A040)
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    final t = table;
    for (final f in [t.leftFlipper, t.rightFlipper]) {
      final path = Path();
      var first = true;
      for (final (x, y) in f.outline()) {
        final p = projection.toScreen(x, y);
        first ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        first = false;
      }
      canvas.drawPath(path..close(), _flipper);
    }
    final s = t.plunger.spec;
    final pull = t.plunger.boost / 100 * 1.5;
    canvas.drawLine(
      projection.toScreen(s.x1, s.y1 + pull),
      projection.toScreen(s.x2, s.y2 + pull),
      _plunger,
    );
  }
}
