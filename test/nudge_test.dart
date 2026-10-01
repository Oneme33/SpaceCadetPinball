import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/gameplay/nudge.dart';

void main() {
  late List<(double, double)> pushes;
  late int sx, sy;
  late Nudge n;

  setUp(() {
    pushes = [];
    sx = sy = 0;
    n = Nudge(
      push: (dx, dy) => pushes.add((dx, dy)),
      shift: (x, y) {
        sx += x;
        sy += y;
      },
    );
  });

  test('a bump pushes the ball and is undone after 0.4 s', () {
    n.bumpLeft();
    expect(pushes.single, (1.0, 0.5));
    expect((sx, sy), (2, -1));
    n.update(0.41);
    expect(pushes.last, (-1.0, -0.5));
    expect((sx, sy), (0, 0));
  });

  test('holding bumps raises the counter; it falls off when idle', () {
    n.bumpRight();
    n.update(0.2);
    expect(n.count, closeTo(0.8, 1e-9));
    n.update(0.2);
    expect(n.active, isFalse);
    final peak = n.count;
    expect(peak, closeTo(1.6, 1e-9));
    n.update(0.5);
    expect(n.count, closeTo(peak - 0.5, 1e-9));
  });

  test('two quick bumps reach the tilt level', () {
    for (var i = 0; i < 2; i++) {
      n.bumpBottom();
      for (var t = 0.0; t < 0.15; t += 0.01) {
        n.update(0.01);
      }
    }
    expect(n.count, greaterThan(Nudge.tiltLevel));
  });

  test('a fresh ball gets leeway', () {
    n
      ..bumpLeft()
      ..reset();
    expect(n.count, -2);
    expect((sx, sy), (0, 0));
  });
}
