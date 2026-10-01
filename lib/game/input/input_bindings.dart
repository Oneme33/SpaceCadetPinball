import 'package:flutter/services.dart';

/// What the player can do, independent of the device that does it.
enum GameAction {
  leftFlipper,
  rightFlipper,
  plunger,
  pause,
  start,

  /// Bump the table from the left, the right or the front.
  nudgeLeft,
  nudgeRight,
  nudgeBottom,
}

/// Desktop key bindings, as in the original.
abstract final class InputBindings {
  static final Map<LogicalKeyboardKey, GameAction> keyboard = {
    LogicalKeyboardKey.keyZ: GameAction.leftFlipper,
    LogicalKeyboardKey.shiftLeft: GameAction.leftFlipper,
    LogicalKeyboardKey.arrowLeft: GameAction.leftFlipper,
    LogicalKeyboardKey.slash: GameAction.rightFlipper,
    LogicalKeyboardKey.shiftRight: GameAction.rightFlipper,
    LogicalKeyboardKey.arrowRight: GameAction.rightFlipper,
    LogicalKeyboardKey.space: GameAction.plunger,
    LogicalKeyboardKey.escape: GameAction.pause,
    LogicalKeyboardKey.keyP: GameAction.pause,
    LogicalKeyboardKey.f2: GameAction.start,
    LogicalKeyboardKey.enter: GameAction.start,
    // The original's table bump keys.
    LogicalKeyboardKey.keyX: GameAction.nudgeLeft,
    LogicalKeyboardKey.period: GameAction.nudgeRight,
    LogicalKeyboardKey.arrowUp: GameAction.nudgeBottom,
  };
}

/// Which actions are held right now.
///
/// An action can be held by several sources at once (Z and Left Shift, or a
/// key and a finger). It counts as released only when every source has let
/// go, so releasing Z while Shift is still down keeps the flipper up.
class InputState {
  final Map<GameAction, Set<Object>> _sources = {
    for (final a in GameAction.values) a: <Object>{},
  };

  bool isHeld(GameAction action) => _sources[action]!.isNotEmpty;

  /// Returns true when this press made the action go from released to held.
  bool press(GameAction action, Object source) {
    final set = _sources[action]!;
    final wasHeld = set.isNotEmpty;
    set.add(source);
    return !wasHeld;
  }

  /// Returns true when this release made the action go from held to released.
  bool release(GameAction action, Object source) {
    final set = _sources[action]!;
    final removed = set.remove(source);
    return removed && set.isEmpty;
  }

  void releaseAll() {
    for (final set in _sources.values) {
      set.clear();
    }
  }
}
