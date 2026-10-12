# Stage 3: Collars and cosmetics

## Goal
Give stars something to spend on (well, unlock), and let players make Luna their own.

## Player experience
- A **Wardrobe** button on the title screen. Luna stands centre-stage, and you pick an outfit from a row of swatches and items. The change shows on her straight away.
- Locked items show a padlock and "★ 6" (the total stars needed).
- Luna wears the chosen items in the game and on the title screen.

## Items
| Item | Unlock (total stars across all levels) |
|---|---|
| Red collar (default) | 0 |
| Blue, green and purple collars | 1, 2, 3 |
| Pink collar with a heart tag | 5 |
| Bandana (red / blue) | 6 |
| Bow (on the head) | 9 |
| Little sun hat | 12 (needs stage 4 levels to reach) |

- One collar plus at most one accessory (bandana, bow or hat).
- Total stars = the sum of stars across all levels (stage 1). Unlocks never get taken away.

## Save data
```ini
[wardrobe]
collar="blue"
accessory="bow"      ; "" for none
```
Unlock status is worked out from the star total. It isn't stored, so it can't get out of sync.

## Technical approach
- **Collar colours:** tint the existing `Collar` mesh's material at runtime (no new model).
- **Accessories:** new props built in `make_props.py` (`bandana.glb`, `bow.glb`, `sun_hat.glb`) and attached to Luna's `Head` node, or to `Body` for the bandana, at fixed offsets. Make sure they follow the head's nod and sit animations.
- Item definitions live in a `scripts/wardrobe.gd` table: key, name, kind, unlock stars, and colour or model.
- `Luna._ready` applies the current outfit, and so does the splash screen's Luna.
- Wardrobe UI: a Control overlay on the title screen, styled with `Hud.panel_style` / `Hud.style_button`.

## Tests
- The unlock rules match the star totals at the boundaries (2 stars → blue and green yes, purple no).
- An outfit set and saved is reloaded and applied to Luna. The `Collar` material colour matches.
- A locked item can't be selected.

## Acceptance
- Screenshots of Luna in each accessory look right, both in-game at 200% zoom and on the title screen, and the accessories move with her head.

## Open questions
- Should other dogs react to an outfit? Suggested: no. Keep it purely cosmetic.
- Do players need a way to see what's coming, e.g. a "Next unlock at ★ 6" line? Suggested: yes.
