import 'dart:math' as math;
import 'dart:ui';

import '../game_config.dart';

enum LayoutMode {
  /// The original window: playfield left, scoreboard right, letterboxed.
  landscape,

  /// Phones held upright: a slim bar with score, ball, messages and the
  /// menu button on top ([ScreenLayout.hudHeight], drawn by the app), the
  /// playfield below it at the full height of the screen. It is wider than
  /// the screen then, so the view follows the ball sideways ([pan]).
  phone,
}

/// How close the phone view is: [close] fills the height of the screen
/// (the view follows the ball sideways); the others show more of the
/// table, as a share of the scale at which its whole width fits.
enum PhoneZoom {
  close(null, 'Close'),
  medium(1.2, 'Medium'),
  whole(1.0, 'Whole table');

  const PhoneZoom(this.factor, this.label);

  /// Scale relative to the whole width; null: the full height.
  final double? factor;
  final String label;

  PhoneZoom get next => values[(index + 1) % values.length];
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
    this.panRange = 0,
  });

  /// Height of the phone bar above the playfield, in canvas pixels.
  static const hudHeight = 64.0;

  /// Upright screens narrower than this (width ÷ height) get the phone
  /// layout; squarer ones keep the original window.
  static const maxPhoneAspect = 0.8;

  final LayoutMode mode;
  final Rect tableView;
  final Rect tableSource;

  /// How far, in original screen pixels, the phone view can move sideways
  /// over the playfield; 0 when the whole width fits.
  final double panRange;

  double get tableScale => tableView.width / tableSource.width;

  /// [pan] places the phone view over the playfield: 0 at its left edge,
  /// 1 at its right edge (the plunger lane). [zoom] is how close it is.
  static ScreenLayout compute(
    Size canvas, {
    double pan = 0.5,
    PhoneZoom zoom = PhoneZoom.close,
  }) {
    final w = canvas.width, h = canvas.height;
    if (w >= h * maxPhoneAspect || h <= hudHeight) return _landscape(canvas);

    const play = GameConfig.playfieldRect;
    final area = Rect.fromLTRB(0, hudHeight, w, h);
    final fullHeight = area.height / play.height;
    final factor = zoom.factor;
    // Never closer than the full height: then the table would be cut off
    // at the top and bottom too.
    final scale = factor == null
        ? fullHeight
        : math.min(fullHeight, factor * _fit(play.size, area.size));
    final visible = w / scale;
    if (visible >= play.width) {
      // Wide enough for the whole playfield at full height: centred.
      final s = _fit(play.size, area.size);
      return ScreenLayout._(
        mode: LayoutMode.phone,
        tableSource: play,
        tableView: Rect.fromCenter(
          center: area.center,
          width: play.width * s,
          height: play.height * s,
        ),
      );
    }
    final range = play.width - visible;
    final height = play.height * scale;
    return ScreenLayout._(
      mode: LayoutMode.phone,
      // Below the full height the table sits in the middle of the area.
      tableView: Rect.fromLTWH(
        0,
        area.top + (area.height - height) / 2,
        w,
        height,
      ),
      tableSource: Rect.fromLTWH(
        play.left + range * pan.clamp(0.0, 1.0),
        play.top,
        visible,
        play.height,
      ),
      panRange: range,
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

  /// The [pan] that brings original screen x [x] into view, keeping it in
  /// the middle [keep] share of the view; [current] if it is already there.
  double panToShow(double x, double current, {double keep = 0.4}) {
    if (panRange <= 0) return current;
    final visible = tableSource.width;
    final left = GameConfig.playfieldRect.left + panRange * current;
    final margin = visible * (1 - keep) / 2;
    var target = left;
    if (x < left + margin) target = x - margin;
    if (x > left + visible - margin) target = x - visible + margin;
    return ((target - GameConfig.playfieldRect.left) / panRange).clamp(
      0.0,
      1.0,
    );
  }

  /// Maps a canvas point to the original screen, or null outside the view
  /// (letterbox bands, the phone bar).
  Offset? toScreen(Offset canvas) {
    if (!tableView.contains(canvas)) return null;
    return tableSource.topLeft + (canvas - tableView.topLeft) / tableScale;
  }

  /// True when [screen] (original screen coordinates) is on the scoreboard,
  /// which doubles as the menu button in the original window.
  static bool isScoreboard(Offset screen) =>
      GameConfig.scoreboardRect.contains(screen);
}
