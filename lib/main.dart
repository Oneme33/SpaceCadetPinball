import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/physics/physics_world.dart';
import 'game/space_cadet_game.dart';
import 'game/ui/overlays.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhysicsWorld.initialize();
  runApp(const SpaceCadetApp());
}

class SpaceCadetApp extends StatefulWidget {
  const SpaceCadetApp({super.key});

  @override
  State<SpaceCadetApp> createState() => _SpaceCadetAppState();
}

class _SpaceCadetAppState extends State<SpaceCadetApp> {
  // Created once, so rebuilds of this widget never recreate the game.
  final _game = SpaceCadetGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3D Pinball — Space Cadet',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        // Raw pointers rather than gestures: several fingers at once, no
        // gesture-arena delay on the flippers.
        body: SafeArea(
          child: Listener(
            onPointerDown: (e) {
              // Browsers only allow audio after a user gesture.
              if (_game.isLoaded) _game.audio.start();
              _game.handlePointer(e);
            },
            onPointerUp: _game.handlePointer,
            onPointerCancel: _game.handlePointer,
            child: GameWidget<SpaceCadetGame>(
              game: _game,
              autofocus: true,
              overlayBuilderMap: overlayBuilders(),
              loadingBuilder: (_) => const Center(
                child: Text(
                  'Loading…',
                  style: TextStyle(
                    color: Color(0xFFB0B0D0),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
