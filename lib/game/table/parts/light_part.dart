import 'part.dart';

/// `TLight`: an insert light. Off shows nothing (sprite −1), on shows its
/// on-state sprite (0, or [onStateBitmap]). Flashing alternates with the
/// delays of attributes 900 (on) and 901 (off).
///
/// The method names follow the original's message codes; the rules drive
/// the lights through them.
class LightPart extends TablePart {
  LightPart(super.ctx, super.component)
    : _onDelay = component.attributes[900]?.first ?? 0.1,
      _offDelay = component.attributes[901]?.first ?? 0.1 {
    _sourceOn = _onDelay;
    _sourceOff = _offDelay;
    reset();
  }

  late double _sourceOn, _sourceOff;
  double _onDelay, _offDelay;

  bool lightOn = false;
  bool flasherOn = false;
  bool _toggledOn = false, _toggledOff = false;
  bool _flashLit = false;
  bool _turnOffAfterFlashing = false;
  int onStateBitmap = 0;

  int? _timeout, _flashTimer;

  /// `light_on`.
  bool get isLit => lightOn || _toggledOn || flasherOn;

  int get _offFrame => -1;
  int get _onFrame => onStateBitmap;
  int _frameFor(bool on) => on ? _onFrame : _offFrame;

  @override
  void reset() {
    _cancel(_timeout);
    _stopFlasher();
    _timeout = null;
    lightOn = false;
    onStateBitmap = 0;
    _toggledOn = _toggledOff = false;
    flasherOn = false;
    _turnOffAfterFlashing = false;
    frame = _offFrame;
  }

  // --- Messages ------------------------------------------------------------

  void turnOn() {
    lightOn = true;
    if (!flasherOn && !_toggledOff && !_toggledOn) frame = _onFrame;
  }

  void turnOff() {
    lightOn = false;
    if (!flasherOn && !_toggledOff && !_toggledOn) frame = _offFrame;
  }

  void toggle() => lightOn ? turnOff() : turnOn();

  void setOn(bool on) => on ? turnOn() : turnOff();

  void flasherStart() {
    _scheduleTimeout(0);
    if (!flasherOn || _flashTimer == null) {
      flasherOn = true;
      _toggledOn = _toggledOff = false;
      _turnOffAfterFlashing = false;
      _startFlasher(lightOn);
    }
  }

  void flasherStartTimed(double seconds) {
    if (!flasherOn) _startFlasher(lightOn);
    flasherOn = true;
    _toggledOn = _toggledOff = false;
    _turnOffAfterFlashing = false;
    _scheduleTimeout(seconds);
  }

  void flasherStartTimedThenStayOn(double seconds) {
    _turnOffAfterFlashing = false;
    turnOn();
    flasherStartTimed(seconds);
  }

  void flasherStartTimedThenStayOff(double seconds) {
    flasherStartTimed(seconds);
    _turnOffAfterFlashing = true;
  }

  void turnOnTimed(double seconds) {
    if (!_toggledOn) {
      if (flasherOn) {
        _stopFlasher(showOn: true);
        flasherOn = false;
      } else {
        frame = _onFrame;
      }
      _toggledOn = true;
      _toggledOff = false;
    }
    _scheduleTimeout(seconds);
  }

  void turnOffTimed(double seconds) {
    if (!_toggledOff) {
      if (flasherOn) {
        _stopFlasher(showOn: false);
        flasherOn = false;
      } else {
        frame = _offFrame;
      }
      _toggledOff = true;
      _toggledOn = false;
    }
    _scheduleTimeout(seconds);
  }

  /// `TLightResetTimed`: back to the plain on/off state.
  void resetTimed() {
    _cancel(_timeout);
    _timeout = null;
    if (flasherOn) _stopFlasher();
    flasherOn = false;
    _toggledOn = _toggledOff = false;
    frame = _frameFor(lightOn);
  }

  void resetAndTurnOn() {
    turnOn();
    resetTimed();
  }

  void resetAndTurnOff() {
    turnOff();
    resetTimed();
  }

  /// `TLightApplyMultDelay`: flash faster or slower.
  void applyDelayMultiplier(double m) {
    _onDelay = m * _sourceOn;
    _offDelay = m * _sourceOff;
  }

  void setOnStateBitmap(int index) {
    onStateBitmap = index.clamp(0, component.states.length - 1);
    final on = flasherOn
        ? _flashLit
        : _toggledOff
        ? false
        : _toggledOn || lightOn;
    frame = _frameFor(on);
  }

  // --- Internals -------------------------------------------------------------

  void _scheduleTimeout(double seconds) {
    _onDelay = _sourceOn;
    _offDelay = _sourceOff;
    _cancel(_timeout);
    _timeout = seconds > 0 ? ctx.timers.set(seconds, _timedOut) : null;
  }

  void _timedOut() {
    _timeout = null;
    if (flasherOn) _stopFlasher();
    frame = _frameFor(lightOn);
    _toggledOn = _toggledOff = false;
    flasherOn = false;
    if (_turnOffAfterFlashing) {
      _turnOffAfterFlashing = false;
      resetAndTurnOff();
    }
    emit(PartEventKind.timerExpired);
  }

  void _startFlasher(bool lit) {
    _flashLit = lit;
    _flash();
  }

  void _flash() {
    _flashLit = !_flashLit;
    frame = _frameFor(_flashLit);
    _flashTimer = ctx.timers.set(_flashLit ? _onDelay : _offDelay, _flash);
  }

  void _stopFlasher({bool? showOn}) {
    _cancel(_flashTimer);
    _flashTimer = null;
    if (showOn != null) {
      _flashLit = showOn;
      frame = _frameFor(showOn);
    }
  }

  void _cancel(int? timer) {
    if (timer != null) ctx.timers.cancel(timer);
  }
}
