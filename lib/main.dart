import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/physics/physics_world.dart';
import 'game/space_cadet_game.dart';
import 'game/ui/overlays.dart';
import 'game/ui/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On a phone the table gets the whole screen; a swipe from the edge
  // brings the system bars back for a moment.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
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
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              // Raw pointers rather than gestures: several fingers at once,
              // no gesture-arena delay on the flippers.
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
                  // The splash screen covers the loading.
                  loadingBuilder: (_) => const SizedBox.shrink(),
                ),
              ),
            ),
            SplashScreen(game: _game),
          ],
        ),
      ),
    );
  }
}
