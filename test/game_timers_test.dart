import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/gameplay/game_timers.dart';

void main() {
  test('fires once after its time has passed', () {
    final t = GameTimers();
    var fired = 0;
    t.set(1, () => fired++);
    t.update(0.6);
    expect(fired, 0);
    t.update(0.6);
    expect(fired, 1);
    t.update(5);
    expect(fired, 1);
    expect(t.pending, 0);
  });

  test('time only passes when updated, so pausing pauses timers', () {
    final t = GameTimers();
    var fired = false;
    t.set(0.5, () => fired = true);
    // A paused game simply does not call update.
    expect(fired, isFalse);
    t.update(0.5);
    expect(fired, isTrue);
  });

  test('cancel and clear', () {
    final t = GameTimers();
    var a = false, b = false;
    final id = t.set(1, () => a = true);
    t.set(1, () => b = true);
    t.cancel(id);
    t.update(1);
    expect(a, isFalse);
    expect(b, isTrue);
    t.set(1, () => a = true);
    t.clear();
    t.update(1);
    expect(a, isFalse);
  });

  test('a callback can schedule a new timer', () {
    final t = GameTimers();
    var second = false;
    t.set(1, () => t.set(1, () => second = true));
    t.update(1);
    expect(second, isFalse);
    t.update(1);
    expect(second, isTrue);
  });
}
