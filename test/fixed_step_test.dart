import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/physics/fixed_step.dart';

void main() {
  FixedStepper stepper(List<double> log, {int max = 100}) =>
      FixedStepper(step: 1 / 240, maxStepsPerFrame: max, onStep: log.add);

  test('step count does not depend on frame rate', () {
    for (final fps in [30, 60, 144, 240]) {
      final log = <double>[];
      final s = stepper(log);
      for (var i = 0; i < fps; i++) {
        s.advance(1 / fps);
      }
      // One second of frames → 240 steps, give or take float rounding.
      expect(log.length, inInclusiveRange(239, 240), reason: '$fps fps');
      expect(log.every((dt) => dt == 1 / 240), isTrue);
    }
  });

  test('leftover time carries over to the next frame', () {
    final log = <double>[];
    final s = stepper(log);
    expect(s.advance(1.5 / 240), 1);
    expect(s.alpha, closeTo(0.5, 1e-9));
    expect(s.advance(0.5 / 240), 1);
    expect(log, hasLength(2));
  });

  test('a long frame is capped instead of spiralling', () {
    final log = <double>[];
    final s = stepper(log, max: 16);
    expect(s.advance(5), 16);
    // The backlog is dropped, so the next normal frame is normal again.
    expect(s.advance(1 / 60), 4);
  });

  test('zero or negative frame time does nothing', () {
    final log = <double>[];
    final s = stepper(log);
    expect(s.advance(0), 0);
    expect(s.advance(-1), 0);
    expect(log, isEmpty);
  });
}
