import 'dart:math' as math;

import 'package:forge2d/forge2d.dart';

import '../../../dat/pinball_data.dart' as dat;
import '../../physics/ball.dart';
import '../../physics/collision.dart';
import '../../physics/table_walls.dart';
import '../../rules/message_code.dart';
import 'part.dart';

/// A part with solid walls on its own static body, so it can be switched
/// off as a whole (`ActiveFlag`).
abstract class SolidPart extends TablePart {
  SolidPart(super.ctx, super.component, {bool active = true})
    : body = ctx.world.createBody(BodyDef()) {
    body.userData = this;
    TableWalls.addShapes(
      body,
      visual.walls,
      material: Collision.material(visual.material),
      filter: Collision.wall(visual.collisionMask),
    );
    this.active = active;
  }

  final Body body;
  bool _active = true;

  bool get active => _active;
  set active(bool value) {
    _active = value;
    body.isEnabled = value;
  }

  dat.Kicker get kicker => visual.kicker;

  /// `DefaultCollision`: kick when hit hard enough, with the hard hit
  /// sound; a softer hit above 0.2 plays the soft hit sound.
  bool defaultCollision(PinballBall ball, double speed, Vector2 normal) {
    // Tilted: a plain rebound, no kick, no sound.
    if (ctx.tilted()) return false;
    final kicked = TablePart.kick(
      ball,
      speed,
      normal,
      kicker.threshold,
      kicker.boost,
    );
    if (kicked) {
      sound(visual.hardHitSound);
    } else if (speed > 0.2) {
      sound(visual.softHitSound);
    }
    return kicked;
  }
}

/// `TWall`: plain walls, and the slingshots (`v_rebo`), which have a kicker
/// and flash their sprite for 0.1 s on a kick.
class WallPart extends SolidPart {
  WallPart(super.ctx, super.component) {
    frame = -1;
  }

  @override
  void onHit(PinballBall ball, double approachSpeed, Vector2 normal) {
    if (!defaultCollision(ball, approachSpeed, normal)) return;
    if (visual.bitmap != null) {
      frame = 0;
      ctx.timers.set(0.1, () => frame = -1);
    }
    emit(MC.controlCollision);
  }
}

/// `TBumper`: kicks, lights up for its timer (attribute 407) and ignores
/// further hits while lit. Its level ([bmpIndex], sprite pair) is set by
/// the rules.
class BumperPart extends SolidPart {
  BumperPart(super.ctx, super.component)
    : timerTime = _attr(component, 407, 0.25);

  final double timerTime;
  int bmpIndex = 0;
  bool _lit = false;

  @override
  void onHit(PinballBall ball, double approachSpeed, Vector2 normal) {
    if (_lit) {
      // Threshold is out of reach while lit (TBumper::Fire).
      if (approachSpeed > 0.2) sound(visual.softHitSound);
      return;
    }
    if (!defaultCollision(ball, approachSpeed, normal)) return;
    _fire();
    emit(MC.controlCollision);
  }

  /// `TBumperSetBmpIndex`: 0 … (frames − 1) / 2.
  void setLevel(int level) {
    final max = (component.states.length - 1) ~/ 2;
    bmpIndex = level.clamp(0, max);
    frame = 2 * bmpIndex + (_lit ? 1 : 0);
  }

  @override
  int message(int code, double value) {
    switch (code) {
      case MC.tBumperSetBmpIndex:
        final max = (component.states.length - 1) ~/ 2;
        final next = value.floor().clamp(0, max);
        if (next != bmpIndex) {
          sound(next > bmpIndex ? visual.sound4 : visual.sound3);
          bmpIndex = next;
          _fire();
          emit(MC.tBumperSetBmpIndex);
        }
      case MC.tBumperIncBmpIndex:
        message(MC.tBumperSetBmpIndex, (bmpIndex + 1).toDouble());
      case MC.tBumperDecBmpIndex:
        message(MC.tBumperSetBmpIndex, (bmpIndex - 1).toDouble());
      case MC.reset:
        messageField = 0;
        reset();
    }
    return 0;
  }

  /// `TBumper::Fire`: lit for its timer, hits ignored meanwhile.
  void _fire() {
    _lit = true;
    frame = 2 * bmpIndex + 1;
    ctx.timers.set(timerTime, () {
      _lit = false;
      frame = 2 * bmpIndex;
    });
  }

  @override
  void reset() {
    _lit = false;
    setLevel(0);
  }
}

/// `TPopupTarget`: a drop target. A hard enough hit drops it (no
/// collision, no sprite) until the rules raise it again, which takes its
/// timer (attribute 407).
class PopupTargetPart extends SolidPart {
  PopupTargetPart(super.ctx, super.component)
    : timerTime = _attr(component, 407, 0.25);

  final double timerTime;
  int? _raiseTimer;

  bool get isDown => !active;

  @override
  void onHit(PinballBall ball, double approachSpeed, Vector2 normal) {
    // basic_collision(...) > Threshold: strictly above.
    if (ctx.tilted() || approachSpeed <= kicker.threshold) return;
    TablePart.kick(ball, approachSpeed, normal, kicker.threshold, kicker.boost);
    sound(visual.hardHitSound);
    drop();
    emit(MC.controlCollision);
  }

  void drop() {
    active = false;
    frame = -1;
  }

  /// `TPopupTargetEnable`.
  void raise() {
    _raiseTimer = ctx.timers.set(timerTime, () {
      _up();
      sound(visual.softHitSound);
    });
  }

  void _up() {
    _raiseTimer = null;
    active = true;
    frame = 0;
  }

  @override
  void reset() {
    if (_raiseTimer case final t?) ctx.timers.cancel(t);
    _up();
  }

  @override
  int message(int code, double value) {
    switch (code) {
      case MC.tPopupTargetDisable:
        drop();
      case MC.tPopupTargetEnable:
        raise();
      case MC.reset:
        messageField = 0;
        reset();
    }
    return 0;
  }
}

/// `TSoloTarget`: kicks, goes down for 0.1 s, comes back by itself.
class SoloTargetPart extends SolidPart {
  SoloTargetPart(super.ctx, super.component);

  @override
  void onHit(PinballBall ball, double approachSpeed, Vector2 normal) {
    if (!active || !defaultCollision(ball, approachSpeed, normal)) return;
    _set(false);
    ctx.timers.set(0.1, () => _set(true));
    emit(MC.controlCollision);
  }

  void _set(bool on) {
    active = on;
    frame = on ? 0 : 1;
  }

  @override
  void reset() => _set(true);

  @override
  int message(int code, double value) {
    switch (code) {
      case MC.tSoloTargetDisable:
        _set(false);
      case MC.tSoloTargetEnable:
        _set(true);
      case MC.reset:
        messageField = 0;
        reset();
    }
    return 0;
  }
}

/// `TGate`: closed (solid, sprite shown) until the rules open it.
class GatePart extends SolidPart {
  GatePart(super.ctx, super.component);

  void open() {
    active = false;
    frame = -1;
    sound(visual.sound3);
  }

  void close() {
    _close();
    sound(visual.sound4);
  }

  void _close() {
    active = true;
    frame = 0;
  }

  @override
  void reset() => _close();

  /// `TGate::Message`: every message is also reported to the rules.
  @override
  int message(int code, double value) {
    switch (code) {
      case MC.tGateDisable:
        open();
      case MC.tGateEnable:
        close();
      case MC.reset:
        messageField = 0;
        _close();
    }
    emit(code);
    return 0;
  }
}

/// `TBlocker`: the centre post between the flippers. Off until the rules
/// raise it (ball save), for a duration.
class BlockerPart extends SolidPart {
  BlockerPart(super.ctx, super.component) : super(active: false) {
    frame = -1;
  }

  /// `TBlocker`: up for 55 s, then 5 s more while flashing.
  final double initialDuration = 55;
  final double extendedDuration = 5;

  int? _timer;

  void raise({double? seconds}) {
    active = true;
    frame = 0;
    sound(visual.sound4);
    _cancel();
    if (seconds != null) {
      _timer = ctx.timers.set(seconds, () {
        _timer = null;
        emit(MC.controlTimerExpired);
      });
    }
  }

  void lower() {
    if (active) sound(visual.sound3);
    _lower();
  }

  void _lower() {
    _cancel();
    active = false;
    frame = -1;
  }

  void _cancel() {
    if (_timer case final t?) ctx.timers.cancel(t);
    _timer = null;
  }

  @override
  void reset() => _lower();

  @override
  int message(int code, double value) {
    switch (code) {
      case MC.tBlockerEnable:
        raise(seconds: value >= 0 ? value : null);
      case MC.tBlockerDisable:
        lower();
      case MC.tBlockerRestartTimeout:
        _cancel();
        _timer = ctx.timers.set(value < 0 ? 0 : value, () {
          _timer = null;
          emit(MC.controlTimerExpired);
        });
      case MC.setTiltLock:
      case MC.playerChanged:
      case MC.reset:
        messageField = 0;
        _lower();
    }
    return 0;
  }
}

/// `TKickback`: a floor at the bottom of an outlane. A ball that lands on
/// it is shot back up after 0.7 s with the kicker's boost; the cycle ends
/// 0.1 s later. Whether a ball can get there is up to the gates above it.
class KickbackPart extends SolidPart {
  KickbackPart(super.ctx, super.component) {
    final line = visual.walls.whereType<dat.WallLine>().first;
    _line = line;
    final dx = line.x2 - line.x1, dy = line.y2 - line.y1;
    final len = math.sqrt(dx * dx + dy * dy);
    _normal = Vector2(dy / len, -dx / len);
  }

  static const timerTime = 0.7;
  static const timerTime2 = 0.1;

  late final dat.WallLine _line;
  late final Vector2 _normal;
  bool _armed = false;

  @override
  void onHit(PinballBall ball, double approachSpeed, Vector2 normal) {
    if (_armed) return;
    _armed = true;
    ctx.timers.set(timerTime, _fire);
  }

  void _fire() {
    var kicked = false;
    for (final b in ctx.balls) {
      if (!b.isCaptured && _touches(b)) {
        b.body.linearVelocity = b.body.linearVelocity + _normal * kicker.boost;
        kicked = true;
      }
    }
    if (kicked) {
      frame = 1;
      sound(visual.hardHitSound);
    }
    ctx.timers.set(timerTime2, () {
      frame = 0;
      _armed = false;
      emit(MC.controlTimerExpired);
    });
  }

  bool _touches(PinballBall b) {
    final l = _line;
    final ax = l.x2 - l.x1, ay = l.y2 - l.y1;
    final t = (((b.x - l.x1) * ax + (b.y - l.y1) * ay) / (ax * ax + ay * ay))
        .clamp(0.0, 1.0);
    final dx = b.x - (l.x1 + ax * t), dy = b.y - (l.y1 + ay * t);
    return math.sqrt(dx * dx + dy * dy) <= b.radius + 0.1;
  }

  @override
  void reset() {
    _armed = false;
    frame = 0;
  }
}

/// `TOneway`: solid from one side; passing through from the other side is
/// reported to the rules.
class OnewayPart extends SolidPart {
  OnewayPart(super.ctx, super.component) {
    final l = visual.walls.whereType<dat.WallLine>().first;
    // The pass-through line runs the other way, so it fires from the open
    // side.
    _pass = TriggerLine.offset(
      l.x2,
      l.y2,
      l.x1,
      l.y1,
      visual.collisionMask,
      -ctx.ballRadius * 0.8,
    );
    frame = -1;
  }

  late final TriggerLine _pass;

  @override
  void checkBall(PinballBall ball) {
    if (_pass.crossedBy(ball)) {
      sound(visual.hardHitSound);
      emit(MC.controlCollision);
    }
  }

  @override
  void onHit(PinballBall ball, double approachSpeed, Vector2 normal) {
    defaultCollision(ball, approachSpeed, normal);
  }
}

double _attr(dat.Component c, int code, double fallback) =>
    c.attributes[code]?.first ?? fallback;
