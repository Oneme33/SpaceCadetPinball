import 'package:flutter_test/flutter_test.dart';
import 'package:space_cadet/game/ui/text_box.dart';

void main() {
  test('shows a message for its time, then the next', () {
    var expired = 0;
    final t = TextBox(onTimerExpired: () => expired++)
      ..display('A', 1)
      ..display('B', 1);
    expect(t.text, 'A');
    t.update(1.01);
    expect(t.text, 'B');
    t.update(1.01);
    expect(t.text, isNull);
    expect(expired, 2);
  });

  test('a permanent message stays while it is the last one', () {
    final t = TextBox()..display('Player 1', -1);
    t.update(60);
    expect(t.text, 'Player 1');
    t.display('Mission accepted', 2);
    expect(t.text, 'Mission accepted');
    t.update(2.1);
    expect(t.text, isNull);
  });

  test('the same text again extends it', () {
    final t = TextBox()..display('Fuel added', 1);
    t.update(0.8);
    t.display('Fuel added', 1);
    t.update(0.8);
    expect(t.text, 'Fuel added');
    t.update(0.3);
    expect(t.text, isNull);
  });

  test('stale messages are skipped', () {
    final t = TextBox()
      ..display('A', 5)
      ..display('B', 0.5)
      ..display('C', 9);
    t.update(5.01);
    // B ran out 4.5 s ago: more than 2 s, skipped.
    expect(t.text, 'C');
  });

  test('a message shows at least a quarter second', () {
    final t = TextBox()
      ..display('A', 1)
      ..display('B', 1.05);
    t.update(1.0);
    expect(t.text, 'B');
    t.update(0.2);
    expect(t.text, 'B');
    t.update(0.1);
    expect(t.text, isNull);
  });

  test('clear can keep high-priority messages', () {
    final t = TextBox()
      ..display('low', 5, lowPriority: true)
      ..display('high', 5);
    t.clear(lowPriorityOnly: true);
    expect(t.text, 'high');
    t.clear();
    expect(t.text, isNull);
  });
}
