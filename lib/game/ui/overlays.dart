import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../space_cadet_game.dart';

/// Flutter overlays: the start and game-over banners and the pause menu.
/// Only for menus: nothing here rebuilds during play.
///
/// Styled after the scoreboard: a bevelled grey metal frame, black recessed
/// panels, white text, values in the blue of the score digits and accents
/// in the red of "BALL".
Map<String, Widget Function(BuildContext, SpaceCadetGame)> overlayBuilders() =>
    {
      SpaceCadetGame.pauseOverlay: (context, game) => _PauseMenu(game: game),
      SpaceCadetGame.gameOverOverlay: (context, game) => _Banner(
        title: 'Game Over',
        hint: 'Press F2 or Enter, or tap, for a new game',
        onTap: game.startGame,
      ),
      SpaceCadetGame.attractOverlay: (context, game) => _Banner(
        title: '3D Pinball — Space Cadet',
        hint: 'Press F2 or Enter, or tap, to start',
        onTap: game.startGame,
      ),
    };

// Colours taken from the scoreboard art.
const _metal = Color(0xFF9C9C9C);
const _metalLight = Color(0xFFDCDCDC);
const _metalDark = Color(0xFF4C4C4C);
const _panel = Color(0xFF000000);
const _white = Color(0xFFF2F2F2);
const _grey = Color(0xFF8A8A8A);
const _blue = Color(0xFF4E6CFF);
const _red = Color(0xFFD42A2A);

const _label = TextStyle(color: _white, fontSize: 14, height: 1.3);
const _small = TextStyle(color: _grey, fontSize: 12, height: 1.3);

class _Banner extends StatelessWidget {
  const _Banner({required this.title, required this.hint, required this.onTap});

  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: const Color(0x99000000),
        child: Center(
          child: _Frame(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: _label.copyWith(fontSize: 20, color: _red),
                ),
                const SizedBox(height: 6),
                Text(hint, textAlign: TextAlign.center, style: _small),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The pause menu and its "How to Play" page.
class _PauseMenu extends StatefulWidget {
  const _PauseMenu({required this.game});
  final SpaceCadetGame game;

  @override
  State<_PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<_PauseMenu> {
  bool _loadingHd = false;
  bool _guide = false;

  SpaceCadetGame get game => widget.game;

  /// Vibration exists on phones only.
  bool get _hasHaptics =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: SafeArea(
        child: Center(
          child: _Frame(
            width: _guide ? 460 : 320,
            child: _guide ? _guidePage() : _menu(),
          ),
        ),
      ),
    );
  }

  Widget _menu() {
    final s = game.settings;
    final hdInstalled = game.hdInstalled;
    final graphics = _loadingHd
        ? 'Loading…'
        : (s.hd && hdInstalled ? 'HD' : 'Classic');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Logo(image: game.scoreboardImage),
        const SizedBox(height: 10),
        Text(
          'GAME PAUSED',
          textAlign: TextAlign.center,
          style: _label.copyWith(color: _red, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        _Row(label: 'Resume', onTap: game.togglePause),
        _Row(label: 'New Game', onTap: game.newGameFromMenu),
        _Row(label: 'How to Play', onTap: () => setState(() => _guide = true)),
        const SizedBox(height: 10),
        _Row(
          label: 'Graphics',
          value: graphics,
          enabled: hdInstalled && !_loadingHd,
          onTap: () async {
            setState(() => _loadingHd = true);
            await game.setHd(!s.hd);
            if (mounted) setState(() => _loadingHd = false);
          },
        ),
        if (!hdInstalled)
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Text('HD graphics not installed', style: _small),
          ),
        _Row(
          label: 'Sound',
          value: s.sound ? 'On' : 'Off',
          onTap: () => setState(() => game.setSound(!s.sound)),
        ),
        if (_hasHaptics)
          _Row(
            label: 'Haptics',
            value: s.haptics ? 'On' : 'Off',
            onTap: () => setState(() => s.haptics = !s.haptics),
          ),
        const SizedBox(height: 8),
        const Text(
          'Esc or P to resume',
          textAlign: TextAlign.center,
          style: _small,
        ),
      ],
    );
  }

  Widget _guidePage() {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'HOW TO PLAY',
          textAlign: TextAlign.center,
          style: _label.copyWith(color: _red, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight - 120),
          child: _Panel(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (title, text) in _guideSections)
                      ..._section(title, text),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Row(label: 'Back', onTap: () => setState(() => _guide = false)),
      ],
    );
  }

  List<Widget> _section(String title, String text) => [
    Text(
      title,
      style: _label.copyWith(color: _blue, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 3),
    Text(text, style: _label.copyWith(fontSize: 13)),
    const SizedBox(height: 12),
  ];
}

/// The guide, written from the rules as ported from the original.
const _guideSections = [
  (
    'Controls',
    'Flippers: Z and / (or Shift, or the arrow keys). Plunger: hold Space, '
        'release to launch; the longer you pull, the harder the shot. Bump '
        'the table with X, . and ↑ — too much and the table tilts. Esc or P '
        'pauses.\n'
        'Touch: left or right half of the screen for the flippers, hold the '
        'plunger lane to pull, tap the scoreboard for this menu.',
  ),
  (
    'Launching',
    'Shoot through the lit launch lane for a Skill Shot, worth up to '
        '75,000. Right after a launch the Re-Deploy light is on: lose the '
        'ball then and you get it back.',
  ),
  (
    'Missions and rank',
    'Hit the mission targets to pick a mission, then shoot the launch ramp '
        'to accept it. The mission box below tells you what to do — hit '
        'bumpers, pass lanes, sink wormholes and more. Completing missions '
        'promotes you, from Cadet all the way to Fleet Admiral.',
  ),
  (
    'Fuel',
    'Missions burn fuel. Roll over the fuel lanes and hit the fuel targets '
        'to refuel ("Ship Re-Fueled"). If the fuel gauge runs out during a '
        'mission, the mission is aborted.',
  ),
  (
    'Weapons and engines',
    'Light all three re-entry lanes at the top to upgrade the attack '
        'bumpers ("Weapons Upgraded") for higher bumper scores. The launch '
        'lanes upgrade the launch bumpers ("Engine Upgraded").',
  ),
  (
    'Hyperspace',
    'Every shot into the hyperspace chute advances the hyperspace lights '
        'for a bigger award each time: 10,000, the jackpot, 20,000, 50,000 '
        'and finally 150,000 with the gravity well.',
  ),
  (
    'Field multiplier',
    'Knock down the drop targets at the top to raise the field multiplier: '
        '2×, 3×, 5× and 10× on everything you score.',
  ),
  (
    'And more',
    'Wormholes send the ball to another wormhole. The black hole is worth '
        '20,000 and the medal targets give commendations of 1,500, 10,000 '
        'and 50,000. Roll through a lit outlane for an extra ball, through '
        'the lit bonus lane to collect your bonus, and every drained ball '
        'pays a crash bonus.',
  ),
];

/// The scoreboard's "3D Pinball Space Cadet" logo, from the original art.
class _Logo extends StatelessWidget {
  const _Logo({required this.image});
  final ui.Image? image;

  /// The logo and the cadet, above the BALL counter (classic pixels of the
  /// 203-wide scoreboard).
  static const _src = Rect.fromLTWH(8, 8, 187, 108);

  /// The same area in the HD image, which is larger.
  static Rect _scaled(ui.Image img) {
    final k = img.width / 203;
    return Rect.fromLTRB(
      _src.left * k,
      _src.top * k,
      _src.right * k,
      _src.bottom * k,
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = image;
    if (img == null) {
      return Text(
        '3D Pinball — Space Cadet',
        textAlign: TextAlign.center,
        style: _label.copyWith(fontSize: 18),
      );
    }
    return _Panel(
      child: AspectRatio(
        aspectRatio: _src.width / _src.height,
        child: CustomPaint(painter: _ImagePainter(img, _scaled(img))),
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.image, this.src);
  final ui.Image image;
  final Rect src;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      src,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_ImagePainter old) => old.image != image;
}

/// The scoreboard's grey metal frame: raised bevel around a dark body.
class _Frame extends StatelessWidget {
  const _Frame({required this.child, required this.width});
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: width),
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: _metal,
        border: Border(
          top: BorderSide(color: _metalLight, width: 3),
          left: BorderSide(color: _metalLight, width: 3),
          bottom: BorderSide(color: _metalDark, width: 3),
          right: BorderSide(color: _metalDark, width: 3),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Container(
        color: const Color(0xFF15151A),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: child,
      ),
    );
  }
}

/// A recessed black panel like the score boxes.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: _panel,
      border: Border(
        top: BorderSide(color: _metalDark, width: 2),
        left: BorderSide(color: _metalDark, width: 2),
        bottom: BorderSide(color: _metalLight, width: 2),
        right: BorderSide(color: _metalLight, width: 2),
      ),
    ),
    child: child,
  );
}

/// A menu row: a recessed panel with a label and optionally a value.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.onTap,
    this.value,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: _Panel(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onTap : null,
          hoverColor: const Color(0x223C5CFF),
          splashColor: const Color(0x333C5CFF),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: _label.copyWith(color: enabled ? _white : _grey),
                  ),
                ),
                if (value case final v?)
                  Text(
                    v,
                    style: _label.copyWith(
                      color: enabled ? _blue : _grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
