/// Bumping the table (`nudge.cpp`).
///
/// A bump adds (±1, 0.5) to every free ball's velocity, shifts the view a
/// couple of pixels and is undone 0.4 s later (the same push the other way,
/// as the original). While a bump is held the tilt counter rises by 4 per
/// second; otherwise it falls by 1 per second. Above 0.5 the player is
/// warned, above 1 the table tilts. Pure Dart.
class Nudge {
  Nudge({required this.push, required this.shift});

  /// Adds (dx, dy) to every free ball's velocity, in table units.
  final void Function(double dx, double dy) push;

  /// Moves the view by (x, y) screen pixels (`render::shift`).
  final void Function(int x, int y) shift;

  static const holdTime = 0.4;
  static const warnLevel = 0.5;
  static const tiltLevel = 1.0;

  /// `nudge_count`.
  double count = 0;

  (double, double)? _active;
  double _left = 0;

  bool get active => _active != null;

  /// LeftTableBump pushes the ball to the right of the table and so on;
  /// [xDiff]/[yDiff] are the original's arguments to `_nudge`.
  void bump(double xDiff, double yDiff) {
    final previous = _active;
    if (previous != null) _undo(previous);
    _apply(xDiff, yDiff);
    _active = (xDiff, yDiff);
    _left = holdTime;
  }

  /// The original's three bumps.
  void bumpLeft() => bump(2, 1); // nudge_right: from the left side
  void bumpRight() => bump(-2, 1); // nudge_left: from the right side
  void bumpBottom() => bump(0, 1); // nudge_up

  void update(double dt) {
    final a = _active;
    if (a != null) {
      count += dt * 4;
      _left -= dt;
      if (_left <= 0) {
        _undo(a);
        _active = null;
      }
    } else {
      count = count - dt <= 0 ? 0 : count - dt;
    }
  }

  /// `pb::tilt_no_more`: a fresh ball gets some leeway.
  void reset() {
    final a = _active;
    if (a != null) _undo(a);
    _active = null;
    count = -2;
  }

  void _apply(double xDiff, double yDiff) {
    push(xDiff * 0.5, yDiff * 0.5);
    shift((xDiff + 0.5).floor(), (0.5 - yDiff).floor());
  }

  void _undo((double, double) a) {
    push(-a.$1 * 0.5, -a.$2 * 0.5);
    shift(-(a.$1 + 0.5).floor(), -(0.5 - a.$2).floor());
  }
}
