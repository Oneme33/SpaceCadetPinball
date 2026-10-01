import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:forge2d/forge2d.dart' show Vector2;

import '../../dat/pinball_data.dart';
import '../gameplay/game_timers.dart';
import '../physics/ball.dart';
import '../physics/flipper.dart';
import '../physics/physics_world.dart';
import '../physics/plunger.dart';
import '../physics/table_walls.dart';
import 'parts/light_part.dart';
import 'parts/part.dart';
import 'parts/ramp_part.dart';
import 'parts/sensor_parts.dart';
import 'parts/solid_parts.dart';
import 'table_layout.dart';

/// Events from the table itself to the game flow.
enum TableEvent { ballLaunched, ballDrained, flipperUp }

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
    );
    for (final c in layout.components) {
      final part = _createPart(c);
      if (part != null) parts.add(part);
    }
    physics.beforeStep.add(_beforeStep);
    physics.afterStep.add(_afterStep);
  }

  final PhysicsWorld physics;
  final TableLayout layout;
  final math.Random _random;
  late final PartContext _ctx;

  late final Flipper leftFlipper;
  late final Flipper rightFlipper;
  late final Plunger plunger;

  final List<PinballBall> balls = [];
  final List<TablePart> parts = [];

  /// Physics-time timers of the parts.
  final GameTimers timers = GameTimers();

  final Set<PinballBall> _toRemove = {};
  final Map<(TablePart, PinballBall), (double, Vector2)> _hits = {};

  void Function(TableEvent event)? onEvent;
  void Function(PartEvent event)? onPartEvent;
  void Function(int? soundGroup)? playSound;

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
        ..prevY = b.y;
      for (final p in parts) {
        p.field(b);
      }
      b.applyFields();
    }
    if (plunger.beforeStep(dt, balls)) onEvent?.call(TableEvent.ballLaunched);
  }

  void _afterStep(double dt) {
    // One hit per part and ball per step: a ball touching two segments of
    // the same wall must not be kicked twice. Keep the strongest.
    _hits.clear();
    for (final hit in physics.world.contactEvents.hit) {
      final a = hit.shapeA.body.userData, b = hit.shapeB.body.userData;
      final (TablePart, PinballBall, Vector2)? h = switch ((a, b)) {
        (final TablePart p, final PinballBall ball) => (p, ball, hit.normal),
        (final PinballBall ball, final TablePart p) => (p, ball, -hit.normal),
        _ => null,
      };
      if (h == null) continue;
      final key = (h.$1, h.$2);
      final prev = _hits[key];
      if (prev == null || hit.approachSpeed > prev.$1) {
        _hits[key] = (hit.approachSpeed, h.$3);
      }
    }
    for (final MapEntry(key: (part, ball), value: (speed, normal))
        in _hits.entries) {
      part.onHit(ball, speed, normal);
    }
    for (final b in balls) {
      if (b.isCaptured || _toRemove.contains(b)) continue;
      for (final p in parts) {
        p.checkBall(b);
        if (b.isCaptured || _toRemove.contains(b)) break;
      }
    }
    _flushRemovals();
    timers.update(dt);
    _flushRemovals();

    for (var i = balls.length - 1; i >= 0; i--) {
      final b = balls[i];
      if (!b.isCaptured && layout.drain.swallows(b)) {
        b.destroy();
        balls.removeAt(i);
        onEvent?.call(TableEvent.ballDrained);
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
