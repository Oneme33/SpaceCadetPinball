import 'dart:math' as math;

/// One triangle of a ramp (`ramp_plane_type`): its own slope gravity and
/// the plane that gives a ball on it its height.
class RampPlane {
  RampPlane({
    required this.offsetX,
    required this.offsetY,
    required this.offsetZ,
    required this.points,
    required double gravityAngle1,
    required double gravityAngle2,
    required double gravityMagnitude,
  }) : fieldX =
           math.cos(gravityAngle2) * math.sin(gravityAngle1) * gravityMagnitude,
       fieldY =
           math.sin(gravityAngle2) * math.sin(gravityAngle1) * gravityMagnitude;

  /// z = x · offsetX + y · offsetY + radius + offsetZ (`TBall::Repaint`).
  final double offsetX, offsetY, offsetZ;

  /// V1, V2, V3 as x0, y0, x1, y1, x2, y2.
  final List<double> points;

  /// Extra acceleration on the ball while it is on this plane.
  final double fieldX, fieldY;

  double heightAt(double x, double y, double radius) =>
      x * offsetX + y * offsetY + radius + offsetZ;
}
