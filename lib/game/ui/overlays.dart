import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../space_cadet_game.dart';

/// Flutter overlays. Only for menus and pause: nothing here rebuilds during
/// play.
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

const _title = TextStyle(
  color: Color(0xFFFFC040),
  fontSize: 22,
  fontFamily: 'monospace',
);
const _hint = TextStyle(
  color: Color(0xFFB0B0D0),
  fontSize: 13,
  fontFamily: 'monospace',
);
const _panel = Color(0xF0100C24);
const _border = Color(0xFF6A5ACD);
const _text = Color(0xFFE8E4FF);
const _muted = Color(0xFF7A7690);
const _value = Color(0xFFFFC040);

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: _title, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(hint, style: _hint, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pause menu: resume, new game and the settings.
class _PauseMenu extends StatefulWidget {
  const _PauseMenu({required this.game});
  final SpaceCadetGame game;

  @override
  State<_PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<_PauseMenu> {
  bool _loadingHd = false;

  SpaceCadetGame get game => widget.game;

  /// Vibration exists on phones only; on the web it is ignored anyway.
  bool get _hasHaptics =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final s = game.settings;
    final hdInstalled = game.hdInstalled;
    final graphics = _loadingHd
        ? 'Loading…'
        : (s.hd && hdInstalled ? 'HD' : 'Classic');
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          decoration: BoxDecoration(
            color: _panel,
            border: Border.all(color: _border, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Game Paused',
                style: _title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              _Button('Resume', game.togglePause),
              _Button('New Game', game.newGameFromMenu),
              const Divider(color: _border, height: 22),
              _Toggle(
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
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('HD not installed', style: _hint),
                ),
              _Toggle(
                label: 'Sound',
                value: s.sound ? 'On' : 'Off',
                onTap: () => setState(() => game.setSound(!s.sound)),
              ),
              if (_hasHaptics)
                _Toggle(
                  label: 'Haptics',
                  value: s.haptics ? 'On' : 'Off',
                  onTap: () => setState(() => s.haptics = !s.haptics),
                ),
              const SizedBox(height: 8),
              const Text(
                'Esc or P to resume',
                style: _hint,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: _text,
        side: const BorderSide(color: _border),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 15),
      ),
      onPressed: onTap,
      child: Text(label),
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: _hint.copyWith(
                fontSize: 15,
                color: enabled ? _text : _muted,
              ),
            ),
          ),
          Text(
            value,
            style: _hint.copyWith(
              fontSize: 15,
              color: enabled ? _value : _muted,
            ),
          ),
        ],
      ),
    ),
  );
}
