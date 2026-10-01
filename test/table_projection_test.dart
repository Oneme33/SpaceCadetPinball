import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/table/table_projection.dart';

void main() {
  const p = LinearProjection(
    table: Rect.fromLTRB(-8, -14, 8, 15),
    screen: Rect.fromLTWH(100, 0, 160, 290),
  );

  test('oriented like the original camera: +x left, +y down', () {
    expect(p.toScreen(8, -14), const Offset(100, 0));
    expect(p.toScreen(-8, 15), const Offset(260, 290));
  });

  test('toTable inverts toScreen', () {
    for (final (x, y) in [(0.0, 0.0), (-7.5, 14.0), (3.25, -11.0)]) {
      final (bx, by) = p.toTable(p.toScreen(x, y));
      expect(bx, closeTo(x, 1e-9));
      expect(by, closeTo(y, 1e-9));
    }
  });
}
