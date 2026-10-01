import 'dart:math' as math;
import 'dart:ui';

/// Where the cadet's car is drawn: its centre, width and turn.
class CadetPose {
  const CadetPose(this.center, this.width, this.facing, this.angle);

  final Offset center;
  final double width;

  /// 1 facing left as in the art, -1 mirrored (flying to the right).
  final double facing;

  /// Bank in radians, nose following the flight path.
  final double angle;
}

/// One pass of the car across the view: in from one edge, out at the far
/// side, so it never turns round in sight.
class CadetFlight {
  CadetFlight._(
    this.start,
    this.duration,
    this.right,
    this._from,
    this._to,
    this._bend,
    this._scaleFrom,
    this._scaleTo,
    this._bob,
  );

  /// A random pass starting at [start] seconds: from the left or right
  /// edge, or diagonally from above or below; near and large or far and
  /// small, or coming closer or moving away on the way.
  factory CadetFlight.random(math.Random r, double start) {
    double between(double a, double b) => a + r.nextDouble() * (b - a);
    final right = r.nextBool();
    final s0 = between(0.3, 1),
        s1 = (s0 + between(-0.45, 0.45)).clamp(0.3, 1.0);
    // Nearer is lower in the view.
    double sideY(double s) => (0.25 + 0.45 * s + between(-0.15, 0.15));
    final viaTop = r.nextDouble() < 0.4;
    final atStart = r.nextBool();
    _Edge edge(bool start, double s) {
      if (viaTop && start == atStart) {
        return _Edge.vertical(between(0.05, 0.3), above: r.nextBool());
      }
      return _Edge.side(sideY(s));
    }

    final from = edge(true, s0), to = edge(false, s1);
    final bend = Offset(between(0.35, 0.65), between(0.2, 0.85));
    // Far away moves slower across the view.
    final speed = 0.22 + 0.33 * (s0 + s1) / 2;
    final duration = 1.6 / speed * between(0.9, 1.1);
    return CadetFlight._(
      start,
      duration,
      right,
      from,
      to,
      bend,
      s0,
      s1,
      between(0, 2 * math.pi),
    );
  }

  final double start, duration;

  /// Flying to the right (the car mirrored).
  final bool right;

  final _Edge _from, _to;
  final Offset _bend;
  final double _scaleFrom, _scaleTo, _bob;

  double get end => start + duration;

  /// Car width at full size, as a share of the view's width.
  static const fullWidth = 0.62;

  /// The pose at [time], or null outside this pass. [aspect] is the car
  /// image's height over its width.
  CadetPose? poseAt(double time, Size size, double aspect) {
    final t = (time - start) / duration;
    if (t < 0 || t > 1) return null;
    final w = size.width, h = size.height;
    double widthAt(double s) => w * fullWidth * s;

    // Start and end just out of view at their own size, the bend in the
    // view. With x as progress from the start side the path always heads
    // one way, so the car does not turn in sight.
    Offset point(_Edge e, double s, {required bool isStart}) {
      final halfW = widthAt(s) / 2, halfH = halfW * aspect;
      final fromLeft = isStart == right;
      if (e.vertical) {
        final x = fromLeft ? e.along * w : w - e.along * w;
        return Offset(x, e.above ? -halfH - 2 : h + halfH + 2);
      }
      return Offset(fromLeft ? -halfW - 2 : w + halfW + 2, e.along * h);
    }

    final p0 = point(_from, _scaleFrom, isStart: true);
    final p2 = point(_to, _scaleTo, isStart: false);
    final p1 = Offset(right ? _bend.dx * w : (1 - _bend.dx) * w, _bend.dy * h);
    final u = 1 - t;
    final pos = p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
    final vel = (p1 - p0) * (2 * u) + (p2 - p1) * (2 * t);

    final facing = right ? -1.0 : 1.0;
    final climb = math.atan2(vel.dy, vel.dx.abs()).clamp(-0.6, 0.6);
    final wobble = math.sin(time * 5 + _bob);
    return CadetPose(
      pos + Offset(0, wobble * h * 0.02),
      widthAt(_scaleFrom + (_scaleTo - _scaleFrom) * t),
      facing,
      -climb * 0.6 * facing + math.cos(time * 5 + _bob) * 0.04,
    );
  }
}

/// One end of a pass: on the left or right edge at a height, or above or
/// below the view at a distance from the start (or end) side.
class _Edge {
  const _Edge.side(this.along) : vertical = false, above = false;
  const _Edge.vertical(this.along, {required this.above}) : vertical = true;

  final bool vertical, above;

  /// Height (side) or distance from the side (vertical), as a share.
  final double along;
}

/// An endless series of random passes with short pauses between them.
class CadetFlights {
  CadetFlights([math.Random? random]) : _random = random ?? math.Random() {
    _current = CadetFlight.random(_random, 0.2);
  }

  final math.Random _random;
  late CadetFlight _current;

  /// The pose at [time] seconds (it only moves forward), or null while the
  /// car is between passes.
  CadetPose? poseAt(double time, Size size, double aspect) {
    while (time > _current.end) {
      final gap = 0.3 + _random.nextDouble() * 1.2;
      _current = CadetFlight.random(_random, _current.end + gap);
    }
    return _current.poseAt(time, size, aspect);
  }
}
