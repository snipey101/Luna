# 8. Synthesise sound effects and music

Date: 2026-10-12

## Status
Accepted

## Context
The game needs a bark, a happy chime, a whimper, footsteps, a win jingle and a gentle music loop. Downloading asset packs adds licensing questions and untrusted files.

## Decision
`tools/audio/make_sounds.py` generates all audio as 16-bit mono 22 kHz WAVs using only the Python standard library. `Sfx` (autoload) plays them from a small pool with slight pitch variation, and loops the music.

## Consequences
- No licensing concerns, and the sounds are reproducible and easy to tweak.
- They sound simple and chiptune-like. Recorded or CC0 sounds could replace any file with the same name.
