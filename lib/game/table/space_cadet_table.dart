import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';
import 'package:forge2d/forge2d.dart' show Vector2;

import '../../dat/pinball_data.dart';
import '../gameplay/game_timers.dart';
import '../physics/ball.dart';
import '../physics/flipper.dart';
import '../physics/physics_world.dart';
import '../physics/plunger.dart';
import '../physics/table_walls.dart';
import 'parts/group_parts.dart';
import 'parts/light_part.dart';
import 'parts/part.dart';
import 'parts/ramp_part.dart';
import 'parts/sensor_parts.dart';
import 'parts/table_proxies.dart';
import 'stuck_ball.dart';
import '../physics/original_collision.dart';
import '../rules/message_code.dart';
import 'parts/solid_parts.dart';
import 'table_layout.dart';

/// Events from the table itself to the game flow.
enum TableEvent { ballLaunched, ballDrained, ballFed, flipperUp }

/// The physical table: walls, flippers, plunger, drain, balls and every
/// component from PINBALL.DAT as a [TablePart].
///
/// Knows nothing about score or missions. It turns input into motion and
/// reports what happened through [onEvent] and [onPartEvent].
class SpaceCadetTable {
  SpaceCadetTable(this.physics, this.layout, {math.Random? random})
    : _random = random ?? math.Random() {
    final world = physics.world;
    TableWalls.buildOutline(world, layout.outline);
    leftFlipper = Flipper(world, layout.leftFlipper);
    rightFlipper = Flipper(world, layout.rightFlipper);
    plunger = Plunger(world, layout.plunger, random: _random);
    _ctx = PartContext(
      world: world,
      timers: timers,
      random: _random,
      balls: balls,
      ballRadius: layout.ballRadius,
      gravityMagnitude: 25,
      emit: (e) => onPartEvent?.call(e),
      addBall: addBall,
      removeBall: _toRemove.add,
      playSound: (g) => playSound?.call(g),
      soundDuration: (g) => soundDuration?.call(g) ?? -1,
      partByGroup: (g) => _byGroup[g],
      tilted: () => tilted,
      drainBall: (b) => _toDrain.add(b),
    );
    for (final c in layout.components) {
      final part = _createPart(c);
      if (part != null) parts.add(part);
    }
    Component proxy(ComponentType type, String name) =>
        layout.ofType(type).firstOrNull ??
        Component(type: type, group: -1, name: name, states: const []);
    drainPart =
        DrainPart(
            _ctx,
            proxy(ComponentType.drain, 'drain'),
            timerTime: layout.drain.delay,
          )
          ..ballsInPlay = (() => multiballCount)
          ..setBallsInPlay = ((n) => multiballCount = n);
    plungerPart = PlungerPart(
      _ctx,
      proxy(ComponentType.plunger, 'plunger'),
      feed: () {
        feedBall();
        multiballCount++;
        onEvent?.call(TableEvent.ballFed);
      },
      ballAtFeed: () => balls.any(
        (b) =>
            (b.x - layout.plunger.feedX).abs() < layout.ballRadius * 1.2 &&
            (b.y - layout.plunger.feedY).abs() < layout.ballRadius * 1.2,
      ),
      autoLaunch: () => plunger.autoLaunches++,
      feedSound: playFeedSound,
    );
    leftFlipperPart = FlipperPart(
      _ctx,
      proxy(ComponentType.flipperLeft, 'a_flip1'),
    );
    rightFlipperPart = FlipperPart(
      _ctx,
      proxy(ComponentType.flipperRight, 'a_flip2'),
    );
    parts.addAll([drainPart, plungerPart, leftFlipperPart, rightFlipperPart]);
    physics.beforeStep.add(_beforeStep);
    physics.afterStep.add(_afterStep);
  }

  final PhysicsWorld physics;
  final TableLayout layout;
  final math.Random _random;
  late final PartContext _ctx;

  /// For parts made outside the table (message boxes).
  PartContext get partContext => _ctx;

  late final DrainPart drainPart;
  late final PlungerPart plungerPart;
  late final FlipperPart leftFlipperPart, rightFlipperPart;

  /// Balls in play (`TPinballTable::MultiballCount`).
  int multiballCount = 0;

  /// Sound records of the table itself: game start and game over.
  int? startSound, gameOverSound;

  math.Random get random => _random;

  /// Sound record of the table for a tilt.
  int? tiltSound;

  /// Plays the game start, game over or tilt sound; returns its length.
  double playTableSound({bool start = false, bool tilt = false}) {
    final g = tilt ? tiltSound : (start ? startSound : gameOverSound);
    playSound?.call(g);
    return g == null ? -1 : (soundDuration?.call(g) ?? -1);
  }

  late final Flipper leftFlipper;
  late final Flipper rightFlipper;
  late final Plunger plunger;

  final List<PinballBall> balls = [];
  final List<TablePart> parts = [];

  /// Physics-time timers of the parts.
  final GameTimers timers = GameTimers();

  final Set<PinballBall> _toRemove = {};
  final Set<PinballBall> _toDrain = {};

  /// `TPinballTable::TiltLockFlag`, set by the rules.
  bool tilted = false;

  /// Adds (dx, dy) to the velocity of every ball in play (a table bump).
  void pushBalls(double dx, double dy) {
    for (final b in balls) {
      if (b.isCaptured) continue;
      b.body.linearVelocity = b.body.linearVelocity + Vector2(dx, dy);
    }
  }

  /// `tilt_timeout`: every ball goes down the drain.
  void drainAll() => _toDrain.addAll(balls);

  double _time = 0;
  double _nextStuckCheck = 0;

  late final StuckBallGuard stuck = StuckBallGuard(
    random: _random,
    restAreas: [
      for (final f in [layout.leftFlipper, layout.rightFlipper])
        Rect.fromPoints(
          Offset(f.originX, f.originY),
          Offset(f.restTipX, f.extendedTipY),
          // Room for the longer flippers of easy mode.
        ).inflate(f.baseRadius + 0.5),
      Rect.fromLTRB(
        layout.plunger.x1,
        layout.plunger.feedY - layout.ballRadius,
        layout.plunger.x2,
        layout.plunger.y1,
      ),
    ],
    relaunch: (b) {
      _toRemove.add(b);
      if (multiballCount > 0) multiballCount--;
      plungerPart.message(MC.plungerRelaunchBall, 0);
    },
  );
  final Map<(TablePart, PinballBall), (double, Vector2)> _hits = {};
  final Map<PinballBall, (double, Object?, Vector2)> _rebounds = {};

  void Function(TableEvent event)? onEvent;
  void Function(PartEvent event)? onPartEvent;
  void Function(int? soundGroup)? playSound;

  /// A ball hit a flipper, with the approach speed (for haptics).
  void Function(double speed)? onFlipperHit;
  double Function(int? soundGroup)? soundDuration;

  VisualState? _visualOf(ComponentType type) {
    for (final c in layout.components) {
      if (c.type == type && c.states.isNotEmpty) return c.states.first;
    }
    return null;
  }

  late final VisualState? _leftFlipperVisual = _visualOf(
    ComponentType.flipperLeft,
  );
  late final VisualState? _rightFlipperVisual = _visualOf(
    ComponentType.flipperRight,
  );
  late final VisualState? _plungerVisual = _visualOf(ComponentType.plunger);

  /// `PlungerStartFeedTimer`'s sound, played when a ball is on its way.
  void playFeedSound() => playSound?.call(_plungerVisual?.sound4);

  void pressPlunger() {
    if (!plunger.pulling) playSound?.call(_plungerVisual?.hardHitSound);
    plunger.press();
  }

  void releasePlunger() {
    if (plunger.pulling) playSound?.call(_plungerVisual?.sound3);
    plunger.release();
  }

  late final Map<String, TablePart> _byName = {
    for (final p in parts) p.name: p,
  };

  /// Parts with a field effect, and parts that watch the ball (sensors,
  /// trigger lines): the only ones visited every physics step.
  late final List<TablePart> _fieldParts = [
    for (final p in parts)
      if (p is KickoutPart || p is HolePart || p is RampPart) p,
  ];
  late final List<TablePart> _sensorParts = [
    for (final p in parts)
      if (p is RolloverPart ||
          p is TripwirePart ||
          p is SpinnerPart ||
          p is OnewayPart ||
          p is KickoutPart ||
          p is SinkPart ||
          p is HolePart ||
          p is RampPart)
        p,
  ];

  late final Map<int, TablePart> _byGroup = {
    for (final p in parts) p.component.group: p,
  };

  TablePart? part(String name) => _byName[name];

  LightPart? light(String name) => _byName[name] as LightPart?;

  TablePart? _createPart(Component c) {
    final walls = c.states.isEmpty ? const <WallShape>[] : c.states.first.walls;
    bool has<T>() => walls.whereType<T>().isNotEmpty;
    try {
      return switch (c.type) {
        ComponentType.wall || ComponentType.wall2 => WallPart(_ctx, c),
        ComponentType.bumper => BumperPart(_ctx, c),
        ComponentType.popupTarget => PopupTargetPart(_ctx, c),
        ComponentType.soloTarget => SoloTargetPart(_ctx, c),
        ComponentType.gate => GatePart(_ctx, c),
        ComponentType.blocker => BlockerPart(_ctx, c),
        ComponentType.kickback when has<WallLine>() => KickbackPart(_ctx, c),
        ComponentType.oneway when has<WallLine>() => OnewayPart(_ctx, c),
        ComponentType.rollover when has<WallPolygon>() => RolloverPart(
          _ctx,
          c,
          isLight: false,
        ),
        ComponentType.lightRollover when has<WallPolygon>() => RolloverPart(
          _ctx,
          c,
          isLight: true,
        ),
        ComponentType.tripwire when has<WallLine>() => TripwirePart(_ctx, c),
        ComponentType.flagSpinner when has<WallLine>() => SpinnerPart(_ctx, c),
        ComponentType.kickout when has<WallCircle>() => KickoutPart(
          _ctx,
          c,
          lit: true,
        ),
        ComponentType.kickoutNoLight when has<WallCircle>() => KickoutPart(
          _ctx,
          c,
          lit: false,
        ),
        ComponentType.sink when has<WallLine>() => SinkPart(_ctx, c),
        ComponentType.hole when has<WallCircle>() => HolePart(_ctx, c),
        ComponentType.ramp => RampPart(_ctx, c),
        ComponentType.light => LightPart(_ctx, c),
        ComponentType.lightGroup => LightGroupPart(_ctx, c),
        ComponentType.lightBargraph => LightBargraphPart(_ctx, c),
        ComponentType.componentGroup => ComponentGroupPart(_ctx, c),
        ComponentType.sound => SoundPart(_ctx, c),
        _ => null,
      };
    } on Object catch (e) {
      debugPrint('Skipping ${c.type.name} ${c.name}: $e');
      return null;
    }
  }

  void setFlipper({required bool left, required bool pressed}) {
    final f = left ? leftFlipper : rightFlipper;
    final visual = left ? _leftFlipperVisual : _rightFlipperVisual;
    if (pressed && !f.pressed) {
      playSound?.call(visual?.sound4);
      onEvent?.call(TableEvent.flipperUp);
      (left ? leftFlipperPart : rightFlipperPart).extended();
    } else if (!pressed && f.pressed) {
      playSound?.call(visual?.sound3);
    }
    f.pressed = pressed;
  }

  /// Puts a new ball in the plunger lane (`PlungerFeedBall`).
  PinballBall feedBall() => addBall(layout.plunger.feedX, layout.plunger.feedY);

  PinballBall addBall(double x, double y) {
    final ball = PinballBall(
      physics.world,
      x: x,
      y: y,
      radius: layout.ballRadius,
      gravityMult: layout.gravityMult,
      random: _random,
    );
    balls.add(ball);
    return ball;
  }

  void removeAllBalls() {
    for (final b in balls) {
      b.destroy();
    }
    balls.clear();
    _toRemove.clear();
    multiballCount = 0;
  }

  /// New game: every part back to its start state, pending timers gone.
  void reset() {
    timers.clear();
    for (final p in parts) {
      p.reset();
    }
  }

  /// Flippers drop and the plunger lets go, e.g. on pause or game over.
  void releaseControls() {
    leftFlipper.pressed = false;
    rightFlipper.pressed = false;
    plunger.release();
  }

  void _beforeStep(double dt) {
    leftFlipper.beforeStep(dt);
    rightFlipper.beforeStep(dt);
    for (final b in balls) {
      if (b.isCaptured) continue;
      b
        ..prevX = b.x
        ..prevY = b.y
        ..preVelocity.setFrom(b.body.linearVelocity);
      for (final p in _fieldParts) {
        p.field(b);
      }
      b.applyFields();
    }
    if (plunger.beforeStep(dt, balls)) onEvent?.call(TableEvent.ballLaunched);
  }

  void _afterStep(double dt) {
    // One hit per part and ball per step: a ball touching two segments of
    // the same wall must not be kicked twice. Keep the strongest. The
    // strongest hit of all sets the ball's rebound, the original's way.
    _hits.clear();
    _rebounds.clear();
    for (final hit in physics.world.contactEvents.hit) {
      final a = hit.shapeA.body.userData, b = hit.shapeB.body.userData;
      if (a is PinballBall && b is PinballBall) {
        final (va, vb) = OriginalCollision.balls(
          a.preVelocity,
          b.preVelocity,
          hit.normal,
        );
        a.body.linearVelocity = va;
        b.body.linearVelocity = vb;
        continue;
      }
      // The normal points from the wall to the ball.
      final (Object?, PinballBall, Vector2)? h = switch ((a, b)) {
        (_, final PinballBall ball) => (a, ball, hit.normal),
        (final PinballBall ball, _) => (b, ball, -hit.normal),
        _ => null,
      };
      if (h == null) continue;
      final (other, ball, normal) = h;
      final rebound = _rebounds[ball];
      if (rebound == null || hit.approachSpeed > rebound.$1) {
        _rebounds[ball] = (hit.approachSpeed, other, normal);
      }
      if (other is Flipper) {
        onFlipperHit?.call(hit.approachSpeed);
        continue;
      }
      if (other is! TablePart) continue;
      final key = (other, ball);
      final prev = _hits[key];
      if (prev == null || hit.approachSpeed > prev.$1) {
        _hits[key] = (hit.approachSpeed, normal);
      }
    }
    for (final MapEntry(key: ball, value: (_, other, normal))
        in _rebounds.entries) {
      if (ball.isCaptured) continue;
      final pre = ball.preVelocity;
      ball.body.linearVelocity = switch (other) {
        final Flipper f => OriginalCollision.flipper(
          f,
          pre,
          normal,
          ball.body.position,
          ball.radius,
        ),
        _ => () {
          final m = switch (other) {
            final TablePart p => p.visual.material,
            'plunger' => OriginalCollision.plungerMaterial,
            _ => OriginalCollision.tableMaterial,
          };
          return OriginalCollision.rebound(
            pre,
            normal,
            m.elasticity,
            m.smoothness,
          );
        }(),
      };
    }
    for (final MapEntry(key: (part, ball), value: (speed, normal))
        in _hits.entries) {
      part.onHit(ball, speed, normal);
    }
    for (final b in balls) {
      if (b.isCaptured || _toRemove.contains(b)) continue;
      for (final p in _sensorParts) {
        p.checkBall(b);
        if (b.isCaptured || _toRemove.contains(b)) break;
      }
    }
    _flushRemovals();
    timers.update(dt);
    _flushRemovals();
    for (final b in _toDrain) {
      if (!balls.remove(b)) continue;
      if (b.isCaptured) b.capturedBy = null;
      b.destroy();
      onEvent?.call(TableEvent.ballDrained);
      drainPart.ballDrained();
    }
    _toDrain.clear();

    _time += dt;
    if (_time >= _nextStuckCheck) {
      _nextStuckCheck = _time + 1 / 60;
      stuck.check(balls, _time);
      _flushRemovals();
    }

    for (var i = balls.length - 1; i >= 0; i--) {
      final b = balls[i];
      if (!b.isCaptured && layout.drain.swallows(b)) {
        b.destroy();
        balls.removeAt(i);
        onEvent?.call(TableEvent.ballDrained);
        drainPart.ballDrained();
      }
    }
  }

  void _flushRemovals() {
    if (_toRemove.isEmpty) return;
    for (final b in _toRemove) {
      balls.remove(b);
      b.destroy();
    }
    _toRemove.clear();
  }
}
