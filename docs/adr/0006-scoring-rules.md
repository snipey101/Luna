# 6. Scoring rules: befriend each dog once, floor at zero, win at 10

Date: 2026-10-12

## Status
Accepted

## Context
The brief: +1 for each dog Luna touches, −1 when an aggressive dog touches her, win at 10, the score never below zero, and no way to lose. If touches could repeat, a player could farm one dog.

## Decision
- Touching a friendly or timid dog befriends it: +1, once per dog. Afterwards it follows Luna for 8 s, then wanders with a heart over its head.
- Aggressive dogs never give a point. A tag costs 1 point (clamped at 0) and gives Luna 1.5 s of knockback and blinking during which she can't be hit again. The dog then loses interest for 5 s and goes home.
- There are 13 dogs that can be befriended against a target of 10, so the game can always be won.
- `GameState` (autoload) owns the score and emits `score_changed` and `won`.

## Consequences
- No farming, and the end of the game stays reachable.
- The protections stop Luna losing several points in a row.
- Late in the game the remaining dogs may be far apart. An arrow pointing to the nearest dog has been suggested if that turns out to be a problem.
