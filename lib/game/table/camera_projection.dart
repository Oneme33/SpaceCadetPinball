import 'dart:math' as math;
import 'dart:ui';

import '../../dat/pinball_data.dart';
import 'table_projection.dart';

/// The original perspective projection (`proj.cpp` in the decompilation).
///
/// A table-space point (x, y, z) is transformed by the 3 × 4 camera matrix
/// and divided by its depth:
///
///     v  = M · (x, y, z, 1)
///     sx = v.x · d / v.z + centerX
///     sy = v.y · d / v.z + centerY
///
/// d is negative in the DAT, so table +x is screen left and table +y
/// (towards the drain) is screen down.
class CameraProjection implements TableProjection {
  CameraProjection(CameraInfo c)
    : _m = List.unmodifiable(c.matrix),
      _d = c.d,
      _cx = c.centerX,
      _cy = c.centerY;

  final List<double> _m;
  final double _d, _cx, _cy;

  @override
  Offset toScreen(double x, double y) => toScreen3(x, y, 0);

  Offset toScreen3(double x, double y, double z) {
    final m = _m;
    final vx = m[0] * x + m[1] * y + m[2] * z + m[3];
    final vy = m[4] * x + m[5] * y + m[6] * z + m[7];
    final vz = m[8] * x + m[9] * y + m[10] * z + m[11];
    final k = vz == 0 ? 999999.88 : _d / vz;
    return Offset(vx * k + _cx, vy * k + _cy);
  }

  /// Distance from the camera (`proj::z_distance`). Used to pick the ball
  /// sprite size.
  double depth(double x, double y, double z) {
    final m = _m;
    final vx = m[0] * x + m[1] * y + m[2] * z + m[3];
    final vy = m[4] * x + m[5] * y + m[6] * z + m[7];
    final vz = m[8] * x + m[9] * y + m[10] * z + m[11];
    return math.sqrt(vx * vx + vy * vy + vz * vz);
  }

  @override
  double scaleAt(double x, double y, double radius) {
    final a = toScreen(x, y);
    final b = toScreen(x + radius, y);
    return (b - a).distance;
  }

  /// Inverse for points on the table plane (z = 0), as `proj::ReverseXForm`.
  @override
  (double, double) toTable(Offset p) {
    final a = _m[5], b = _m[6], f = _m[7], g = _m[11];
    final x2 = (p.dx - _cx) / _d;
    final y2 = (p.dy - _cy) / _d;
    final y0 = (y2 * g - f) / (a + b * y2);
    final x0 = x2 * (-b * y0 + g);
    return (x0, y0);
  }
}
