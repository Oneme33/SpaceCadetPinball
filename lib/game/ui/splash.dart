import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../space_cadet_game.dart';

/// The loading screen: a starfield, the title in the logo's lavender and a
/// progress bar in the scoreboard's metal, until the game has loaded; then
/// it fades away. Twinkling stops when the system asks for reduced motion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.game});
  final SpaceCadetGame game;

  /// Shown at least this long, so a fast load does not flash it.
  static const minimum = Duration(milliseconds: 1400);
  static const fade = Duration(milliseconds: 500);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(
    (t) => _time.value = t.inMicroseconds / 1e6,
  );
  final _time = ValueNotifier<double>(0);
  final _shownSince = Stopwatch()..start();
  bool _leaving = false, _gone = false;

  @override
  void initState() {
    super.initState();
    widget.game.loading.addListener(_check);
    _check();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _check() {
    if (_leaving || widget.game.loading.value.$1 < 1) return;
    final wait = SplashScreen.minimum - _shownSince.elapsed;
    Future.delayed(wait.isNegative ? Duration.zero : wait, () {
      if (mounted) setState(() => _leaving = true);
    });
  }

  @override
  void dispose() {
    widget.game.loading.removeListener(_check);
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: _leaving,
      child: AnimatedOpacity(
        opacity: _leaving ? 0 : 1,
        duration: SplashScreen.fade,
        onEnd: () {
          if (_leaving) {
            _ticker.stop();
            setState(() => _gone = true);
          }
        },
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(child: CustomPaint(painter: _Stars(_time))),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Title(),
                      const SizedBox(height: 36),
                      ValueListenableBuilder(
                        valueListenable: widget.game.loading,
                        builder: (context, v, _) => _Progress(v.$1, v.$2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "3D Pinball" over "Space Cadet", in the logo's lavender with a dark
/// violet outline.
class _Title extends StatelessWidget {
  const _Title();

  static const _lavender = Color(0xFFB8A4F0);
  static const _violet = Color(0xFF7A5CD6);
  static const _outline = Color(0xFF2A1B5C);

  Widget _outlined(String text, double size, {double spacing = 0}) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: spacing,
      height: 1,
    );
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size / 9
              ..strokeJoin = StrokeJoin.round
              ..color = _outline,
          ),
        ),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6DCFF), _lavender, _violet],
          ).createShader(r),
          child: Text(text, style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final big = math.min(84.0, width / 6.2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _outlined('3D Pinball', big * 0.45, spacing: 1),
        SizedBox(height: big * 0.12),
        _outlined('Space Cadet', big),
      ],
    );
  }
}

/// The scoreboard's bevelled metal around a recessed bar, filled in the
/// blue of the score digits.
class _Progress extends StatelessWidget {
  const _Progress(this.done, this.step);
  final double done;
  final String step;

  static const _metal = Color(0xFF9C9C9C);
  static const _light = Color(0xFFDCDCDC);
  static const _dark = Color(0xFF4C4C4C);
  static const _blue = Color(0xFF4E6CFF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Container(
            height: 22,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: _metal,
              border: Border(
                top: BorderSide(color: _light, width: 2),
                left: BorderSide(color: _light, width: 2),
                bottom: BorderSide(color: _dark, width: 2),
                right: BorderSide(color: _dark, width: 2),
              ),
            ),
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: done),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (context, v, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: v.clamp(0.02, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF8FA2FF), _blue, Color(0xFF2B3FB0)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step,
            style: const TextStyle(
              color: Color(0xFF9A9AB8),
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed stars that twinkle, in the scoreboard's star colours, with a few
/// drifting slowly by.
class _Stars extends CustomPainter {
  _Stars(this.time) : super(repaint: time);
  final ValueNotifier<double> time;

  static final _stars = () {
    final r = math.Random(11);
    return [
      for (var i = 0; i < 140; i++)
        (r.nextDouble(), r.nextDouble(), r.nextInt(3), r.nextDouble()),
    ];
  }();
  static const _colors = [
    Color(0xFFFFFFFF),
    Color(0xFF9FB4FF),
    Color(0xFF6E86E8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final p = Paint();
    for (final (x, y, c, phase) in _stars) {
      final twinkle = 0.45 + 0.55 * math.sin(t * 1.7 + phase * 6.3).abs();
      // The nearer (brighter) stars drift a little, for depth.
      final drift = c == 0 ? (t * 0.004 * (1 + phase)) % 1.0 : 0.0;
      final px = ((x - drift) % 1.0) * size.width;
      p.color = _colors[c].withValues(alpha: twinkle);
      final r = c == 0 ? 1.6 : 1.1;
      canvas.drawRect(Rect.fromLTWH(px, y * size.height, r, r), p);
    }
    // A faint violet glow behind the title.
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * 0.55,
      Paint()
        ..shader = ui.Gradient.radial(
          size.center(Offset.zero),
          size.shortestSide * 0.55,
          [const Color(0x332A1B5C), const Color(0x00000000)],
        ),
    );
  }

  @override
  bool shouldRepaint(_Stars old) => false;
}
