import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/ui/cadet_flights.dart';

void main() {
  const size = Size(300, 190), aspect = 95 / 138;
  final view = Offset.zero & size;

  Rect box(CadetPose p) => Rect.fromCenter(
    center: p.center,
    width: p.width,
    height: p.width * aspect,
  );

  test('every pass comes in from out of view and leaves out of view', () {
    final r = math.Random(3);
    for (var i = 0; i < 500; i++) {
      final f = CadetFlight.random(r, 0);
      final first = f.poseAt(0, size, aspect)!;
      final last = f.poseAt(f.duration, size, aspect)!;
      // The wobble moves the car a little; the margin covers it.
      expect(box(first).deflate(6).overlaps(view), isFalse, reason: '#$i in');
      expect(box(last).deflate(6).overlaps(view), isFalse, reason: '#$i out');
      expect(first.facing, f.right ? -1 : 1);
    }
  });

  test('the car never flies backwards, so it never turns in sight', () {
    final r = math.Random(4);
    for (var i = 0; i < 500; i++) {
      final f = CadetFlight.random(r, 0);
      var x = f.poseAt(0, size, aspect)!.center.dx;
      for (var k = 1; k < 50; k++) {
        final p = f.poseAt(f.duration * k / 50, size, aspect)!;
        if (f.right) {
          expect(p.center.dx, greaterThanOrEqualTo(x), reason: '#$i');
        } else {
          expect(p.center.dx, lessThanOrEqualTo(x), reason: '#$i');
        }
        x = p.center.dx;
      }
    }
  });

  test('passes vary and follow each other with short pauses', () {
    final flights = CadetFlights(math.Random(5));
    var visible = 0, rights = 0, lefts = 0, gaps = 0;
    var wasVisible = false;
    for (var t = 0.0; t < 120; t += 0.05) {
      final p = flights.poseAt(t, size, aspect);
      final on = p != null && box(p).overlaps(view);
      if (on) visible++;
      if (on && !wasVisible) p.facing < 0 ? rights++ : lefts++;
      if (!on && wasVisible) gaps++;
      wasVisible = on;
    }
    expect(rights, greaterThan(3));
    expect(lefts, greaterThan(3));
    expect(gaps, greaterThan(10));
    expect(visible / (120 / 0.05), greaterThan(0.5), reason: 'mostly in view');
  });
}
