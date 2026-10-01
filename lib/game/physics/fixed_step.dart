/// Runs a simulation at a fixed time step, independent of the frame rate.
///
/// Frame time is accumulated and consumed in whole [step]s. When a frame is
/// very long (tab in background, debugger pause), at most [maxStepsPerFrame]
/// steps run and the rest is dropped, so the game slows down instead of
/// spiralling into ever-longer frames.
class FixedStepper {
  FixedStepper({
    required this.step,
    required this.maxStepsPerFrame,
    required this.onStep,
  });

  final double step;
  final int maxStepsPerFrame;
  final void Function(double dt) onStep;

  double _accumulator = 0;

  /// Total steps taken since creation. Useful for debug output and tests.
  int totalSteps = 0;

  /// Fraction of a step left in the accumulator, 0..1. Rendering can use it
  /// to interpolate between the last two physics states.
  double get alpha => _accumulator / step;

  /// Advances by [frameDt] seconds of real time. Returns the number of
  /// simulation steps taken.
  int advance(double frameDt) {
    if (frameDt <= 0) return 0;
    _accumulator += frameDt;
    var steps = 0;
    while (_accumulator >= step && steps < maxStepsPerFrame) {
      onStep(step);
      _accumulator -= step;
      steps++;
    }
    if (steps == maxStepsPerFrame && _accumulator >= step) {
      _accumulator = 0;
    }
    totalSteps += steps;
    return steps;
  }

  void reset() => _accumulator = 0;
}
