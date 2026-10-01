import 'dart:math' as math;

import 'package:forge2d/forge2d.dart';

import '../../../dat/pinball_data.dart' as dat;
import '../../gameplay/game_timers.dart';
import '../../physics/ball.dart';

/// What a part tells the rules, after the original's `control::handler`
/// message codes.
enum PartEventKind {
  /// `ControlCollision`: hit, rolled over, crossed, captured…
  collision,

  /// `ControlBallCaptured`: a hole took the ball.
  ballCaptured,

  /// `ControlBallReleased`: a hole let the ball go on a new level.
  ballReleased,

  /// `ControlTimerExpired`: e.g. a kickback finished its cycle.
  timerExpired,

  /// `ControlSpinnerLoopReset`: a spinner completed a full turn.
  spinnerLoopReset,
}

class PartEvent {
  const PartEvent(this.part, this.kind);
  final TablePart part;
  final PartEventKind kind;

  @override
  String toString() => '${part.name}: ${kind.name}';
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

  void emit(PartEventKind kind) => ctx.emit(PartEvent(this, kind));

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

  bool crossedBy(PinballBall b) {
    if (b.layers & layers == 0) return false;
    final mx = b.x - b.prevX, my = b.y - b.prevY;
    final dx = x2 - x1, dy = y2 - y1;
    // Normal (dy, -dx); moving against it means coming from its side.
    if (mx * dy - my * dx >= 0) return false;
    return segmentsIntersect(b.prevX, b.prevY, b.x, b.y, x1, y1, x2, y2);
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
