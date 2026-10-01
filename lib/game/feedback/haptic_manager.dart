import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Haptic { light, medium, heavy }

/// Short vibrations for table events, on phones only.
///
/// Rate-limited per strength so a ball rattling between bumpers never
/// turns into a continuous buzz; a stronger pulse also suppresses weaker
/// ones for a moment. Off when the setting is off, and a no-op on the web.
class HapticManager {
  HapticManager({
    required this.enabled,
    double Function()? clock,
    void Function(Haptic)? output,
  }) : _clock = clock ?? _wallClock,
       _output = output ?? _platform;

  /// Whether haptics are on (the setting).
  final bool Function() enabled;
  final double Function() _clock;
  final void Function(Haptic) _output;

  /// Minimum seconds between two pulses of a strength.
  static const gap = {
    Haptic.light: 0.08,
    Haptic.medium: 0.06,
    Haptic.heavy: 0.1,
  };

  final Map<Haptic, double> _last = {};

  void play(Haptic h) {
    if (!enabled()) return;
    final now = _clock();
    for (final s in Haptic.values) {
      if (s.index < h.index) continue;
      final last = _last[s];
      if (last != null && now - last < gap[s]!) return;
    }
    _last[h] = now;
    _output(h);
  }

  static final Stopwatch _watch = Stopwatch()..start();
  static double _wallClock() => _watch.elapsedMicroseconds / 1e6;

  static void _platform(Haptic h) {
    if (kIsWeb) return;
    switch (h) {
      case Haptic.light:
        HapticFeedback.lightImpact();
      case Haptic.medium:
        HapticFeedback.mediumImpact();
      case Haptic.heavy:
        HapticFeedback.heavyImpact();
    }
  }
}
