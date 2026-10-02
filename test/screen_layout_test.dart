import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/game_config.dart';
import 'package:space_cadet/game/ui/screen_layout.dart';

void main() {
  void expectUndistorted(Rect view, Rect source) => expect(
    view.width / source.width,
    closeTo(view.height / source.height, 1e-9),
  );

  const phone = Size(392, 850);
  const play = GameConfig.playfieldRect;

  test('desktop: the original window, letterboxed and centred', () {
    final l = ScreenLayout.compute(const Size(1600, 900));
    expect(l.mode, LayoutMode.landscape);
    expectUndistorted(l.tableView, l.tableSource);
    expect(l.tableView.height, closeTo(900, 1e-9));
    expect(l.tableView.center.dx, closeTo(800, 1e-9));
  });

  test('phone upright: the playfield fills the screen under the bar', () {
    final l = ScreenLayout.compute(phone);
    expect(l.mode, LayoutMode.phone);
    expect(l.tableView, Rect.fromLTRB(0, ScreenLayout.hudHeight, 392, 850));
    expectUndistorted(l.tableView, l.tableSource);
    expect(l.tableSource.height, play.height, reason: 'full height');
    expect(l.tableSource.width, lessThan(play.width));
    expect(l.panRange, closeTo(play.width - l.tableSource.width, 1e-9));
  });

  test('pan moves the view from the left edge to the plunger lane', () {
    final left = ScreenLayout.compute(phone, pan: 0);
    final right = ScreenLayout.compute(phone, pan: 1);
    expect(left.tableSource.left, closeTo(play.left, 1e-9));
    expect(right.tableSource.right, closeTo(play.right, 1e-9));
  });

  test('the view only moves when the ball leaves its middle part', () {
    final l = ScreenLayout.compute(phone);
    final mid = l.tableSource.center.dx;
    expect(l.panToShow(mid, 0.5), 0.5);
    expect(l.panToShow(play.right - 2, 0.5), greaterThan(0.5));
    expect(l.panToShow(play.left + 2, 0.5), lessThan(0.5));
    expect(l.panToShow(play.right + 100, 0.5), 1.0, reason: 'clamped');
  });

  test('nearly square portrait falls back to the original layout', () {
    final l = ScreenLayout.compute(const Size(500, 560));
    expect(l.mode, LayoutMode.landscape);
  });

  test('canvas points map back to the original screen', () {
    final l = ScreenLayout.compute(phone, pan: 1);
    final p = l.toScreen(l.tableView.bottomRight - const Offset(1e-6, 1e-6))!;
    expect(p.dx, closeTo(play.right, 1e-3));
    expect(p.dy, closeTo(play.bottom, 1e-3));
    expect(l.toScreen(const Offset(100, 10)), isNull, reason: 'the bar');
  });

  test('letterbox bands map to nothing', () {
    final l = ScreenLayout.compute(const Size(1600, 900));
    expect(l.toScreen(const Offset(5, 450)), isNull);
  });
}
