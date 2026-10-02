import 'dart:math' as math;

import 'package:forge2d/forge2d.dart';

import '../../../dat/pinball_data.dart' as dat;
import '../../gameplay/game_timers.dart';
import '../../physics/ball.dart';
import '../../rules/message_code.dart';

/// What a part tells the rules: `control::handler(code, component)`.
/// [code] is an [MC] code, e.g. [MC.controlCollision] for a hit, a
/// rollover or a capture, [MC.controlTimerExpired] after a timed cycle.
class PartEvent {
  const PartEvent(this.part, this.code);
  final TablePart part;
  final int code;

  @override
  String toString() => '${part.name}: $code';
}

/// Everything a part may touch. Owned by [SpaceCadetTable].
class PartContext {
  PartContext({
    required this.world,
    required this.timers,
    required this.random,
    required this.balls,
    required this.ballRadius,
    required this.gravityMagnitude,
    required this.emit,
    required this.addBall,
    required this.removeBall,
    required this.playSound,
    required this.soundDuration,
    required this.partByGroup,
    required this.tilted,
    required this.drainBall,
  });

  final World world;

  /// Physics-time timers: they stop when the simulation stops.
  final GameTimers timers;
  final math.Random random;
  final List<PinballBall> balls;
  final double ballRadius;

  /// `GravityDirVectMult` (25): ramp slopes are scaled by it.
  final double gravityMagnitude;
  final void Function(PartEvent event) emit;
  final PinballBall Function(double x, double y) addBall;

  /// Removes a ball after the current step.
  final void Function(PinballBall ball) removeBall;

  /// Plays a sound record (null: none).
  final void Function(int? soundGroup) playSound;

  /// Length of a sound record in seconds, −1 when unknown
  /// (`loader::play_sound`'s return value).
  final double Function(int? soundGroup) soundDuration;

  /// The part built from DAT group [group] (`find_component`).
  final TablePart? Function(int group) partByGroup;

  /// The table is tilted (`TPinballTable::TiltLockFlag`).
  final bool Function() tilted;

  /// Sends a ball down the drain, e.g. a wormhole while tilted.
  final void Function(PinballBall ball) drainBall;
}

/// A runtime table component: the counterpart of the original's
/// `TPinballComponent` subclasses. Physics-facing behaviour only; scoring
/// and missions react to its [PartEvent]s.
abstract class TablePart {
  TablePart(this.ctx, this.component);

  final PartContext ctx;
  final dat.Component component;

  String get name => component.name ?? '#${component.group}';
  dat.VisualState get visual => component.states.first;

  /// Sprite frame to draw, -1 for none (`SpriteSet`).
  int frame = 0;

  /// Free storage for the rules (`TPinballComponent::MessageField`).
  int messageField = 0;

  /// The original's `Message(code, value)`: [MC] codes, interpreted per
  /// component type. Returns the original's return value.
  int message(int code, double value) {
    if (code == MC.reset) {
      messageField = 0;
      reset();
    }
    return 0;
  }

  /// Adds this part's field acceleration to [ball] (`FieldEffect`).
  void field(PinballBall ball) {}

  /// Box2D reported a hit of [ball] on this part's body. [normal] points
  /// from the part to the ball.
  void onHit(PinballBall ball, double approachSpeed, Vector2 normal) {}

  /// Called after each step for every free ball: sensors and trigger
  /// lines.
  void checkBall(PinballBall ball) {}

  /// New game (`MessageCode::Reset`).
  void reset() {}

  void emit(int code) => ctx.emit(PartEvent(this, code));

  /// The original's step skip when a ball passes through a line it does
  /// not bounce off (ramp edges, rollovers, tripwires, spinners, one-way
  /// walls).
  ///
  /// `pb::timed_frame` moves a ball in rays of at most half its radius;
  /// such a line ends the ray at the crossing, and the next ray starts
  /// there at full length again. So the ball travels the distance to the
  /// crossing (within its half-radius ray) a second time in that frame.
  /// Measured against the decompilation (tool/compare), this is what gets
  /// a weak ramp shot to the top.
  void passThrough(PinballBall ball, double? travelled) {
    if (travelled == null || ball.isCaptured) return;
    final ray = ctx.ballRadius / 2;
    final extra = travelled % ray;
    final v = ball.body.linearVelocity;
    final speed = v.length;
    if (extra <= 0 || speed == 0) return;
    ball.body.setTransform(
      ball.body.position + v * (extra / speed),
      ball.body.rotation,
    );
  }

  void sound(int? group) => ctx.playSound(group);

  /// `maths::basic_collision` with a kicker: on a hit at or above the
  /// threshold, the boost is added along the normal (on top of the
  /// rebound Box2D already applied). Returns whether it kicked.
  static bool kick(
    PinballBall ball,
    double approachSpeed,
    Vector2 normal,
    double threshold,
    double boost,
  ) {
    if (approachSpeed < threshold) return false;
    if (boost != 0) {
      ball.body.linearVelocity = ball.body.linearVelocity + normal * boost;
    }
    return true;
  }

  /// `TBall::throw_ball`: a direction rotated by ±angleMult at random and
  /// a speed of boost ± boost · throwMult %.
  static Vector2 throwVelocity(dat.Kicker k, math.Random random) {
    final (dx, dy, _) = k.throwBallDirection ?? (0.0, -1.0, 0.0);
    final angle = (1 - 2 * random.nextDouble()) * (k.throwBallAngleMult ?? 0);
    final c = math.cos(angle), s = math.sin(angle);
    final mult = (k.throwBallMult ?? 0) * 0.01;
    final speed = (1 - 2 * random.nextDouble()) * (k.boost * mult) + k.boost;
    return Vector2(dx * c - dy * s, dx * s + dy * c)..scale(speed);
  }
}

/// A one-sided trigger line, like a `TLine` the ball passes through: it
/// fires when the ball centre crosses from the line's right side (the
/// side its normal points to) to the left, on a matching layer.
class TriggerLine {
  const TriggerLine(this.x1, this.y1, this.x2, this.y2, this.layers);

  /// The line moved [offset] along its normal, as `TLine::Offset`. Walls
  /// the original builds with `createWall` are offset by the ball radius,
  /// so they fire when the ball's edge, not its centre, reaches them.
  factory TriggerLine.offset(
    double x1,
    double y1,
    double x2,
    double y2,
    int layers,
    double offset,
  ) {
    final dx = x2 - x1, dy = y2 - y1;
    final len = math.sqrt(dx * dx + dy * dy);
    final ox = dy / len * offset, oy = -dx / len * offset;
    return TriggerLine(x1 + ox, y1 + oy, x2 + ox, y2 + oy, layers);
  }

  final double x1, y1, x2, y2;
  final int layers;

  TriggerLine get reversed => TriggerLine(x2, y2, x1, y1, layers);

  bool crossedBy(PinballBall b) => crossingDistance(b) != null;

  /// How far the ball travelled this step before it crossed the line from
  /// its side, or null if it did not.
  double? crossingDistance(PinballBall b) {
    if (b.layers & layers == 0) return null;
    final mx = b.x - b.prevX, my = b.y - b.prevY;
    final dx = x2 - x1, dy = y2 - y1;
    // Normal (dy, -dx); moving against it means coming from its side.
    if (mx * dy - my * dx >= 0) return null;
    if (!segmentsIntersect(b.prevX, b.prevY, b.x, b.y, x1, y1, x2, y2)) {
      return null;
    }
    return segmentCrossing(b.prevX, b.prevY, b.x, b.y, x1, y1, x2, y2);
  }

  /// Distance from (ax, ay) along a→b to where it meets the line c–d.
  static double segmentCrossing(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
    double dx,
    double dy,
  ) {
    final ex = dx - cx, ey = dy - cy;
    final d1 = ex * (ay - cy) - ey * (ax - cx);
    final d2 = ex * (by - cy) - ey * (bx - cx);
    final t = d1 == d2 ? 0.0 : d1 / (d1 - d2);
    final mx = bx - ax, my = by - ay;
    return t * math.sqrt(mx * mx + my * my);
  }

  static bool segmentsIntersect(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
    double dx,
    double dy,
  ) {
    double cross(double ux, double uy, double vx, double vy) =>
        ux * vy - uy * vx;
    final d1 = cross(dx - cx, dy - cy, ax - cx, ay - cy);
    final d2 = cross(dx - cx, dy - cy, bx - cx, by - cy);
    final d3 = cross(bx - ax, by - ay, cx - ax, cy - ay);
    final d4 = cross(bx - ax, by - ay, dx - ax, dy - ay);
    return (d1 > 0) != (d2 > 0) && (d3 > 0) != (d4 > 0);
  }
}

/// Point-in-polygon for sensor areas (rollovers).
/// Distance from the ball's previous position to the first edge of the
/// polygon [pts] it crossed this step, or null.
double? polygonCrossing(List<double> pts, PinballBall b) {
  double? best;
  final n = pts.length ~/ 2;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final (cx, cy, dx, dy) = (
      pts[2 * j],
      pts[2 * j + 1],
      pts[2 * i],
      pts[2 * i + 1],
    );
    if (!TriggerLine.segmentsIntersect(
      b.prevX,
      b.prevY,
      b.x,
      b.y,
      cx,
      cy,
      dx,
      dy,
    )) {
      continue;
    }
    final d = TriggerLine.segmentCrossing(
      b.prevX,
      b.prevY,
      b.x,
      b.y,
      cx,
      cy,
      dx,
      dy,
    );
    if (best == null || d < best) best = d;
  }
  return best;
}

bool insidePolygon(List<double> pts, double x, double y) {
  var inside = false;
  final n = pts.length ~/ 2;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final xi = pts[2 * i], yi = pts[2 * i + 1];
    final xj = pts[2 * j], yj = pts[2 * j + 1];
    if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}
