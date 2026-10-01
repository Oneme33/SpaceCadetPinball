import 'package:flutter/material.dart';

import '../space_cadet_game.dart';

/// Flutter overlays. Only for menus and pause: nothing here rebuilds during
/// play.
Map<String, Widget Function(BuildContext, SpaceCadetGame)> overlayBuilders() =>
    {
      SpaceCadetGame.pauseOverlay: (context, game) => _Banner(
        title: 'Game Paused',
        hint: 'Press Esc or P, or tap, to resume',
        onTap: game.togglePause,
      ),
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

/// TODO: replace with the original's look once FONT.DAT is decoded
/// (Phase 5). Plain on purpose until then.
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
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFC040),
                  fontSize: 24,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hint,
                style: const TextStyle(
                  color: Color(0xFFB0B0D0),
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
