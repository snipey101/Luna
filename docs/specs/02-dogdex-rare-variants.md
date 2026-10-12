# Stage 2: Dogdex and rare variants

## Goal
Add a collection that lasts across runs, so there's always something left to find.

## Player experience
- A **Dogdex** button on the title screen opens an album: a grid of cards, one per breed and variant.
  - Befriended: a small 3D-rendered portrait (or the model in a SubViewport), the breed name, its personality icon (friendly, timid or grumpy), and "Befriended ×N".
  - Not yet met: a dark silhouette and "???".
  - A progress line at the top, e.g. "9 / 14 found".
- In the park, a **rare variant** has a soft sparkle around it, and befriending one shows a special "Rare!" bubble and a sparkle burst. A "New!" bubble appears the first time any entry is befriended.

## Rare variants
| Variant | Base | How it appears |
|---|---|---|
| Dalmatian | new breed (friendly) | Rare spawn: replaces one friendly dog |
| Black Lab | Labrador colours, black (friendly) | Rare spawn: replaces one friendly dog |
| Golden shiny | any breed | Recoloured to a soft gold with a sparkle |

- At the start of each run, roll for each eligible dog: Dalmatian 6%, Black Lab 6%, and 4% shiny for any breed (aggressive dogs included). At most **2 rare dogs per run**.
- Tuning lives in `breeds.gd` (`RARE` table).
- Shiny dogs are a material tint at runtime (a gold-ish albedo multiply on the body meshes), so they don't need new models. The Dalmatian and Black Lab are new rows in `make_dogs.py` (the Dalmatian's spots use the existing patch helpers or a few extra small ellipsoids).

## Save data (extends stage 1)
```ini
[dogdex]
golden=4          ; befriended count per entry key
shiny_corgi=1
dalmatian=1
```
- Entry keys: the breed key, `shiny_<breed>`, `dalmatian`, `blacklab`.
- Befriending an aggressive dog counts for its breed entry, like any other.

## Technical approach
- `Dog` gets a `variant` (`""`, `"shiny"`) and an `entry_key()`. `befriend()` calls `Progress.add_dogdex(entry_key())` and checks whether it's new.
- `Main._spawn_dogs` handles the rare rolls (use `_rng`, so a `--seed` reproduces them).
- Dogdex screen: `scripts/dogdex.gd`, a Control overlay opened from the splash screen. Use portrait renders only if they're cheap. Otherwise each card can show the breed's colours as a simple drawn dog-head icon. Decide during implementation, looking at performance and appearance.
- Debug: `--force-rare=dalmatian|blacklab|shiny` for screenshots and tests.

## Tests
- Rare rolls with a fixed seed are deterministic, and never more than 2 rare dogs appear.
- Befriending adds to the right Dogdex entry, and the first befriend triggers "New!".
- Shiny entries are counted separately from the base breed.
- The Dogdex survives a save and reload.

## Acceptance
- With a forced rare dog, its sparkle is visible in the park, befriending it shows "Rare!", and it appears in the Dogdex.
- The silhouettes and "N / M found" are correct for a fresh save.

## Open questions
- Should the Dogdex show hints for unmet entries (e.g. "Seen near the yards")? Suggested: hints for rare variants only.
- Are 6% and 4% the right chances? A typical player should find most rares within about 10 wins.
