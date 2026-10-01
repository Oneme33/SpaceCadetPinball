/// A scoreboard message box (`TTextBox`): a queue of messages, each shown
/// for its time. Pure Dart, driven by game time through [update].
///
/// As in the original:
/// - a message with time −1 stays until something replaces it, but only
///   when it is the last one in the queue;
/// - showing the same text as the last queued message just extends it;
/// - messages that ran out more than 2 s ago are skipped;
/// - a message is shown for at least 0.25 s.
class TextBox {
  TextBox({this.onTimerExpired});

  /// `ControlTimerExpired`, after a message has been shown.
  final void Function()? onTimerExpired;

  final List<_Message> _queue = [];
  double _now = 0;
  double? _showUntil;

  /// Text on display, or null.
  String? text;

  bool get isEmpty => text == null;

  void display(String message, double time, {bool lowPriority = false}) {
    if (_queue.isNotEmpty && _queue.last.text == message) {
      final last = _queue.last..refresh(_now, time);
      if (identical(last, _queue.first)) {
        _showUntil = time == -1 ? null : _now + time;
      }
      return;
    }
    if (_queue.isNotEmpty && _queue.first.time == -1 && _showUntil == null) {
      clear();
    }
    _queue.add(_Message(message, time, _now, lowPriority));
    if (_queue.length == 1) _draw();
  }

  void clear({bool lowPriorityOnly = false}) {
    _showUntil = null;
    while (_queue.isNotEmpty &&
        (!lowPriorityOnly || _queue.first.lowPriority)) {
      _queue.removeAt(0);
    }
    text = null;
    if (_queue.isNotEmpty) _draw();
  }

  void update(double dt) {
    _now += dt;
    final until = _showUntil;
    if (until == null || _now < until) return;
    _showUntil = null;
    if (_queue.isNotEmpty) _queue.removeAt(0);
    _draw();
    onTimerExpired?.call();
  }

  void _draw() {
    text = null;
    while (_queue.isNotEmpty) {
      final m = _queue.first;
      if (m.time == -1) {
        if (_queue.length == 1) {
          text = m.text;
          _showUntil = null;
          return;
        }
      } else if (m.timeLeft(_now) >= -2) {
        text = m.text;
        _showUntil = _now + (m.timeLeft(_now) < 0.25 ? 0.25 : m.timeLeft(_now));
        return;
      }
      _queue.removeAt(0);
    }
  }
}

class _Message {
  _Message(this.text, this.time, double now, this.lowPriority)
    : _end = now + time;

  final String text;
  double time;
  final bool lowPriority;
  double _end;

  double timeLeft(double now) => _end - now;

  void refresh(double now, double time) {
    this.time = time;
    _end = now + time;
  }
}
