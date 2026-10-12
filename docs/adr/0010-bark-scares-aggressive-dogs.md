# 10. Barking scares off aggressive dogs, with a cooldown

Date: 2026-10-12

## Status
Accepted (supersedes "bark is cosmetic" from the v1 plan)

## Context
In v1 the bark did nothing apart from the sound. Players had no active way to deal with a chasing dog other than running away.

## Decision
`Luna.bark()` calls `on_bark()` on every dog in the `dogs` group within `BARK_RADIUS` (4.5 m). An aggressive dog that isn't already on cooldown gets scared: it whimpers, shows "Eep!", goes home and keeps its usual 5 s cooldown. The bark itself has a `BARK_COOLDOWN` of 1.5 s, so spamming it can't make Luna untouchable. Friendly and timid dogs ignore barks.

## Consequences
- Gives the bark a purpose and adds a timing skill, without new controls.
- Balance depends on two constants at the top of `luna.gd`.
