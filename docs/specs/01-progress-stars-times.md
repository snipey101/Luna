# Stage 1: Save data, stars and best times

## Goal
Give every run a score worth beating, and remember it between sessions. This stage also sets up the save system that stages 2–4 build on.

## Player experience
- A small **run timer** in the HUD (mm:ss) starts when the park loads and pauses while the game is paused.
- On winning, the win screen shows **1–3 paw stars**, which pop in one at a time with a chime, then the run time and a "New best!" badge when it applies.
- The **title screen** shows your best stars and best time for the Park.

## Rules
| Stars | Earned when |
|---|---|
| ★ | You win (reach the friend target). |
| ★★ | You win in less than the level's **par time** (Park: 5:00). |
| ★★★ | You win without losing a point to an aggressive dog. A "-1" counts; an "Ouch!" at 0 points doesn't. |

- Each star is earned on its own: a fast run with a hit gets ★★, and a slow run with no hits gets ★ + ★★★ = 2 stars total. **Stars per level = the number of the three conditions met**, and the best result per level is kept.
- Record whether each condition has *ever* been met per level, so stars can build up across runs (Mario-style). This makes progress feel steady for casual players.
- The best time is the fastest win, regardless of stars.

## Save data
- File: `user://progress.cfg` (ConfigFile). On Windows this is under `%APPDATA%/Godot/app_userdata/Luna/`.
- New autoload `Progress` (`scripts/progress.gd`) owns loading, saving and the schema. Saves are written immediately on change.
- Schema (version 1):
  ```ini
  [meta]
  version=1
  [level.park]
  star_win=true
  star_par=false
  star_nohit=true
  best_time=412.6
  wins=3
  ```
- Missing file or keys mean defaults. An unknown future `version` is read best-effort and not overwritten.
- Zoom stays in `settings.cfg` (ADR 0013). Progress is separate so it can be reset without losing settings.

## Technical approach
- `GameState`: add `run_time`, `points_lost` (count of applied −1s), and `level_id` (`"park"` for now). Reset them in `reset()`.
- Level constants (target, par time) live in one table that stage 4 can extend: `scripts/levels.gd` with `const LEVELS := {"park": {"name": "The Park", "target": 10, "par": 300.0}}`.
- `Hud`: show the timer, and add a star row plus time line to the win panel.
- `Main._on_won`: calculate the stars, call `Progress.record_win(level_id, time, no_hit)`, and pass the result to the HUD.
- Splash: show the best result for the Park under the tagline.
- Debug: `--reset-progress` deletes the progress file at startup. Tests use their own temporary progress path so they never touch real saves.

## Tests
- A no-hit win gets the no-hit star, and a win with a −1 doesn't.
- A win under par gets the par star (set `run_time` directly).
- The best time only improves. A slower win doesn't overwrite it.
- Stars collected across runs are combined (par in one run, no-hit in another, giving ★★★).
- Save, reload and read back give the same values. A missing file gives zero stars.
- The timer doesn't advance while paused.

## Acceptance
- The stars and time on the win screen match the run, and the title screen shows the best after restarting the game.
- The existing gameplay tests are unchanged and passing. There's an ADR for the save system and star rules.

## Open questions
- Is a 5:00 par right for the Park? Tune it after a few real playthroughs.
- Should star conditions be listed on the pause screen so players know what to aim for? (Suggested: yes, greyed out until earned.)
