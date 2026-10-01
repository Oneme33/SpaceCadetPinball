# 3D Pinball — Space Cadet (Flutter recreation)

A from-scratch recreation of *3D Pinball for Windows – Space Cadet* in
Flutter + Flame + Forge2D (native Box2D v3), for web and Android.

The original artwork, sounds and table data are **not** part of this
repository. Put your own copy of the game files in `original/` (git-ignored)
and install them; see [docs/ASSETS.md](docs/ASSETS.md):

```bash
dart run tool/install_originals.dart original/
```

Without them the game runs with labelled placeholders.

## Run

```bash
flutter run -d chrome                               # web
flutter run -d chrome --dart-define=SC_DEBUG=true   # with debug overlay
flutter run -d <android-device>                     # Android
flutter test
flutter analyze
```

Controls: **Z / Left Shift** left flipper, **/ / Right Shift** right flipper,
**Space** plunger, **Esc / P** pause, **F2 / Enter** start.

Touch: left or right half of the screen works that flipper (several fingers
at once), the plunger lane pulls the plunger, the scoreboard is the menu
button (pause).

## Screen layout

- **Landscape / desktop**: the original window — playfield left,
  scoreboard right — scaled uniformly and letterboxed.
- **Portrait (phones, the default way to hold them)**: scoreboard on top,
  playfield at the bottom filling the width, so the flippers sit under the
  thumbs and the scoreboard (the menu button) is out of their way. Tall
  screens show the whole scoreboard with its logo; shorter ones show it from
  the BALL counter down. Nothing is ever stretched.

See `lib/game/ui/screen_layout.dart`.

Debug mode shows FPS, physics rate, game phase, held inputs, ball speed and
the table coordinates under the pointer. It draws every wall from the DAT
over the art (**G** toggles) and spawns a test ball wherever you click.

Tools:

```bash
dart run tool/dat_info.dart       # summary of PINBALL.DAT
dart run tool/element_map.dart    # regenerates docs/ELEMENT_MAP.md
```

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
      control.dart              control.cpp, ported function by function
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
| Wall restitution, friction | per wall from elasticity/smoothness | materials (300 → 301/302) |
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

### Open points to check against the original

- Kickouts hold the ball for their default 1.5 s; the rules set this per
  mission (Phase 6).
- Wormholes give the ball back from the same sink; the rules pick another
  one (Phase 6).
- Gates start closed and the centre post down; the rules open and raise
  them (Phase 6). Until then a ball in an outlane drains.
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
| 6 | Space Cadet rules and missions | next |
| 7 | Animation, haptics, mobile controls | |
| 8 | Tuning against the original | |
