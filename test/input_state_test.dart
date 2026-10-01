import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/input/input_bindings.dart';

void main() {
  test('original key bindings', () {
    final k = InputBindings.keyboard;
    expect(k[LogicalKeyboardKey.keyZ], GameAction.leftFlipper);
    expect(k[LogicalKeyboardKey.shiftLeft], GameAction.leftFlipper);
    expect(k[LogicalKeyboardKey.slash], GameAction.rightFlipper);
    expect(k[LogicalKeyboardKey.shiftRight], GameAction.rightFlipper);
    expect(k[LogicalKeyboardKey.space], GameAction.plunger);
    expect(k[LogicalKeyboardKey.escape], GameAction.pause);
    expect(k[LogicalKeyboardKey.keyP], GameAction.pause);
  });

  test('both flippers can be held at the same time', () {
    final s = InputState();
    expect(s.press(GameAction.leftFlipper, 'z'), isTrue);
    expect(s.press(GameAction.rightFlipper, '/'), isTrue);
    expect(s.isHeld(GameAction.leftFlipper), isTrue);
    expect(s.isHeld(GameAction.rightFlipper), isTrue);
  });

  test('an action stays held until its last source is released', () {
    final s = InputState();
    expect(s.press(GameAction.leftFlipper, 'z'), isTrue);
    expect(s.press(GameAction.leftFlipper, 'shift'), isFalse);
    expect(s.release(GameAction.leftFlipper, 'z'), isFalse);
    expect(s.isHeld(GameAction.leftFlipper), isTrue);
    expect(s.release(GameAction.leftFlipper, 'shift'), isTrue);
    expect(s.isHeld(GameAction.leftFlipper), isFalse);
  });

  test('key repeat and stray releases do not toggle the action', () {
    final s = InputState();
    s.press(GameAction.plunger, 'space');
    expect(s.press(GameAction.plunger, 'space'), isFalse);
    expect(s.release(GameAction.rightFlipper, '/'), isFalse);
  });
}
