import '../../rules/message_code.dart';
import '../../ui/text_box.dart';
import 'part.dart';

/// `TDrain`: tells the rules a ball went down (`ControlCollision`) and,
/// once no ball is left in play, again after its timer (attribute 407,
/// `ControlTimerExpired`), when the next ball or game over follows.
class DrainPart extends TablePart {
  DrainPart(super.ctx, super.component, {required this.timerTime}) {
    frame = -1;
  }

  final double timerTime;
  int? _timer;

  /// Set by the table: balls in play (`TPinballTable::MultiballCount`).
  late int Function() ballsInPlay;
  late void Function(int) setBallsInPlay;

  void ballDrained() {
    final left = ballsInPlay() - 1;
    setBallsInPlay(left <= 0 ? 0 : left);
    if (left <= 0) {
      _timer = ctx.timers.set(timerTime, () {
        _timer = null;
        emit(MC.controlTimerExpired);
      });
    }
    emit(MC.controlCollision);
  }

  @override
  int message(int code, double value) {
    if (code == MC.reset) {
      if (_timer case final t?) ctx.timers.cancel(t);
      _timer = null;
    }
    return 0;
  }
}

/// `TPlunger` as the rules see it: feeding balls and the automatic
/// relaunch. Every message is also reported to the rules, as the
/// original does (`control::handler(code, this)` in `TPlunger::Message`).
class PlungerPart extends TablePart {
  PlungerPart(
    super.ctx,
    super.component, {
    required this.feed,
    required this.ballAtFeed,
    required this.autoLaunch,
    required this.feedSound,
  }) {
    frame = -1;
  }

  /// Adds a ball in the lane and counts it in play.
  final void Function() feed;

  /// A ball is already sitting where a new one would appear.
  final bool Function() ballAtFeed;

  /// Arms the plunger to launch the next ball by itself.
  final void Function() autoLaunch;

  final void Function() feedSound;

  int? _feedTimer;

  @override
  int message(int code, double value) {
    switch (code) {
      case MC.plungerStartFeedTimer:
        _setFeed(0.96);
        feedSound();
      case MC.plungerFeedBall:
        if (ballAtFeed()) {
          _setFeed(1);
        } else {
          feed();
        }
      case MC.plungerLaunchBall:
      case MC.plungerRelaunchBall:
        autoLaunch();
        if (code == MC.plungerRelaunchBall) {
          _setFeed(value);
          feedSound();
        }
      case MC.reset:
      case MC.playerChanged:
        if (_feedTimer case final t?) ctx.timers.cancel(t);
        _feedTimer = null;
    }
    emit(code);
    return 0;
  }

  void _setFeed(double seconds) {
    if (_feedTimer case final t?) ctx.timers.cancel(t);
    _feedTimer = ctx.timers.set(seconds, () {
      _feedTimer = null;
      message(MC.plungerFeedBall, 0);
    });
  }
}

/// `TTextBox` as the rules see it: a component they can display on and
/// compare with; reports `ControlTimerExpired` when a message ends.
class TextBoxPart extends TablePart {
  TextBoxPart(super.ctx, super.component, this.box) {
    frame = -1;
  }

  final TextBox box;

  void display(String text, double time) => box.display(text, time);
  void clear() => box.clear();

  /// Called by the text box when a message has run out.
  void expired() => emit(MC.controlTimerExpired);
}

/// `TFlipper` as the rules see it: reports `TFlipperExtend`.
class FlipperPart extends TablePart {
  FlipperPart(super.ctx, super.component) {
    frame = -1;
  }

  void extended() => emit(MC.tFlipperExtend);
}
