import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/ui/screen_layout.dart';

void main() {
  void expectUndistorted(Rect view, Rect source) => expect(
    view.width / source.width,
    closeTo(view.height / source.height, 1e-9),
  );

  test('desktop: the original window, letterboxed and centred', () {
    final l = ScreenLayout.compute(const Size(1600, 900));
    expect(l.mode, LayoutMode.landscape);
    expect(l.scoreboardView, isNull);
    expectUndistorted(l.tableView, l.tableSource);
    expect(l.tableView.height, closeTo(900, 1e-9));
    expect(l.tableView.center.dx, closeTo(800, 1e-9));
  });

  test('phone upright: playfield fills the width at the bottom', () {
    const canvas = Size(390, 763);
    final l = ScreenLayout.compute(canvas);
    expect(l.mode, LayoutMode.portrait);
    expect(l.tableView.width, 390);
    expect(l.tableView.bottom, closeTo(763, 1e-9));
    expectUndistorted(l.tableView, l.tableSource);
  });

  test('phone upright: scoreboard on top, never larger than the table', () {
    final l = ScreenLayout.compute(const Size(390, 763));
    final view = l.scoreboardView!;
    expectUndistorted(view, l.scoreboardSource!);
    expect(view.bottom, lessThanOrEqualTo(l.tableView.top + 1e-9));
    expect(view.top, greaterThanOrEqualTo(0));
    expect(
      view.width / l.scoreboardSource!.width,
      lessThanOrEqualTo(l.tableScale + 1e-9),
    );
  });

  test('a tall screen shows the logo, a shorter one the compact part', () {
    final tall = ScreenLayout.compute(const Size(390, 1000));
    expect(tall.scoreboardSource, ScreenLayout.scoreboardFull);
    final short = ScreenLayout.compute(const Size(390, 640));
    expect(short.scoreboardSource, ScreenLayout.scoreboardCompact);
  });

  test('nearly square portrait falls back to the original layout', () {
    final l = ScreenLayout.compute(const Size(500, 560));
    expect(l.mode, LayoutMode.landscape);
  });

  test('canvas points map back to the original screen', () {
    final l = ScreenLayout.compute(const Size(390, 763));
    final p = l.toScreen(l.tableView.bottomRight - const Offset(1e-6, 1e-6))!;
    expect(p.dx, closeTo(365, 1e-3));
    expect(p.dy, closeTo(416, 1e-3));
    final s = l.toScreen(l.scoreboardView!.center)!;
    expect(ScreenLayout.isScoreboard(s), isTrue);
    expect(ScreenLayout.isScoreboard(l.toScreen(l.tableView.center)!), isFalse);
  });

  test('letterbox bands map to nothing', () {
    final l = ScreenLayout.compute(const Size(1600, 900));
    expect(l.toScreen(const Offset(5, 450)), isNull);
  });
}
