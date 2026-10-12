# Luna: notes for Claude

Godot 4 isometric puppy game (see README.md). Models come from Blender scripts and audio from a Python script, and the world, dogs and HUD are built in code. Design decisions live in `docs/adr/`. Read the relevant ADR before changing a core approach.

## Tooling (macOS, Apple Silicon)
- Godot: `/Applications/Godot.app/Contents/MacOS/Godot` (4.7.2). Blender: `/Applications/Blender.app/Contents/MacOS/Blender` (2.92, Intel, Python 3.7, so scripts must stay 2.92 compatible).
- The terminal runs under Rosetta: Homebrew needs `arch -arm64 /opt/homebrew/bin/brew ...`.
- After adding new assets (`.glb`, `.wav`), run `Godot --headless --path game --import` **twice**. The first pass can fail with "no resource loaders" because scripts compile before the new files are imported.
- Windows export templates (x86_64 only) are in `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.

## Commands
- `make run`: play (opens the title screen).
- `make test`: headless gameplay checks. The exit code is 0 when all pass, and the output ends with `ALL PASSED` or `FAILED (n failures)`.
- `make assets`: rebuild models and sounds, then re-import.
- `make windows`: writes `build/Luna.exe`.
- Debug flags go after `--`: `--seed=N --luna-pos=x,z --zoom=N --cam-size=N --demo --needs-demo[=poop] --splash [--autoplay] --screenshot=out.png --shot-delay=S`. Any flag skips the title screen unless `--splash` is given.

## Checking visual changes
Take a screenshot and look at it. Don't assume it looks right. For example: `Godot --path game -- --screenshot=<scratchpad>/x.png --shot-delay=1.5 --seed=4 --zoom=2 --demo`. Pick the flags that show the change (`--luna-pos` to frame a spot, `--needs-demo` for the potty and energy features, `--splash` for the title screen).

## Rules that are easy to break
- **Model contract:** the animation code (`dog_anim.gd`) finds the parts by name: `Body`, `Head`, `EarL/R`, `LegFL/FR/BL/BR`, `Tail`, and `Kibble` on the bowl. Keep these names in `tools/blender/`.
- `GLOBAL_SCALE` in `make_dogs.py` must equal `Breeds.MODEL_SCALE` (1.8).
- Don't use `NavigationAgent3D`. Dogs follow paths from `NavigationServer3D` with their own 2D follower (ADR 0007), and skip navmesh points with `y > 1` (islands on top of obstacles).
- Billboard text (`Label3D`) is centred with `offset` (in pixels, screen space), not a parent position offset.
- Materials coloured by vertex need `vertex_color_is_srgb = true`, or colours come out washed out.
- Speech bubbles go through `Fx.speech_bubble()` / `Fx.popup()`, parented to the speaker, with heights from `Luna.HEAD_HEIGHT` or `Dog._head_height()`.

## Where tuning lives
- Dog personalities and breeds: `game/scripts/breeds.gd`.
- Score target, energy, food, potty, lure: the constants at the top of `game/scripts/game_state.gd`.
- Luna's speeds and bark: the top of `game/scripts/luna.gd`.
- Camera and zoom: `game/scripts/iso_camera.gd`.

## Tests (`game/tests/test_gameplay.gd`)
- They run on a fixed world seed (`TEST_SEED`). Dog wandering is still random, so run `make test` several times before calling a change done.
- Teleporting Luna can brush past other dogs or eat bowls on the way. Check the specific dog's state, or compare the score before and after; don't assert an exact absolute score. Reset bowls and the tummy counters before needs checks.
- When a check is flaky, find out why (print state on failure) before loosening it. Some flakes have been real bugs.

## Process
- Add an ADR (`docs/adr/NNNN-*.md` and a row in `docs/adr/README.md`) for significant gameplay or architecture decisions. Supersede or amend rather than rewrite.
- Keep the README controls and rules, the HUD hint, the pause text and the title-screen controls line in sync when controls change.
- Re-export `build/Luna.exe` after gameplay changes (it's gitignored).
- Commit and push only when asked. Remote: `git@github.com:snipey101/Luna.git` (public), branch `main`. Use the `ship` skill.
