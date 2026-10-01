import 'dart:math' as math;

import '../../physics/ball.dart';
import '../../physics/ramp_plane.dart';
import 'part.dart';

/// `TRamp`: a raised track built from triangular planes (attribute 1300).
///
/// The ramp is made of trigger lines, not walls (its rails are ordinary
/// walls on the ramp's layer):
/// - every plane edge puts a ball that crosses it onto that plane: on the
///   ramp's layer, with the plane's slope gravity and height;
/// - the two exit edges (1301, 1302) put it back on a flat level — the
///   playfield or the upper level — when enabled;
/// - the entry line (1303) is reported to the rules.
class RampPart extends TablePart {
  RampPart(super.ctx, super.component) {
    final a = component.attributes;
    rampLayers = visual.collisionMask;
    fieldMult = a[701]?.first ?? 0.2;
    zOffsetFlag = (a[1305]?.first ?? 0) != 0;

    final p = a[1300]!;
    final count = p[0].floor();
    for (var i = 0; i < count; i++) {
      final o = 1 + i * 13;
      planes.add(
        RampPlane(
          offsetX: p[o],
          offsetY: p[o + 1],
          offsetZ: p[o + 2],
          points: p.sublist(o + 3, o + 9),
          gravityAngle1: p[o + 9],
          gravityAngle2: p[o + 10],
          gravityMagnitude: ctx.gravityMagnitude,
        ),
      );
    }

    final w0 = a[1303]!;
    _entry = TriggerLine(w0[4], w0[5], w0[2], w0[3], 1 << w0[0].floor());

    final exit1 = _exit(a[1301]!);
    final exit2 = _exit(a[1302]!);
    _exits = [exit1.$1, exit2.$1];

    for (final plane in planes) {
      final v = plane.points;
      for (var e = 0; e < 3; e++) {
        final i = e * 2, j = ((e + 1) % 3) * 2;
        final (x1, y1, x2, y2) = (v[i], v[i + 1], v[j], v[j + 1]);
        var layers = rampLayers;
        for (final (exit, enabled, group) in [exit1.$2, exit2.$2]) {
          if (_same(exit, x1, y1, x2, y2)) layers = enabled ? group : 0;
        }
        if (layers != 0) {
          _entries.add((TriggerLine(x1, y1, x2, y2, layers), plane));
        }
      }
    }
    frame = -1;
  }

  final List<RampPlane> planes = [];
  late final int rampLayers;
  late final double fieldMult;
  late final bool zOffsetFlag;
  late final TriggerLine _entry;

  /// Exit lines with the layer and height offset they lead to.
  late final List<(TriggerLine, int, double)> _exits;

  /// Plane edges and the plane they lead onto.
  final List<(TriggerLine, RampPlane)> _entries = [];

  /// Parses 1301/1302: [layer bit, enabled, count, x0, y0, x1, y1, offset],
  /// matched to the nearest plane edge (`maths::find_closest_edge`).
  ((TriggerLine, int, double), ((double, double, double, double), bool, int))
  _exit(List<double> w) {
    final group = 1 << w[0].floor();
    final enabled = w[1].floor() != 0;
    final (px0, py0, px1, py1) = (w[3], w[4], w[5], w[6]);
    var best = double.infinity;
    var end = (0.0, 0.0), start = (0.0, 0.0);
    for (final plane in planes) {
      final v = plane.points;
      for (var e = 0; e < 3; e++) {
        final i = e * 2, j = ((e + 1) % 3) * 2;
        final d =
            _dist(px0, py0, v[i], v[i + 1]) + _dist(px1, py1, v[j], v[j + 1]);
        if (d < best) {
          best = d;
          end = (v[i], v[i + 1]);
          start = (v[j], v[j + 1]);
        }
      }
    }
    // Exit line: start → end, on the ramp's layer.
    final line = TriggerLine(start.$1, start.$2, end.$1, end.$2, rampLayers);
    return (
      (line, group, w[7]),
      ((end.$1, end.$2, start.$1, start.$2), enabled, group),
    );
  }

  static double _dist(double ax, double ay, double bx, double by) {
    final dx = ax - bx, dy = ay - by;
    return math.sqrt(dx * dx + dy * dy);
  }

  static bool _same(
    (double, double, double, double) e,
    double x1,
    double y1,
    double x2,
    double y2,
  ) => e.$1 == x1 && e.$2 == y1 && e.$3 == x2 && e.$4 == y2;

  bool _owns(PinballBall b) =>
      b.rampPlane != null && planes.contains(b.rampPlane);

  @override
  void field(PinballBall ball) {
    if (!_owns(ball) || ball.layers & rampLayers == 0) return;
    final p = ball.rampPlane!;
    final v = ball.body.linearVelocity;
    ball.fieldAccel
      ..x += p.fieldX - v.x * fieldMult
      ..y += p.fieldY - v.y * fieldMult;
  }

  @override
  void checkBall(PinballBall ball) {
    if (_entry.crossedBy(ball)) {
      sound(visual.softHitSound);
      emit(PartEventKind.collision);
    }
    for (final (line, layers, offset) in _exits) {
      if (_owns(ball) && line.crossedBy(ball)) {
        ball
          ..rampPlane = null
          ..layers = layers;
        if (zOffsetFlag) ball.z = ball.radius + offset;
        return;
      }
    }
    for (final (line, plane) in _entries) {
      if (line.crossedBy(ball)) {
        ball
          ..rampPlane = plane
          ..layers = rampLayers;
        break;
      }
    }
    if (_owns(ball)) {
      ball.z = ball.rampPlane!.heightAt(ball.x, ball.y, ball.radius);
    }
  }
}
