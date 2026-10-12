# 17. Title screen before the game

Date: 2026-10-12

## Status
Accepted

## Context
The game used to drop players straight into the park with no introduction.

## Decision
- `scenes/Splash.tscn` (`scripts/splash.gd`) is now the main scene. It shows a small 3D lawn with Luna and four friends wagging and hopping, the "Luna" title, a tagline, the controls, and Play and Quit buttons. Play has focus, so Enter or Space starts the game. Esc quits.
- Play fades to cream, then loads `Main.tscn`. On the win screen, "Play Again" still reloads `Main` directly, skipping the title.
- The title screen reuses the game's look: `World.add_environment()` (moved out of `main.gd`) and the static `Hud.panel_style()` / `Hud.style_button()`.
- Any command-line debug flag skips the title screen so the existing screenshot and demo flags keep working. `--splash` shows it anyway, and `--splash --autoplay` presses Play automatically to check the hand-over.

## Consequences
- A friendlier start that shows off the characters.
- The tests load `Main.tscn` directly, so they're unaffected.
