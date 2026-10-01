import 'dart:ui';

/// Maps table space (the flat physics plane, in original table units) to
/// screen space (the original 600 × 416 virtual screen).
///
/// With the original data this is [CameraProjection], the perspective
/// camera from PINBALL.DAT. Without it, [LinearProjection] is a flat
/// stand-in with the same orientation.
abstract interface class TableProjection {
  Offset toScreen(double x, double y);

  /// Screen-space radius of something [radius] table units wide at (x, y).
  double scaleAt(double x, double y, double radius);

  /// Inverse mapping, for debug clicks that spawn a ball.
  (double, double) toTable(Offset screen);
}

/// Linear map of [table] onto [screen], oriented like the original camera:
/// table +x is screen left, table +y (towards the drain) is screen down.
class LinearProjection implements TableProjection {
  const LinearProjection({required this.table, required this.screen});

  final Rect table;
  final Rect screen;

  double get _sx => screen.width / table.width;
  double get _sy => screen.height / table.height;

  @override
  Offset toScreen(double x, double y) => Offset(
    screen.right - (x - table.left) * _sx,
    screen.top + (y - table.top) * _sy,
  );

  @override
  double scaleAt(double x, double y, double radius) => radius * _sx;

  @override
  (double, double) toTable(Offset p) => (
    table.left + (screen.right - p.dx) / _sx,
    table.top + (p.dy - screen.top) / _sy,
  );
}
