import '../../rules/message_code.dart';
import 'light_part.dart';
import 'part.dart';

/// `TLightGroup`: an ordered set of lights (attribute 1027) that the rules
/// move as one: step, animate, count, light the next one…
class LightGroupPart extends TablePart {
  LightGroupPart(super.ctx, super.component)
    : timer1Default = component.attributes[903]?.first ?? 0 {
    frame = -1;
    _timer1 = timer1Default;
  }

  final double timer1Default;
  late final List<LightPart> lights = [
    for (final g in component.shortAttributes[1027] ?? const <int>[])
      if (ctx.partByGroup(g) case final LightPart l) l,
  ];

  int _messageField2 = MC.tLightGroupNull;
  int _animationFlag = 0;
  double _timer1 = 0;
  int? _timer, _notifyTimer;

  int get count => lights.length;

  @override
  void reset() {
    _cancel(_timer);
    _cancel(_notifyTimer);
    _timer = _notifyTimer = null;
    _messageField2 = MC.tLightGroupNull;
    _animationFlag = 0;
    _timer1 = timer1Default;
  }

  @override
  int message(int code, double value) {
    if (lights.isEmpty && code != MC.reset) return 0;
    switch (code) {
      case MC.setTiltLock:
      case MC.gameOver:
        break;
      case MC.reset:
        reset();
        messageField = 0;
      case MC.tLightGroupStepBackward:
        final last = lights.last;
        if (last.flasherOn || last.toggledOn || last.toggledOff) break;
        if (_messageField2 != MC.tLightGroupNull) {
          message(MC.tLightGroupReset, 0);
        }
        _animationFlag = 1;
        _messageField2 = code;
        final lastField = last.messageField, lastOn = last.lightOn;
        for (var i = count - 1; i > 0; i--) {
          lights[i].setOn(lights[i - 1].lightOn);
          lights[i].messageField = lights[i - 1].messageField;
        }
        lights.first
          ..setOn(lastOn)
          ..messageField = lastField;
        _reschedule(value);
      case MC.tLightGroupStepForward:
        final last = lights.last;
        if (last.flasherOn || last.toggledOn || last.toggledOff) break;
        if (_messageField2 != MC.tLightGroupNull) {
          message(MC.tLightGroupReset, 0);
        }
        _animationFlag = 1;
        _messageField2 = code;
        final first = lights.first;
        final firstField = first.messageField, firstOn = first.lightOn;
        for (var i = 0; i < count - 1; i++) {
          lights[i].setOn(lights[i + 1].lightOn);
          lights[i].messageField = lights[i + 1].messageField;
        }
        last
          ..setOn(firstOn)
          ..messageField = firstField;
        _reschedule(value);
      case MC.tLightGroupAnimationBackward:
        if (_animationFlag != 0 || _messageField2 == MC.tLightGroupNull) {
          _startAnimation();
        }
        _messageField2 = code;
        _animationFlag = 0;
        final lastOn = lights.last.toggledOn;
        for (var i = count - 1; i > 0; i--) {
          _timed(lights[i], lights[i - 1].toggledOn);
        }
        _timed(lights.first, lastOn);
        _reschedule(value);
      case MC.tLightGroupAnimationForward:
        if (_animationFlag != 0 || _messageField2 == MC.tLightGroupNull) {
          _startAnimation();
        }
        _messageField2 = code;
        _animationFlag = 0;
        final firstOn = lights.first.toggledOn;
        for (var i = 0; i < count - 1; i++) {
          _timed(lights[i], lights[i + 1].toggledOn);
        }
        _timed(lights.last, firstOn);
        _reschedule(value);
      case MC.tLightGroupLightShowAnimation:
        if (_animationFlag != 0 || _messageField2 == MC.tLightGroupNull) {
          _startAnimation();
        }
        _messageField2 = code;
        _animationFlag = 0;
        for (final l in lights) {
          if (ctx.random.nextInt(100) > 70) {
            l.turnOnTimed(ctx.random.nextDouble() * value * 3 + 0.1);
          }
        }
        _reschedule(value);
      case MC.tLightGroupGameOverAnimation:
        if (_animationFlag != 0 || _messageField2 == MC.tLightGroupNull) {
          _startAnimation();
        }
        _messageField2 = code;
        _animationFlag = 0;
        for (final l in lights) {
          l.message(
            MC.tLightResetAndToggleValue,
            ctx.random.nextInt(100) > 70 ? 1 : 0,
          );
        }
        _reschedule(value);
      case MC.tLightGroupRandomAnimationSaturation:
        final off = lights.where((l) => !l.lightOn).length;
        if (off == 0) break;
        var pick = ctx.random.nextInt(off);
        for (final l in lights.reversed) {
          if (!l.lightOn && pick-- == 0) {
            l.turnOn();
            break;
          }
        }
        if (_messageField2 != MC.tLightGroupNull) _startAnimation();
      case MC.tLightGroupRandomAnimationDesaturation:
        final on = lights.where((l) => l.lightOn).length;
        if (on == 0) break;
        var pick = ctx.random.nextInt(on);
        for (final l in lights.reversed) {
          if (l.lightOn && pick-- == 0) {
            l.turnOff();
            break;
          }
        }
        if (_messageField2 != MC.tLightGroupNull) _startAnimation();
      case MC.tLightGroupOffsetAnimationForward:
        final i = _nextUp();
        if (i < 0) break;
        lights[i].turnOn();
        if (_messageField2 != MC.tLightGroupNull) _startAnimation();
        return 1;
      case MC.tLightGroupOffsetAnimationBackward:
        final i = _nextDown();
        if (i < 0) break;
        lights[i].turnOff();
        if (_messageField2 != MC.tLightGroupNull) _startAnimation();
        return 1;
      case MC.tLightGroupReset:
        _cancel(_timer);
        _timer = null;
        if (_messageField2 == MC.tLightGroupAnimationBackward ||
            _messageField2 == MC.tLightGroupAnimationForward ||
            _messageField2 == MC.tLightGroupLightShowAnimation) {
          _forward(MC.tLightResetTimed, 0);
        }
        _messageField2 = MC.tLightGroupNull;
        _animationFlag = 0;
      case MC.tLightGroupTurnOnAtIndex:
        final i = value.floor();
        if (i < 0 || i >= count) break;
        lights[i].turnOn();
        if (_messageField2 != MC.tLightGroupNull) _startAnimation();
      case MC.tLightGroupTurnOffAtIndex:
        final i = value.floor();
        if (i < 0 || i >= count) break;
        lights[i].turnOff();
        if (_messageField2 != MC.tLightGroupNull) _startAnimation();
      case MC.tLightGroupGetOnCount:
        return lights.where((l) => l.lightOn).length;
      case MC.tLightGroupGetLightCount:
        return count;
      case MC.tLightGroupGetMessage2:
        return _messageField2;
      case MC.tLightGroupGetAnimationFlag:
        return _animationFlag;
      case MC.tLightGroupResetAndTurnOn:
        final i = _nextUp();
        if (i < 0) break;
        if (_messageField2 != MC.tLightGroupNull || _animationFlag != 0) {
          message(MC.tLightGroupReset, 0);
        }
        lights[i].flasherStartTimedThenStayOn(value);
        return 1;
      case MC.tLightGroupResetAndTurnOff:
        final i = _nextDown();
        if (i < 0) break;
        if (_messageField2 != MC.tLightGroupNull || _animationFlag != 0) {
          message(MC.tLightGroupReset, 0);
        }
        lights[i].flasherStartTimedThenStayOff(value);
        return 1;
      case MC.tLightGroupRestartNotifyTimer:
        _cancel(_notifyTimer);
        _notifyTimer = value > 0
            ? ctx.timers.set(value, () {
                _notifyTimer = null;
                emit(MC.controlNotifyTimerExpired);
              })
            : null;
      case MC.tLightGroupFlashWhenOn:
        for (final l in lights.reversed) {
          if (l.lightOn) {
            l
              ..turnOff()
              ..flasherStartTimedThenStayOff(value);
          }
        }
      case MC.tLightGroupToggleSplitIndex:
        emit(code);
        toggleSplitIndex(value.floor());
      case MC.tLightGroupStartFlasher:
        final i = _nextDown();
        if (i >= 0) lights[i].flasherStart();
      default:
        _forward(code, value);
    }
    return 0;
  }

  /// Lights [0, index] on, the rest off.
  void toggleSplitIndex(int index) {
    if (index < 0 || index >= count) return;
    for (var i = count - 1; i > index; i--) {
      lights[i].resetAndTurnOff();
    }
    for (var i = index; i >= 0; i--) {
      lights[i].resetAndTurnOn();
    }
  }

  void _forward(int code, double value) {
    for (final l in lights.reversed) {
      l.message(code, value);
    }
  }

  void _timed(LightPart l, bool on) =>
      on ? l.turnOnTimed(0) : l.turnOffTimed(0);

  void _reschedule(double time) {
    _cancel(_timer);
    _timer = null;
    if (time == 0) {
      _messageField2 = MC.tLightGroupNull;
      _animationFlag = 0;
      return;
    }
    _timer1 = time > 0 ? time : timer1Default;
    _timer = ctx.timers.set(_timer1, () {
      _timer = null;
      message(_messageField2, _timer1);
    });
  }

  void _startAnimation() {
    for (final l in lights.reversed) {
      _timed(l, l.lightOn);
    }
  }

  int _nextUp() {
    for (var i = 0; i < count; i++) {
      if (!lights[i].lightOn) return i;
    }
    return -1;
  }

  int _nextDown() {
    for (var i = count - 1; i >= 0; i--) {
      if (lights[i].lightOn) return i;
    }
    return -1;
  }

  void _cancel(int? t) {
    if (t != null) ctx.timers.cancel(t);
  }
}

/// `TLightBargraph`: the fuel gauge. Its level counts down by itself, one
/// half-light per step, with the times of attribute 904.
class LightBargraphPart extends LightGroupPart {
  LightBargraphPart(super.ctx, super.component)
    : times = component.attributes[904] ?? const [];

  final List<double> times;
  int timeIndex = 0;
  int? _barTimer;

  @override
  void reset() {
    if (_barTimer case final t?) ctx.timers.cancel(t);
    _barTimer = null;
    timeIndex = 0;
    super.reset();
  }

  @override
  int message(int code, double value) {
    switch (code) {
      case MC.tLightGroupGetOnCount:
        return timeIndex;
      case MC.tLightGroupToggleSplitIndex:
        if (_barTimer case final t?) ctx.timers.cancel(t);
        _barTimer = null;
        var index = value.floor();
        final max = count * 2;
        if (index >= max) index = max - 1;
        if (index >= 0) {
          super.message(MC.tLightGroupToggleSplitIndex, (index ~/ 2) * 1.0);
          if (index.isEven) super.message(MC.tLightGroupStartFlasher, 0);
          if (index < times.length) {
            _barTimer = ctx.timers.set(times[index], _expired);
          }
          timeIndex = index;
        } else {
          super.message(MC.tLightResetAndTurnOff, 0);
          timeIndex = 0;
        }
      case MC.setTiltLock:
        reset();
      case MC.reset:
        reset();
        super.message(MC.reset, value);
      default:
        return super.message(code, value);
    }
    return 0;
  }

  void _expired() {
    _barTimer = null;
    if (timeIndex != 0) {
      message(MC.tLightGroupToggleSplitIndex, (timeIndex - 1) * 1.0);
      emit(MC.controlTimerExpired);
    } else {
      message(MC.tLightResetAndTurnOff, 0);
      emit(MC.tLightGroupCountdownEnded);
    }
  }
}

/// `TComponentGroup`: forwards messages to its members (attribute 1027).
class ComponentGroupPart extends TablePart {
  ComponentGroupPart(super.ctx, super.component) {
    frame = -1;
  }

  late final List<TablePart> members = [
    for (final g in component.shortAttributes[1027] ?? const <int>[])
      ?ctx.partByGroup(g),
  ];

  int? _timer;

  @override
  int message(int code, double value) {
    if (code == MC.tComponentGroupResetNotifyTimer) {
      if (_timer case final t?) ctx.timers.cancel(t);
      _timer = value > 0
          ? ctx.timers.set(value, () {
              _timer = null;
              emit(MC.controlNotifyTimerExpired);
            })
          : null;
    } else if (code < MC.pause ||
        (code > MC.setTiltLock &&
            code != MC.playerChanged &&
            code != MC.gameOver)) {
      for (final m in members) {
        m.message(code, value);
      }
    }
    return 0;
  }
}

/// `TSound`: a named sound the rules play; returns its length.
class SoundPart extends TablePart {
  SoundPart(super.ctx, super.component) {
    frame = -1;
  }

  int? get _sound => visual.sound4;

  double play() {
    sound(_sound);
    return _sound == null ? 0 : ctx.soundDuration(_sound);
  }
}
