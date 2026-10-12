# 16. Energy, food bowls, and peeing and pooping

Date: 2026-10-12

## Status
Accepted

## Context
The original brief named these as future ideas: energy that runs down and is refilled by finding food, and peeing and pooping after eating too much. They had to stay cute, keep the "no way to lose" rule, and give peeing and pooping a real purpose in the game.

## Decision
- **Tuning in one place:** every needs value is a constant in `GameState` (energy drain rates, bowl count and refill time, the bowl thresholds for pee and poop, accident time, mark lifetime, lure radius, sniff time). `GameState` also holds the state (`energy`, `bowls_since_pee`, `bowls_since_poop`) and emits `energy_changed` and `need_changed`.
- **Energy** (0–100) drains at 0.25/s idle, 0.6/s sneaking, 1.2/s moving, and 3 per bark. Below 25, Luna moves at 75% speed and her head and ears droop. It never causes a loss.
- **Food bowls** (`FoodBowl`, 6 on open sand) are eaten by walking into them: about 1 s of munching, +40 energy, refill after 30 s.
- **Needs:** pee after 2 bowls, poop after 4 (poop takes priority). While Luna needs to go she wiggles, and a "Gotta pee!" or "Gotta poop!" bubble repeats every 4 s. **E** goes; after 20 s she has an accident wherever she is. Going on grass (`World.is_grass`: the yards plus 4 new unfenced lawns) shows "Good girl!" with sparkles. Otherwise, or after an accident, it shows "Oops!". There's no effect on the score.
- **Marks** (`PottyMark`): a puddle or a cartoon swirl that fades after 20 s.
- **Pee is a lure:** an idle or wandering timid dog within 10 m of a fresh pee spot goes over (`LURED`) and sniffs it for 6 s (`SNIFF`). In both states it ignores Luna, so she can walk up and befriend it. Each spot lures each dog once. Poop has no gameplay effect.
- Holding Shift keeps Luna sneaking while she eats or goes, so stopping doesn't scare timid dogs.

## Consequences
- Eating, peeing, luring and catching timid dogs is a new tactic that feeds into the main goal of making friends.
- Luna can now be busy (eating or going) and briefly unable to move. Aggressive dogs can still reach her during that time.
- Tests reset bowls and the tummy counters before they run, because Luna can eat bowls by accident while running around in earlier checks.
