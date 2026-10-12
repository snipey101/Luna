# 11. Headless gameplay tests

Date: 2026-10-12

## Status
Accepted

## Context
The game rules (scoring, personalities, winning) are easy to break by accident while tuning, and playing through by hand is slow.

## Decision
`game/tests/test_gameplay.tscn` loads `Main` headlessly, teleports Luna around and checks the rules. `make test` runs it, and the exit code is 0 when every check passes. Spawns are random on each run, so tests must not depend on layout: for example, they place Luna and a dog inside a yard on purpose, and they compare the score before and after an action rather than checking an absolute value. Screenshots for visual checks come from `--screenshot`, `--demo`, `--luna-pos` and `--cam-size`.

## Consequences
- Fast feedback on the rules, and the random layouts give broader coverage.
- Tests touch some private state (`_cooldown`, `_enter`) to set up situations. That's acceptable for a project this small.
