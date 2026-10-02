# Flutter-gids voor dit project

Voor wie React, Angular of React Native kent en dit project wil begrijpen.
Eerst de Flutter-basis naast wat je al kent, daarna hoe Space Cadet in
elkaar zit, en tot slot waar je wat aanpast.

## 1. Flutter in vergelijking

| Flutter / Dart | Wat je al kent |
|---|---|
| **Dart** | TypeScript-achtig: getypeerd, `async`/`await`, klassen, null-safety (`String?` mag null zijn, `String` niet). Compileert naar native code (Android/iOS/desktop) en naar JavaScript/WebAssembly (web). |
| **Widget** | Component. Alles op het scherm is een widget, ook marges (`Padding`), uitlijning (`Center`) en lay-out (`Row` ≈ flex-row, `Column` ≈ flex-column, `Stack` ≈ position: absolute boven elkaar). |
| **`StatelessWidget`** | Functiecomponent zonder state: alleen props in, `build()` geeft de UI terug (≈ `render`). |
| **`StatefulWidget` + `State`** | Component met state. `setState(() { … })` ≈ `setState`/`useState`-setter: zet de waarde en laat `build()` opnieuw lopen. `initState` ≈ `componentDidMount`/`useEffect(…, [])`, `dispose` ≈ cleanup. |
| **`build(BuildContext context)`** | De render-functie. `context` geeft toegang tot de boom erboven, zoals `MediaQuery.sizeOf(context)` (schermgrootte) — vergelijkbaar met React-context. |
| **`ValueNotifier` / `ValueListenableBuilder`** | Een kleine observable met een component die erop rendert (≈ een store + `useSyncExternalStore`). Gebruikt voor de laadbalk. |
| **`pubspec.yaml`** | `package.json`: naam, versie, dependencies, en welke bestanden als **assets** mee de app in gaan. `flutter pub get` ≈ `npm install`. |
| **`lib/main.dart`** | Het entrypoint (`index.tsx`). `runApp(...)` ≈ `ReactDOM.createRoot(...).render(...)`. |
| **Hot reload** (`r` in `flutter run`) | Fast refresh: code verandert, state blijft. |
| **`flutter analyze`** | ESLint + `tsc --noEmit`. |
| **`flutter test`** | Jest. Tests staan in `test/`, `expect(waarde, matcher)`. |

**Belangrijk verschil met React:** er is geen virtuele DOM en geen HTML.
Flutter tekent elke pixel zelf (op het web op een `<canvas>`). Daardoor ziet
de app er op elk platform hetzelfde uit.

## 2. Een spel bovenop Flutter

Een pinballspel ververst 60 keer per seconde en past niet in "state
verandert → opnieuw renderen". Daarom gebruikt dit project twee extra lagen:

- **Flame** — een game-engine op Flutter. Het spel is een `FlameGame`
  (`SpaceCadetGame`) met een **game loop**: elke frame `update(dt)`
  (logica) en `render(canvas)` (tekenen). Daarin zitten **componenten**
  (≈ scene-objecten, niet te verwarren met React-componenten): de tafel-art,
  de sprites, de bal, het scorebord. Een **camera** bepaalt welk stuk van de
  wereld je ziet.
- **Forge2D** — Box2D (de bekende 2D-physics-engine) voor Dart. Hierin
  bewegen de bal en de flippers; muren zijn statische vormen.

Flutter-widgets doen alleen wat er **boven** het spel ligt: het menu, de
telefoonbalk, de splash. Die heten in Flame **overlays** en worden aan- en
uitgezet met `overlays.add('pause')` / `overlays.remove(...)`.

```
main.dart  (Flutter-app)
 └─ Stack
     ├─ GameWidget  ← het Flame-spel (canvas)
     │    ├─ SpaceCadetGame  (game loop, camera)
     │    │    ├─ TableArt, ComponentSprite, FlipperSprite, BallsComponent, Scoreboard …
     │    │    └─ physics: SpaceCadetTable → Forge2D-wereld
     │    └─ overlays (Flutter-widgets): pauzemenu, telefoonbalk, banners
     └─ SplashScreen  (Flutter-widget, tot alles geladen is)
```

## 3. Hoe het spel werkt, laag voor laag

**Twee coördinatenstelsels.**
- *Tafelruimte*: de eenheden uit `PINBALL.DAT`, ongeveer x −8…8 en y −14…15,
  waarbij +y richting de drain wijst. Hier rekent de physics.
- *Schermruimte*: het originele venster van 600 × 416 pixels. Hier wordt
  getekend.

`CameraProjection` rekent tussen de twee met de camera-gegevens uit de DAT.

**Elke frame (vereenvoudigd):**
1. `SpaceCadetGame.update(dt)` laat de timers en tekstvakken lopen.
2. `PhysicsWorld.advance(dt)` doet zoveel vaste stappen van 1/240 seconde
   als er in `dt` passen (`fixed_step.dart`), zodat de physics overal even
   snel loopt, ook als het scherm haperend ververst.
3. Per stap:
   - `beforeStep`: flippers zetten, krachten op de bal (zwaartekracht van
     ramps, de velden van kickouts);
   - Forge2D lost de botsingen op;
   - `afterStep`: de botsing krijgt de **originele terugkaats-formule**
     (`original_collision.dart`), daarna gaan de sensoren af (rollovers,
     wormholes, de drain).
4. Onderdelen die geraakt worden, sturen een **bericht** (`PartEvent`) naar
   de regels (`OriginalRules.handler`). De regels zetten lampjes, scores en
   missies, net als `control.cpp` van het origineel.
5. `render`: Flame tekent de art, de sprites (frame per toestand), de bal
   (met diepte via de z-map) en het scorebord.

## 4. De mappen

```
lib/
  main.dart                 app-start, Stack met spel + splash
  dat/                      PINBALL.DAT inlezen (formaat, bitmaps, palet, teksten uit Pinball.exe)
  game/
    space_cadet_game.dart   het hart: laden, game loop, invoer, camera, overlays
    game_config.dart        vaste waarden (schermgrootte, physics-stap)
    game_state.dart         toestandsmachine: attract → playing → paused → gameOver
    settings.dart           instellingen (HD, geluid, muziek, easy mode, highscores) via shared_preferences (≈ localStorage)
    graphics.dart           klassiek of HD tekenen
    assets/                 de originele bestanden laden en decoderen
    audio/                  geluidseffecten en muziek (flutter_soloud)
    physics/                bal, flippers, plunger, muren, de originele botsingsformules
    table/                  de tafel: alle onderdelen (parts/), camera-projectie, sprites, de bal tekenen
      parts/                bumpers, targets, ramps, kickouts, lampjes … elk onderdeel van de DAT als klasse
    rules/                  de originele regels (original_rules_port.dart is control.cpp, geport), score
    gameplay/               timers, aanstoten/tilt
    input/                  toetsen en acties
    feedback/               trillen (haptics)
    ui/                     overlays (menu), telefoonbalk, splash, schermindeling, scorebord, de vliegende cadet
    debug/                  debug-weergave van de physics
test/                       unit- en integratietests (flutter test)
tool/                       scripts: originelen installeren, HD maken, muziek opnemen, icoon, APK, site, vergelijken met het origineel
site/                       de website (gewone HTML/CSS/JS)
docs/                       documentatie
android/, web/              platform-specifieke schil (manifest, icoon, index.html)
assets/original/            jouw originele spelbestanden (niet in git)
```

## 5. Waar pas je wat aan?

| Wil je… | Kijk in |
|---|---|
| het menu veranderen | `lib/game/ui/overlays.dart` (`_PauseMenu`, `_Row`, de kleuren bovenaan) |
| de telefoonbalk of de camera op de telefoon | `overlays.dart` (`_PhoneHud`), `ui/screen_layout.dart`, `_followBall` in `space_cadet_game.dart` |
| de splash | `lib/game/ui/splash.dart` |
| een instelling toevoegen | `settings.dart` (opslaan), `overlays.dart` (knop), `space_cadet_game.dart` (toepassen) |
| hoe de bal stuitert | `physics/original_collision.dart` (de originele formules) |
| flippers (lengte, kracht) | `physics/flipper.dart`, easy mode in `setEasy` (`space_cadet_game.dart`) |
| wat een bumper of target doet | `table/parts/solid_parts.dart` en `sensor_parts.dart` |
| de regels en missies | `rules/original_rules_port.dart` (geport, liever niet zomaar aan komen) |
| de website | `site/` |

## 6. Dagelijks gebruik

```bash
flutter pub get                    # dependencies installeren
flutter run -d chrome              # starten in Chrome, met hot reload (r) en hot restart (R)
flutter run                        # op een aangesloten Android-telefoon
flutter analyze                    # lint + typecheck
flutter test                       # alle tests
tool/release_apk.sh                # APK bouwen en zippen in dist/
tool/deploy_site.sh                # site bouwen en op space-cadet.nl zetten
```

## 7. Dart in een notendop

```dart
// Klasse met constructor-shorthand (≈ TypeScript parameter properties).
class Bumper {
  Bumper(this.x, this.y, {this.boost = 17});   // {…} = benoemde parameters
  final double x, y;                            // final ≈ readonly
  final double boost;

  double distanceTo(double px, double py) =>    // => ≈ arrow function
      math.sqrt((px - x) * (px - x) + (py - y) * (py - y));
}

// Records en pattern matching (≈ tuples en destructuring).
final (score, ball) = (64250, 2);
final label = switch (ball) { 1 => 'eerste', _ => 'bal $ball' };

// Null-safety.
String? text;            // mag null zijn
print(text ?? 'leeg');   // ?? zoals in TypeScript
text?.length;            // optional chaining

// Async.
Future<void> load() async {
  final bytes = await rootBundle.load('assets/original/PINBALL.DAT');
}

// Cascade: meerdere aanroepen op hetzelfde object (geen equivalent in TS).
ball
  ..placeAt(0, 0)
  ..layers = 1;
```

Goede startpunten om te lezen: `main.dart`, dan `onLoad` en `update` in
`space_cadet_game.dart`, dan een eenvoudig onderdeel zoals `BumperPart` in
`solid_parts.dart`.
