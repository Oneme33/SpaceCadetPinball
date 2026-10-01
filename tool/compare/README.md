# Comparing with the original

Phase 8 measures this port against the decompiled original
([k4zmu2a/SpaceCadetPinball](https://github.com/k4zmu2a/SpaceCadetPinball),
MIT): both play the same scripted scenarios on the user's own PINBALL.DAT,
and the ball tracks are laid side by side.

- `scenarios.txt`: the scenarios (ball placement, flipper and plunger
  input at given times).
- `harness/`: a headless `main` for the decompilation, a silent SDL_mixer
  stand-in and a build script. The random sideways push of the table field
  is off in both, so runs repeat exactly.
- `scenarios_test.dart`: plays the scenarios on the port.
- `compare.py`: prints how long the tracks stay within 0.5 table units,
  positions and speeds, and draws both over the walls (needs Pillow).

```bash
tool/compare/harness/build.sh /tmp/sc-ref
/tmp/sc-ref/harness assets/original/ tool/compare/scenarios.txt 240 > /tmp/ref.csv
SCENARIOS=tool/compare/scenarios.txt OUT=/tmp/port.csv WALLS=/tmp/walls.json flutter test tool/compare/scenarios_test.dart
python3 tool/compare/compare.py /tmp/ref.csv /tmp/port.csv /tmp/walls.json /tmp/tracks
```

The third harness argument is the update rate. The original runs its
physics once per frame, so it depends a little on the frame rate itself
(the Windows game ran as fast as the PC allowed): flipper shots vary by
about 20 % between 60 and 240 Hz. 240 Hz, the port's own step, is the
main reference.
