import 'dart:math' as math;
import 'dart:ui';

import '../game_config.dart';

enum LayoutMode {
  /// The original window: playfield left, scoreboard right, letterboxed.
  landscape,

  /// Phones held upright: scoreboard on top (it is also the menu button),
  /// playfield at the bottom filling the width, so the flippers sit under
  /// the thumbs.
  portrait,
}

/// Where the playfield and the scoreboard go on the device, in canvas
/// pixels, and which part of the original 600 × 416 screen each shows.
///
/// Every view is a uniform scale of its source: proportions never distort.
/// Pure Dart; the game applies it to its cameras.
class ScreenLayout {
  const ScreenLayout._({
    required this.mode,
    required this.tableView,
    required this.tableSource,
    this.scoreboardView,
    this.scoreboardSource,
  });

  /// The whole scoreboard sprite, logo included.
  static const scoreboardFull = GameConfig.scoreboardRect;

  /// Scoreboard without the logo: from the BALL counter (y 152) down to
  /// the mission text box (bottom 391), with a small margin.
  static const scoreboardCompact = Rect.fromLTRB(386, 144, 589, 400);

  /// Portrait needs at least this much room above the playfield for the
  /// scoreboard, in canvas pixels; otherwise the original layout is used.
  static const minScoreboardHeight = 90.0;

  final LayoutMode mode;
  final Rect tableView;
  final Rect tableSource;
  final Rect? scoreboardView;
  final Rect? scoreboardSource;

  double get tableScale => tableView.width / tableSource.width;

  static ScreenLayout compute(Size canvas) {
    final w = canvas.width, h = canvas.height;
    const play = GameConfig.playfieldRect;
    final s = w / play.width;
    final tableHeight = play.height * s;
    final room = h - tableHeight;
    if (w >= h || room < minScoreboardHeight) return _landscape(canvas);

    final tableView = Rect.fromLTWH(0, room, w, tableHeight);
    final area = Rect.fromLTWH(0, 0, w, room);
    final fullScale = _fit(scoreboardFull.size, area.size);
    // The logo is worth showing only if the scoreboard stays about as large
    // as the playfield; otherwise the compact part, at table scale.
    final source = fullScale >= 0.8 * s ? scoreboardFull : scoreboardCompact;
    final scale = math.min(_fit(source.size, area.size), s);
    return ScreenLayout._(
      mode: LayoutMode.portrait,
      tableView: tableView,
      tableSource: play,
      scoreboardSource: source,
      scoreboardView: Rect.fromCenter(
        center: area.center,
        width: source.width * scale,
        height: source.height * scale,
      ),
    );
  }

  static ScreenLayout _landscape(Size canvas) {
    const source = Rect.fromLTWH(
      0,
      0,
      GameConfig.screenWidth,
      GameConfig.screenHeight,
    );
    final scale = _fit(source.size, canvas);
    return ScreenLayout._(
      mode: LayoutMode.landscape,
      tableSource: source,
      tableView: Rect.fromCenter(
        center: Offset(canvas.width / 2, canvas.height / 2),
        width: source.width * scale,
        height: source.height * scale,
      ),
    );
  }

  static double _fit(Size inner, Size outer) =>
      math.min(outer.width / inner.width, outer.height / inner.height);

  /// Maps a canvas point to the original screen, or null outside both
  /// views (letterbox bands).
  Offset? toScreen(Offset canvas) {
    for (final (view, source) in [
      (tableView, tableSource),
      if (scoreboardView case final v?) (v, scoreboardSource!),
    ]) {
      if (view.contains(canvas)) {
        final k = view.width / source.width;
        return source.topLeft + (canvas - view.topLeft) / k;
      }
    }
    return null;
  }

  /// True when [screen] (original screen coordinates) is on the scoreboard,
  /// which doubles as the menu button.
  static bool isScoreboard(Offset screen) =>
      GameConfig.scoreboardRect.contains(screen);
}
