import 'dart:math' as math;

import '../../../dat/pinball_data.dart' as dat;
import '../../physics/ball.dart';
import 'part.dart';
import '../../rules/message_code.dart';

/// `TRollover` / `TLightRollover`: a lane switch the ball rolls over. It
/// fires when the ball centre enters its area (attribute 600) and re-arms
/// when the ball has left it.
///
/// A rollover's sprite (the wire) disappears while the ball is on it. A
/// light rollover's sprite is a light that comes on when rolled over and
/// goes off again after its delay (attribute 407).
class RolloverPart extends TablePart {
  RolloverPart(super.ctx, super.component, {required this.isLight})
    : area = (component.states.first.walls.first as dat.WallPolygon).points,
      layers = component.states.first.collisionMask,
      lightDelay = component.attributes[407]?.first ?? 0 {
    frame = isLight ? -1 : 0;
  }

  final bool isLight;
  final List<double> area;
  final int layers;
  final double lightDelay;

  final Set<PinballBall> _inside = {};
  int? _lightTimer;

  @override
  void checkBall(PinballBall ball) {
    final inside =
        ball.layers & layers != 0 && insidePolygon(area, ball.x, ball.y);
    if (inside && _inside.add(ball)) {
      frame = isLight ? 0 : -1;
      if (_lightTimer case final t?) ctx.timers.cancel(t);
      sound(visual.softHitSound);
      emit(MC.controlCollision);
    } else if (!inside && _inside.remove(ball)) {
      if (isLight) {
        _lightTimer = ctx.timers.set(lightDelay, () => frame = -1);
      } else if (_inside.isEmpty) {
        frame = 0;
      }
    }
  }

  @override
  void reset() {
    _inside.clear();
    frame = isLight ? -1 : 0;
  }
}

/// `TTripwire`: an invisible one-sided line in a lane.
class TripwirePart extends TablePart {
  TripwirePart(super.ctx, super.component) {
    final l = visual.walls.whereType<dat.WallLine>().first;
    _line = TriggerLine.offset(
      l.x1,
      l.y1,
      l.x2,
      l.y2,
      visual.collisionMask,
      ctx.ballRadius,
    );
    frame = -1;
  }

  late final TriggerLine _line;

  @override
  void checkBall(PinballBall ball) {
    if (_line.crossedBy(ball)) {
      sound(visual.softHitSound);
      emit(MC.controlCollision);
    }
  }
}

/// `TFlagSpinner`: the ball passes through and spins the flag. Spin speed
/// is 20 × ball speed (clamped by attributes 1200/1201) and decays by
/// attribute 1202 per frame; every frame is reported, a full turn too.
class SpinnerPart extends TablePart {
  SpinnerPart(super.ctx, super.component)
    : speedDecrement = component.attributes[1202]?.first ?? 0.65,
      maxSpeed = component.attributes[1200]?.first ?? 50000,
      minSpeed = component.attributes[1201]?.first ?? 5 {
    final l = visual.walls.whereType<dat.WallLine>().first;
    // TFlagSpinner: end = first point, start = second.
    _forward = TriggerLine(l.x2, l.y2, l.x1, l.y1, visual.collisionMask);
    _backward = _forward.reversed;
  }

  final double speedDecrement, maxSpeed, minSpeed;
  late final TriggerLine _forward, _backward;

  int _direction = 1;
  double _speed = 0;
  int? _timer;

  int get frames => component.states.length;

  @override
  void checkBall(PinballBall ball) {
    final int direction;
    if (_forward.crossedBy(ball)) {
      direction = 1;
    } else if (_backward.crossedBy(ball)) {
      direction = -1;
    } else {
      return;
    }
    _direction = direction;
    _speed = (ball.speed == 0 ? minSpeed : ball.speed * 20).clamp(
      minSpeed,
      maxSpeed,
    );
    if (_timer case final t?) ctx.timers.cancel(t);
    _nextFrame();
  }

  void _nextFrame() {
    _timer = null;
    frame = (frame + _direction) % frames;
    sound(visual.softHitSound);
    emit(MC.controlCollision);
    if (frame == 0) emit(MC.controlSpinnerLoopReset);
    _speed *= speedDecrement;
    if (_speed >= minSpeed) _timer = ctx.timers.set(1 / _speed, _nextFrame);
  }

  @override
  void reset() {
    if (_timer case final t?) ctx.timers.cancel(t);
    _timer = null;
    frame = 0;
  }
}

/// `TKickout`: a saucer. Within its field radius it pulls the ball in
/// (attribute 305); within the capture radius (306 × radius) it holds the
/// ball, sunk to height 408, and throws it out again with its kicker.
///
/// The rules decide how long a ball is held (`TKickoutRestartTimer`);
/// −1 means the default of 1.5 s.
class KickoutPart extends TablePart {
  KickoutPart(super.ctx, super.component, {required this.lit})
    : _circle = component.states.first.walls.first as dat.WallCircle,
      fieldMult = component.attributes[305]!.first,
      captureRadius =
          component.attributes[306]!.first *
          (component.states.first.walls.first as dat.WallCircle).radius,
      captureZ = component.attributes[408]![2],
      // a_kout1 (the gravity well) is off until the rules switch it on.
      active = lit {
    frame = -1;
  }

  /// `TKickout(..., someFlag)`: kickouts with a light are active by
  /// default; the unlit one only when the rules say so.
  final bool lit;
  final dat.WallCircle _circle;
  final double fieldMult, captureRadius, captureZ;

  static const holdTime = 1.5;
  static const reactivateTime = 0.05;

  bool active;
  PinballBall? _held;

  bool _onLayer(PinballBall b) => b.layers & visual.collisionMask != 0;

  @override
  void field(PinballBall ball) {
    if (!active || _held != null || !_onLayer(ball)) return;
    final dx = _circle.x - ball.x, dy = _circle.y - ball.y;
    final d2 = dx * dx + dy * dy;
    if (d2 > _circle.radius * _circle.radius || d2 == 0) return;
    final d = math.sqrt(d2);
    final v = ball.body.linearVelocity;
    ball.fieldAccel
      ..x += dx / d * fieldMult - v.x
      ..y += dy / d * fieldMult - v.y;
  }

  @override
  void checkBall(PinballBall ball) {
    if (!active || _held != null || !_onLayer(ball)) return;
    final dx = _circle.x - ball.x, dy = _circle.y - ball.y;
    if (dx * dx + dy * dy > captureRadius * captureRadius) return;
    _held = ball;
    ball.capture(this, _circle.x, _circle.y, z: captureZ);
    if (ctx.tilted()) {
      message(MC.tKickoutRestartTimer, 0.1);
      return;
    }
    sound(visual.softHitSound);
    emit(MC.controlCollision);
  }

  int? _ejectTimer;

  /// `TKickout::Message`: the rules decide when the ball comes out.
  @override
  int message(int code, double value) {
    switch (code) {
      case MC.tKickoutRestartTimer:
        if (_held != null) {
          if (_ejectTimer case final t?) ctx.timers.cancel(t);
          _ejectTimer = ctx.timers.set(value < 0 ? holdTime : value, () {
            _ejectTimer = null;
            eject();
          });
        }
      case MC.setTiltLock:
        if (!lit) active = false;
      case MC.reset:
        if (_held != null) {
          if (_ejectTimer case final t?) ctx.timers.cancel(t);
          eject();
        }
        if (!lit) active = false;
    }
    return 0;
  }

  void eject() {
    final ball = _held;
    if (ball == null) return;
    _held = null;
    final v = TablePart.throwVelocity(visual.kicker, ctx.random);
    sound(visual.hardHitSound);
    ball.release(v.x, v.y, z: ctx.ballRadius);
    active = false;
    ctx.timers.set(reactivateTime, () => active = lit);
  }

  @override
  void reset() {
    eject();
    active = lit;
  }

  bool get holdsBall => _held != null;
}

/// `TSink`: a wormhole. The ball disappears and comes back out of the sink
/// at attribute 601 after its timer (407), thrown by its kicker.
///
/// The rules pick which wormhole the ball comes out of and when
/// (`TSinkResetTimer`, `WormHoleControl`).
class SinkPart extends TablePart {
  SinkPart(super.ctx, super.component)
    : timerTime = component.attributes[407]?.first ?? 2,
      exitX = component.attributes[601]![0],
      exitY = component.attributes[601]![1] {
    final l = visual.walls.whereType<dat.WallLine>().first;
    _line = TriggerLine.offset(
      l.x1,
      l.y1,
      l.x2,
      l.y2,
      visual.collisionMask,
      ctx.ballRadius,
    );
    frame = -1;
  }

  final double timerTime, exitX, exitY;
  late final TriggerLine _line;

  @override
  void checkBall(PinballBall ball) {
    if (!_line.crossedBy(ball)) return;
    if (ctx.tilted()) {
      ctx.drainBall(ball);
      return;
    }
    ctx.removeBall(ball);
    sound(visual.sound4);
    emit(MC.controlCollision);
  }

  int? _ejectTimer;

  /// `TSink::Message`: the rules decide where and when the ball comes out.
  @override
  int message(int code, double value) {
    switch (code) {
      case MC.tSinkResetTimer:
        if (_ejectTimer case final t?) ctx.timers.cancel(t);
        _ejectTimer = ctx.timers.set(value < 0 ? timerTime : value, () {
          _ejectTimer = null;
          eject();
        });
      case MC.playerChanged:
      case MC.reset:
        if (_ejectTimer case final t?) ctx.timers.cancel(t);
        _ejectTimer = null;
        messageField = 0;
    }
    return 0;
  }

  void eject() {
    final ball = ctx.addBall(exitX, exitY);
    sound(visual.sound3);
    final v = TablePart.throwVelocity(visual.kicker, ctx.random);
    ball.body.linearVelocity = v;
  }
}

/// `THole`: catches the ball on a raised level, lets it fall and puts it
/// down at rest on another level (attribute 1304), e.g. at the end of a
/// ramp.
class HolePart extends TablePart {
  HolePart(super.ctx, super.component)
    : _circle = component.states.first.walls.first as dat.WallCircle,
      pull = component.attributes[305]!.first,
      captureRadius =
          component.attributes[306]!.first *
          (component.states.first.walls.first as dat.WallCircle).radius,
      dropZ = component.attributes[408]![2],
      targetLayers = component.attributes[1304]!.first.floor() {
    frame = -1;
  }

  final dat.WallCircle _circle;
  final double pull, captureRadius, dropZ;
  final int targetLayers;

  /// 3D Pinball holds the ball 0.5 s before it drops.
  static const holdTime = 0.5;
  static const dropTime = 0.15;

  PinballBall? _held;

  bool _onLayer(PinballBall b) => b.layers & visual.collisionMask != 0;

  @override
  void field(PinballBall ball) {
    if (_held != null || !_onLayer(ball)) return;
    final dx = _circle.x - ball.x, dy = _circle.y - ball.y;
    final d2 = dx * dx + dy * dy;
    if (d2 > _circle.radius * _circle.radius || d2 == 0) return;
    final d = math.sqrt(d2);
    final v = ball.body.linearVelocity;
    ball.fieldAccel
      ..x += dx / d * pull - v.x
      ..y += dy / d * pull - v.y;
  }

  @override
  void checkBall(PinballBall ball) {
    if (_held != null || !_onLayer(ball)) return;
    final dx = _circle.x - ball.x, dy = _circle.y - ball.y;
    if (dx * dx + dy * dy > captureRadius * captureRadius) return;
    _held = ball;
    ball.capture(this, _circle.x, _circle.y);
    sound(visual.hardHitSound);
    emit(MC.controlBallCaptured);
    ctx.timers.set(holdTime, _drop);
  }

  void _drop() {
    final ball = _held;
    if (ball == null) return;
    final from = ball.z;
    const steps = 6;
    for (var i = 1; i <= steps; i++) {
      ctx.timers.set(dropTime * i / steps, () {
        ball.z = from + (dropZ - from) * i / steps;
        if (i == steps) _release(ball);
      });
    }
  }

  void _release(PinballBall ball) {
    _held = null;
    ball
      ..rampPlane = null
      ..layers = targetLayers
      ..release(0, 0, z: dropZ);
    sound(visual.softHitSound);
    emit(MC.controlBallReleased);
  }
}
