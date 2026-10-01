import 'package:forge2d/forge2d.dart';

import '../game_config.dart';
import 'fixed_step.dart';

/// Owns the Box2D world and advances it at a fixed rate.
///
/// The world lives in table space (table units = metres). Rendering never
/// reads Box2D directly from widgets: components read body positions after
/// the step and project them to screen space.
class PhysicsWorld {
  /// [gravity] is in table space (+y towards the drain). [maxSpeed] caps
  /// every body's linear speed, like the original's `BallMaxSpeed`.
  PhysicsWorld({required (double, double) gravity, double maxSpeed = 400})
    : world = World(
        gravity: Vector2(gravity.$1, gravity.$2),
        definition: WorldDef(
          enableContinuous: true,
          maximumLinearSpeed: maxSpeed,
        ),
      ) {
    _stepper = FixedStepper(
      step: GameConfig.physicsStep,
      maxStepsPerFrame: GameConfig.maxStepsPerFrame,
      onStep: _step,
    );
  }

  /// Must run once before the first [PhysicsWorld] is created. Loads the
  /// WebAssembly build of Box2D on the web; a no-op on native.
  static Future<void> initialize() => initializeForge2D();

  final World world;
  late final FixedStepper _stepper;

  /// Called before every physics step: flipper motion, plunger, forces.
  final List<void Function(double dt)> beforeStep = [];

  /// Called after every physics step: sensors, drain, events.
  final List<void Function(double dt)> afterStep = [];

  int get totalSteps => _stepper.totalSteps;

  void _step(double dt) {
    for (final f in beforeStep) {
      f(dt);
    }
    world.step(dt, subStepCount: GameConfig.physicsSubSteps);
    for (final f in afterStep) {
      f(dt);
    }
  }

  /// Advances by one rendered frame of [dt] seconds. Returns steps taken.
  int advance(double dt) => _stepper.advance(dt);

  /// Call when the simulation resumes after a pause, so the paused time is
  /// not simulated all at once.
  void resetClock() => _stepper.reset();

  void destroy() => world.destroy();
}
