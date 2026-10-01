/// One-shot timers in game time, like the original's `timer::set`.
///
/// They only advance when [update] is called, so pausing the game pauses
/// them too. Pure Dart, testable without a game loop.
class GameTimers {
  final List<_Timer> _timers = [];
  int _nextId = 1;

  int get pending => _timers.length;

  /// Calls [callback] after [seconds] of game time. Returns an id for
  /// [cancel].
  int set(double seconds, void Function() callback) {
    final id = _nextId++;
    _timers.add(_Timer(id, seconds, callback));
    return id;
  }

  void cancel(int id) => _timers.removeWhere((t) => t.id == id);

  void clear() => _timers.clear();

  void update(double dt) {
    if (_timers.isEmpty) return;
    final due = <_Timer>[];
    for (final t in _timers) {
      t.remaining -= dt;
      if (t.remaining <= 0) due.add(t);
    }
    for (final t in due) {
      _timers.remove(t);
      t.callback();
    }
  }
}

class _Timer {
  _Timer(this.id, this.remaining, this.callback);
  final int id;
  double remaining;
  final void Function() callback;
}
