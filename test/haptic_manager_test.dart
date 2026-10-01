import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/feedback/haptic_manager.dart';

void main() {
  late double now;
  late List<Haptic> out;
  late bool enabled;
  late HapticManager h;

  setUp(() {
    now = 0;
    out = [];
    enabled = true;
    h = HapticManager(
      enabled: () => enabled,
      clock: () => now,
      output: out.add,
    );
  });

  test('plays each strength', () {
    h.play(Haptic.light);
    now = 1;
    h.play(Haptic.medium);
    now = 2;
    h.play(Haptic.heavy);
    expect(out, [Haptic.light, Haptic.medium, Haptic.heavy]);
  });

  test('never buzzes continuously', () {
    for (var i = 0; i < 100; i++) {
      h.play(Haptic.medium);
      now += 0.01;
    }
    // One second of hits every 10 ms: at most one pulse per 60 ms.
    expect(out.length, lessThanOrEqualTo(17));
  });

  test('a strong pulse masks weaker ones for a moment', () {
    h.play(Haptic.heavy);
    now = 0.05;
    h.play(Haptic.light);
    expect(out, [Haptic.heavy]);
  });

  test('off means off', () {
    enabled = false;
    h.play(Haptic.heavy);
    expect(out, isEmpty);
  });
}
