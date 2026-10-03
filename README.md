# 3D Pinball — Space Cadet (Flutter recreation)

A from-scratch recreation of *3D Pinball for Windows – Space Cadet* in
Flutter + Flame + Forge2D (native Box2D v3), for web and Android.

The original artwork, sounds and table data are **not** part of this
repository. Put your own copy of the game files in `original/` (git-ignored)
and install them; see [docs/ASSETS.md](docs/ASSETS.md):

```bash
dart run tool/install_originals.dart original/
```

This also reads the game's messages and the bitmap font of the message
boxes (`PBMSG_FT`, the dotted letters) from your `Pinball.exe` (put it in
`original/` too). Without the originals the game runs with labelled
placeholders.

## Run

```bash
flutter run -d chrome                               # web
flutter run -d chrome --dart-define=SC_DEBUG=true   # with debug overlay
flutter run -d <android-device>                     # Android
flutter test
flutter analyze
```

Controls: **Z / Left Shift** left flipper, **/ / Right Shift** right flipper,
**Space** plunger, **X / . / ↑** bump the table (left, right, front),
**Esc / P** pause menu, **F2 / Enter** start.

Touch: left or right half of the screen works that flipper (several fingers
at once), the plunger lane pulls the plunger, the scoreboard is the menu
button (pause).

## HD graphics

The pause menu switches between **Classic** (the original pixels) and
**HD**: every bitmap of the DAT upscaled 4× with Real-ESRGAN, drawn into
exactly the same rectangles, so the game plays identically. The table and
its parts use the general model (realesrgan-x4plus); the scoreboard's
cartoon art uses the anime model, which keeps the logo and the cadet crisp.
The small lamps and the ball are not left to ESRGAN, which turns a lamp of
a few pixels into a rectangle and the small balls square: round lamps are
redrawn as smooth ellipses with their own radial colour profile (bright
core, dark rim), other small lamps use xBRZ (made for pixel art), and the
ball keeps its own picture, smoothly scaled and cut to an exact circle
(`tool/hd_small_sprites.py`, needs `pip install xbrz.py Pillow`).
The score digits stay classic in both modes. Make the HD set from your installed originals:

```bash
dart run tool/make_hd.dart --esrgan path/to/realesrgan-ncnn-vulkan
```

Real-ESRGAN comes from https://github.com/xinntao/Real-ESRGAN (release
v0.2.5.0, `realesrgan-ncnn-vulkan` for your platform). The result lands in
`assets/original/hd/` and, like the originals, stays out of git.

## Music

The original plays `PINBALL.MID` through the Windows MIDI synthesizer;
the app has none, so the installed MIDI is recorded once:

```bash
tool/music/render.sh
```

TinySoundFont (MIT) plays it with the GeneralUser GS SoundFont (free to
use), both downloaded into `tool/music/.cache/`; `lame` makes
`assets/original/music.mp3` of it (a WAV without lame). Like the
originals it stays out of git. As in the original the music starts with a
game, loops (through game over), and stops on pause or when the app loses
focus; it then continues where it was instead of starting over. Sound
effects and music switch on and off apart in the menu. (`PINBALL2.MID` is
no music: it is a bitmap font in MIDI clothing.)

## Website

`site/` is a landing page in the game's style: play in the browser (the
game loads only when asked for; phones go to the full-screen version), the
Android download, and a support button that appears once a link is set in
`site/config.js`. Put it together and try it locally:

```bash
tool/release_apk.sh            # newest APK into dist/
tool/build_site.sh --serve     # build/site/, on http://localhost:8124
```

`build/site/` holds the game with its original files, so it stays out of
git.

It runs at space-cadet.nl on the Lukraak server (Apache, like the other
sites there): set up once with `tool/server/setup_space_cadet.sh` (sudo;
run it again for HTTPS once the DNS points to the server), then publish
with `tool/deploy_site.sh` (builds and rsyncs to
`/var/www/space-cadet.nl/www`, no sudo).

## Pause menu and settings

Esc, P, a tap on the scoreboard or the menu button of the phone bar opens
it: resume, new game, a "How to
Play" guide (written from the ported rules), the high scores (normal and
easy), mode (Normal/Easy), graphics
(Classic/HD), sound and music on/off (side by side) and, on phones,
haptics on/off. It is styled
after the scoreboard. Settings and the high score tables are kept between
sessions.

At the top the cadet flies through the stars in his space car, each pass
a random one: in from the left or right, or diagonally from above or
below, near and large or far and small (slower), or coming closer or
moving away, and always out at the far side, so he never turns round in
sight. The car is cut out of the scoreboard art (classic or HD,
whichever is on). The
logo letters behind his see-through dome are replaced by a glass tint and
the dome's rim. The loop stands still when the system asks for reduced
motion.

### Easy mode

Not original, for a relaxed game:

- the "easy mode" cheat of the decompilation (control.cpp): the centre post
  between the flippers stays up for good and the kickback gates stay open,
  so both outlanes kick the ball back every time;
- flippers 1.25× as long (physics and sprite, scaled about the pivot), so
  together with the post the gap between the flippers is closed. A ball
  that slips past a kickback can still drain, but rarely does.

Turning it on during a game marks that game as an easy game: its score goes
to a separate easy high score table.

## Screen layout

- **Desktop and landscape:** the original window, playfield left and
  scoreboard right, letterboxed.
- **Phones held upright:** the playfield at the full height of the screen,
  under a slim bar with ball and score, the two message boxes and a menu
  button. The playfield is wider than the screen then, so the view slides
  sideways after the ball nearest the flippers, keeping it in the middle
  part of the screen, and rests on the plunger lane when a ball waits
  there. The halves of the screen are the flippers; with a ball on the
  plunger the right half pulls it. The app runs full screen (a swipe from
  the edge shows the system bars).

A splash screen (starfield, title, a progress bar in the scoreboard's
metal) covers the loading on every platform; the Android launch screen and
the web page start black, so nothing flashes white before it.

## Architecture

```
lib/
  main.dart                     app shell, GameWidget, overlays
  dat/                          PINBALL.DAT parser: groups, bitmaps, z-maps, palette, components, walls
  game/
    assets/original_assets.dart loads and decodes the user's originals
    space_cadet_game.dart       wires input, state, physics and rendering
    game_config.dart            coordinate spaces, timing, debug flag
    game_state.dart             pure state machine (loading → attract → playing ⇄ paused → ballLost → gameOver)
    input/input_bindings.dart   key bindings, multi-source held state
    gameplay/                   pure Dart: ball count, game timers
    rules/
      score_manager.dart        AddScore: multipliers 1/2/3/5/10, jackpot, bonus
      message_code.dart         the original MessageCode values
      original_rules.dart       game flow (TPinballTable::Message), helpers
      original_rules_port.dart  control.cpp, ported function by function
    audio/audio_manager.dart    original WAVs via flutter_soloud, 8 voices
    physics/
      physics_world.dart        Box2D world in table space, before/after-step hooks
      fixed_step.dart           frame-rate independent fixed step (240 Hz)
      collision.dart            collision layers, original material → Box2D
      table_walls.dart          static walls from the DAT as one-sided chains
      ball.dart                 sliding ball with the original field effect
      flipper.dart              kinematic flippers from attributes 800–805
      plunger.dart              plunger pullback/launch, drain line
    table/
      space_cadet_table.dart    the physical table: flippers, plunger, drain, balls, parts
      parts/                    every DAT component at runtime (TBumper, TRamp, … counterparts)
        part.dart               base, events to the rules, kicker, one-sided trigger lines
        solid_parts.dart        walls/slingshots, bumpers, drop and solo targets, gates,
                                centre post, kickbacks, one-way walls
        sensor_parts.dart       rollovers, tripwires, spinners, kickouts, wormholes, ramp hole
        ramp_part.dart          ramps: planes, slope gravity, layer changes, ball height
        light_part.dart         TLight: on/off, timed, flashing (900/901)
        group_parts.dart        TLightGroup, TLightBargraph (fuel), TComponentGroup, TSound
        table_proxies.dart      drain, plunger, flippers, message boxes as the rules see them
      table_layout.dart         element map in table space
      table_sprites.dart        component sprites, balls, placeholder parts
      table_projection.dart     table space → screen space (interface + flat fallback)
      camera_projection.dart    the original perspective camera
      table_art.dart            playfield and scoreboard art
      ball_renderer.dart        ball sprite by depth, z-buffered against the table depth map
      placeholder_table.dart    labelled stand-in without originals
    debug/debug_layer.dart      collision shapes, click-to-spawn
    ui/                         screen layout, scoreboard (original digits), message
                                boxes (TTextBox queue), debug HUD, Flutter overlays
docs/
  TABLE_ANALYSIS.md             what PINBALL.DAT contains and how we use it
  ELEMENT_MAP.md                generated: every component with position and physics
  ASSETS.md                     asset rules and status
```

Two coordinate spaces, both taken from the original:

- **Table space**: the flat physics plane in original table units
  (x −8…8, y −14…15). One unit is one Box2D metre. +x is screen left, +y
  points towards the drain.
- **Screen space**: the original 600 × 416 virtual screen, scaled
  uniformly with letterboxing.

Gameplay rules (Phase 5–6) will be pure Dart that reacts to physics
events, so they can be tested without rendering.

### Physics values taken from the original

| What | Value | Source |
|---|---|---|
| Gravity | (0, 11.99) | `table` attribute 305 |
| Speed braking | 0.2 × speed, plus random sideways push | attribute 701, `TTableLayer::FieldEffect` |
| Ball radius, top speed | 0.3, 60 (200 radii/s) | `ball` 500, `pb::BallMaxSpeed` |
| Flippers | pivot, tip radii, 0.04 s up, 0.08 s down | attributes 800–805 |
| Plunger | +1 per 25 ms up to 100, +0–10 % random | `TPlunger` |
| Rebound | the original's own response per hit, from elasticity/smoothness | `maths::basic_collision`, materials (300 → 301/302) |
| Flipper hit | rebound + collisionMult · ω · (distance ÷ length) along the normal | `TFlipperEdge::EdgeCollision` |
| Next ball | 1.82 s after drain + 0.96 s feed | `drain` 407, `TPlunger` |
| Kickers | per component threshold and boost (bumpers 17/12, slingshots 18, targets 5, kickbacks 55) | kicker groups (400 → 401/402) |
| Ramps | 18 + 2 planes with slope gravity, layer 1 → 2 → 4 | `ramp`, `s_ramp9` (1300–1305) |

### Table components (Phase 4)

Every gameplay component in the DAT has a runtime part with the original
behaviour: kick on a hard enough hit, drop and pop-up, light and timer,
capture and throw. Sensors are one-sided trigger lines and areas exactly
as in the original (a line fires only when crossed from its normal side;
`createWall` lines are offset by the ball radius), not Box2D sensors.

Every part reports to the rules what the original reports to
`control::handler` (collision, ball captured/released, timer expired,
spinner loop). The rules themselves are Phase 6; until then parts use
their own defaults.

### Scoreboard, sound and lights (Phase 5)

- Score, ball and player number use the original digit sprites
  (`score1`, `ballcount1`, `player_number1`); `FONT.DAT` holds the same
  ten digits.
- Message boxes follow `TTextBox`'s queue. 3D Pinball drew their text
  with the Windows system font in white; that font is not part of the game
  files, so a plain sans-serif stands in (TODO: verify size and face).
- Every sound comes from the DAT's own references: hard/soft hit sounds
  per component, flipper up/down, plunger pull/release/feed, game start and
  game over. Sounds start on the first key or touch (browser rule).
- Your copy of the game lacks six referenced WAVs (SOUND2, 37, 44, 52, 59,
  62: e.g. game over and the plunger pull). They stay silent; nothing is
  substituted.
- All 140 lights work as `TLight` (on/off, timed, flashing). What lights
  them is the rules' job: so far only the slingshot lights.

### The rules (Phase 6)

`control.cpp` from the decompilation is ported in full: all 88 component
control functions, `MissionControl` and the mission controllers (17
missions, 9 ranks), fuel, hyperspace, wormholes, the gravity well,
re-deploy (ball save), extra balls, bonus, jackpot, multipliers and the
ball drain sequence. The port was made with a one-off translator for the
regular patterns (`X->Message(MessageCode::Y, v)` → `X.message(MC.y, v)`),
then fixed by hand where C++ and Dart differ; names follow the original so
the two can be compared side by side.

Components talk to the rules through the original's message codes
(`MC`): every part has `message(code, value)` and its `messageField`, and
reports events the way the original calls `control::handler`. The game
flow is the original's too: `NewGame` → light show (as long as the start
sound) → "Player 1" → ball feed; the drain → `BallDrainControl` →
re-deploy, shoot again, next ball or game over.

Messages come from the user's own Pinball.exe (`STRINGnnn` = resource id
nnn − 101), extracted by the install tool.

### Phase 7

- **Tilt**: bumping the table as `nudge.cpp` (±1, 0.5 velocity, a 2 px
  view shift, undone after 0.4 s); "Danger" above 0.5, TILT above 1:
  flippers dead, no kicks or scoring, wormholes drain, all balls drain
  after 30 s.
- **Stuck ball**: the original rescue (`UnstuckBall`): small random pushes,
  relaunch after 20 checks; balls may rest by the flippers and plunger.
- **High scores**: top five kept; game over shows them as the original's
  `GameoverController` does. Names are not asked.
- **Haptics** (phones): light for targets and rollovers, medium for
  bumpers, slingshots and bumps, strong for flipper hits, launches and
  special awards; rate-limited, never continuous.

Not yet: more than one player, the attract-mode demo, and bumping the
table on touch screens.

### Phase 8: measured against the original

The decompiled original runs headless next to the port (`tool/compare/`,
see its README): same scenarios, same PINBALL.DAT, ball tracks side by
side. What that showed and changed:

- **Collision response.** Box2D's restitution and friction are not the
  original's. In 3D Pinball a ball sliding along a wall loses nothing
  (smoothness only steers the rebound) and an oblique hit loses
  (1 − elasticity) of its approach. Box2D now only keeps the ball out of
  the walls; every hit gets the original's `basic_collision`, flipper hits
  `TFlipperEdge::EdgeCollision` with its boost, ball against ball
  `TBall::EdgeCollision`. Flipper shots went from 17/20/25 to 20/33/44
  (early, mid, late flip; the original gives 18–22/25–32/46–52 between 60
  and 240 Hz), and a ball rolling down a flipper now does so at the
  original's speed.
- **Stuck ball.** The rescue pushed a slow ball every frame and relaunched
  it after a third of a second (the original's next frame sees the push
  and waits another half second). Now a push per half second standing
  still, a relaunch after about ten seconds, as the original.
- **Passing through lines.** The original moves a ball in rays of half
  its radius; a line it passes through (ramp edges, rollovers,
  tripwires, spinners, one-way walls) ends the ray, and the next starts
  at full length, so the ball gains the distance to the line once more.
  Copied (`TablePart.passThrough`): ramp shots now reach the upper level
  at the original's moment (0.15 s vs 0.15 s at speed 35), a weak shot
  (20) makes it as in the original, and ramp tracks stay together for
  0.6–1.3 s instead of 0.03–0.4 s.
- **Matching:** gravity and braking (free fall within 0.13 after 1 s),
  slingshots (19.0 vs 18.8), bumpers (20.7 vs 20.7 head-on), the plunger
  (full and short pulls), kickouts (held 0.22–1.72 s in both, thrown at
  34.6), wormholes and kickbacks (together for 1–2.4 s).
- **Original's own quirk, not copied:** at 120 Hz about a third of very
  short plunger taps do not launch at all (the ball is mid-bounce during
  the 25 ms window); at 240 Hz none miss.

Tracks still part after 0.5–2 s, as two runs of any pinball do: near two
bumpers a hundredth of a second decides the next bounce.

### Open points to check against the original

- A ramp shot that only just makes the top can come to rest on the upper
  level.
- A weak plunge leaves the lane half way through a one-way wall.

## Phases

| Phase | Content | Status |
|---|---|---|
| 1 | Project, architecture, fixed-step physics, state machine, input, debug mode | done |
| 2 | DAT parser, table art, camera projection, element map | done |
| 3 | Ball, walls, drain, flippers, plunger — first playable | done |
| 4 | Bumpers, slingshots, lanes, targets, ramps, sensors | done |
| 5 | Scoring, scoreboard, sound, lights | done |
| 6 | Space Cadet rules and missions | done |
| 7 | HD graphics, menu, haptics, tilt, high scores, stuck ball | done |
| 8 | Tuning against the original | done: collision response, stuck ball, pass-through lines |
