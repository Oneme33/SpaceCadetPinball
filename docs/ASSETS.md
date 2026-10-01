# Assets

## Rule

The original artwork, sounds, font and music are Microsoft/Cinematronics
property. They are **never committed**. The repository contains only code
plus clearly named placeholders. Do not publish a build containing the
original assets.

## Where originals live

```
original/            the user's own copy (PINBALL.DAT, FONT.DAT, *.WAV, *.MID) — git-ignored
assets/original/     what the game loads — git-ignored except its README
```

Install them with:

```bash
dart run tool/install_originals.dart original/
```

This validates `PINBALL.DAT` and copies it, `FONT.DAT` and the WAVs into
`assets/original/`. The game parses the DAT at start-up (`lib/dat/`), so
there is no conversion step and no generated art: bitmaps, depth maps,
walls, materials and the camera all come straight from the file.

**A web build bundles these files.** Never deploy a build made with the
originals installed to a public host.

## When originals are missing

The game falls back to flat, clearly marked placeholder shapes drawn in code,
at the exact positions and sizes from the layout. No substitute artwork or
substitute sounds are ever used. A missing sound is silent and logged.

## Status

| Asset | Status |
|---|---|
| Table and scoreboard art | rendered from the DAT (Phase 2) |
| Ball sprites (7 depths) | rendered from the DAT (Phase 2) |
| Component sprites, z-maps | parsed; drawn from Phase 3/4 on |
| Sound effects | available in `original/` (60 WAV) |
| Message display font | available in `original/FONT.DAT`, decoder in Phase 5 |
| Music | available (`.MID`); MIDI playback is not supported by the audio engine — TODO: decide in Phase 5 |
