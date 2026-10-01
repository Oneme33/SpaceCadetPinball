import 'dart:ui';

/// Global constants. Everything that defines a coordinate space or a timing
/// lives here, so nothing positions itself in device pixels. Table geometry
/// itself comes from PINBALL.DAT, see [TableLayout].
abstract final class GameConfig {
  /// Debug overlay, collision shapes and click-to-spawn.
  /// Enable with `--dart-define=SC_DEBUG=true`.
  static const bool debug = bool.fromEnvironment('SC_DEBUG');

  // --- Screen space -------------------------------------------------------

  /// The original virtual screen (`table_size` in PINBALL.DAT). All art is
  /// positioned in this space; it is scaled uniformly to the device.
  static const double screenWidth = 600;
  static const double screenHeight = 416;

  /// Scoreboard sprite (`background` group): 203 × 394 at (386, 12).
  static const Rect scoreboardRect = Rect.fromLTWH(386, 12, 203, 394);

  /// Playfield sprite (`table` group, 365 × 470) is drawn at (0, 0) and
  /// cropped by the screen height, as in the original.
  static const Rect playfieldRect = Rect.fromLTWH(0, 0, 365, 416);

  // --- Timing -------------------------------------------------------------

  /// Physics step. 240 Hz keeps flipper contact accurate at high ball speed.
  static const double physicsStep = 1 / 240;

  /// Box2D v3 sub-steps per physics step.
  static const int physicsSubSteps = 4;

  /// Cap on physics steps per rendered frame (see [FixedStepper]).
  static const int maxStepsPerFrame = 16;
}
