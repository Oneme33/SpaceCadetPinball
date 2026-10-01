# Space Cadet table — technical analysis

## Source material

Everything below comes from the user's own copy of *3D Pinball for Windows –
Space Cadet* (`original/`, git-ignored, never committed):

| File | Content |
|---|---|
| `PINBALL.DAT` | All table data: bitmaps, z-maps, wall geometry, physics parameters, component list |
| `FONT.DAT` | Bitmap font of the message display |
| `SOUND*.WAV` | Original sound effects |
| `PINBALL.MID`, `PINBALL2.MID` | Music |
| `table.bmp` | The help file's "Pinball Table Components" legend (55 numbered parts) |

The DAT format (`PARTOUT(4.0)RESOURCE`) is documented by the MIT-licensed
decompilation [k4zmu2a/SpaceCadetPinball](https://github.com/k4zmu2a/SpaceCadetPinball).
We use it as a format reference only; our parser is our own code.

A verification parse of `PINBALL.DAT` reads 541 groups and ends exactly at
byte 928 700 (the file size), so the format is understood correctly.

## Coordinate systems

The original does **not** position anything in screen pixels. There are two
spaces, and our game uses the same two:

1. **Table space (physics).** A flat 2D plane in table units. The `table`
   group's own outline is the rectangle x −8…8, y −14…15, so the playfield is
   roughly 16 × 29 units. **+x is screen left, +y points towards the drain**
   (the projection constant d is negative). Gravity from attribute 305 is
   (0, 11.99): 25 × sin(0.5 rad) along +y. All wall polylines (`FloatArray` entries starting
   with `600`) and component positions are in this space. This is what
   Forge2D simulates — the size is ideal for Box2D, so table units map 1:1 to
   Forge2D metres.
2. **Screen space (render).** The pre-rendered art lives in a fixed virtual
   screen: `table_size` = **600 × 416**. The playfield sprite (`table`,
   365 × 470) is drawn at (0, 0); its bottom 54 px (the cabinet stand) fall
   outside the screen, as in the original. The scoreboard sprite
   (`background`, 203 × 394) sits at its own (386, 12). Component sprites are
   drawn at their stored (x, y) minus the table sprite's (137, 2).

The bridge between them is `camera_info`: a 3 × 4 view matrix, then d,
zMin and zScaler. The projection centre (183, 238) is attribute 700 of the
`table` group:

    v  = M · (x, y, z, 1)
    sx = v.x · d / v.z + 183
    sy = v.y · d / v.z + 238

The ball is drawn by projecting its centre at height = radius and picking
one of 7 sprites (9–15 px) by camera distance, so it grows towards the
player. Verified in Phase 2 by drawing every wall from the DAT through this
projection: the lines sit on the art. The z-maps (16-bit depth per pixel, 302 of
them) let sprites occlude the ball correctly, e.g. when it rolls under a ramp.

The whole 600 × 416 screen is scaled uniformly to the device (letterboxed),
so proportions can never distort.

> The spec suggested 720 × 1080 logical units. We deliberately use the
> original's own spaces instead: then every coordinate comes straight from
> the DAT, and nothing has to be traced or re-measured.

## Component inventory (from `table_objects`)

`table_objects` lists every component with its engine type: 340 entries.
The full map with positions is generated into
[ELEMENT_MAP.md](ELEMENT_MAP.md) (`dart run tool/element_map.dart`).

| Type | Count | DAT names | Legend (table.bmp) |
|---|---|---|---|
| Wall | 64 | 45 polygons + 19 circular posts, incl. `v_rebo1–4` | table boundaries, rails; `v_rebo` = 22/49 Rebound (slingshots) |
| FlipperL / FlipperR | 1 + 1 | `a_flip1`, `a_flip2` (geometry in attributes 800–805, not walls) | 24/54 Flipper |
| Plunger | 1 | `plunger` | 51 Plunger |
| Drain | 1 | `drain` | ball drain |
| Bumper | 7 | `a_bump1–7`, grouped as `attack_bumpers` and `launch_bumpers` | 2/32 Attack Bumpers, 15 Launch Bumpers |
| PopupTarget (drop) | 9 | `a_targ1–9` | 6/29 Hazard Target Banks, 40 Booster Targets |
| SoloTarget | 13 | `a_targ10–22` | 1 Fuel, 16 Mission, 35 Medal, 34 Space Warp, 4 Field Multiplier targets |
| Rollover | 17 | `a_roll1–8`, `a_roll110–112`, `a_roll179–184` | 26 Re-Entry Lanes, 11 Launch Lanes, 5 Space Warp Rollover, lane switches |
| LightRollover | 1 | `a_roll9` | |
| Tripwire | 5 | `s_trip1–5` | 19/47 Out Lane, 21/48 Return Lane, 20 Bonus Lane |
| Oneway | 9 | `s_onewy*` | one-way gates in lanes |
| Gate | 2 | `v_gate1–2` | gates |
| Blocker | 1 | `v_bloc1` | TODO: VERIFY (likely the re-deploy/ball-save blocker, 53) |
| Kickback | 2 | `a_kick1–2` | 23/52 Kicker |
| Kickout | 3 | `a_kout1–3` | 9 Black Hole Kickout, 27 Hyperspace Kickout |
| Sink | 4 | `v_sink1–3`, `v_sink7` | 3/28/41 Wormholes (+1, TODO: VERIFY) |
| FlagSpinner | 2 | `a_flag1–2` | 7/33 Flag |
| Ramp / Hole | 2 + 1 | `ramp`, `s_ramp9`, `ramp_hole` | 8 Launch Ramp, 30 Hyperspace Chute |
| Light | 140 | `lite*`, `literoll*` | all inserts (missions, ranks, fuel, progress…) |
| LightGroup | 18 | `worm_hole_lights`, `hyperspace_lights`, `fuel_bargraph`… | 31 Hyperspace Lights, 39 Deployment Lights, 44 Rank Lights, 45 Progress Lights |
| LightBargraph | 1 | `fuel_bargraph` | 10 Fuel Lights |
| TextBox | 2 | `info_text_box`, `mission_text_box` | scoreboard message displays |
| Sound | 30 | `soundwave*` | sound bindings |
| Timer, Demo, ComponentGroup | 1 + 1 + 2 | `demo`, … | attract mode, grouping |

Scoreboard fields: `score1`, `ballcount1`, `player_number1`, `font1`.

The legend → DAT mapping in the right column is inferred from types and
counts. Phase 2 confirms each one by projecting its geometry onto the table
sprite. Anything that does not line up gets a TODO: VERIFY.

## Per-component physics data

Each component carries its original material parameters (`ShortArray`
codes, see `loader.cpp`): smoothness, elasticity, kicker threshold/boost,
collision group and hit sounds. Default elasticity is 0.6. These are imported
as-is, so tuning starts from the original values instead of guesses.

Note that the original used its own collision engine, not Box2D. The values
are the right starting point but will need adjusting to feel the same in
Forge2D (Phase 8).
