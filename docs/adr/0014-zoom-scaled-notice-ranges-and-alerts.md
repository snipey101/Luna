# 14. Scale notice ranges to the zoom, and show "!" alerts

Date: 2026-10-12

## Status
Accepted (resolves the visibility concern in ADR 0013)

## Context
At 200% zoom you can see about 5 m around Luna, but timid dogs noticed her at 8 m and aggressive dogs at 7 m. Dogs reacted off screen: timid dogs ran away unseen, and chasing dogs arrived without warning.

## Decision
- `GameState.range_scale = 0.5 + 0.5 / zoom` multiplies every dog's notice range (via `Dog._notice()`). It's 1.0 at 100%, 0.75 at 200% (timid 6 m, sneaking 2.25 m, aggressive 5.25 m) and about 0.67 at 300%. The camera updates it whenever the zoom changes. Halfway scaling, rather than shrinking fully with the view, leaves room to react at close zoom.
- The leash and bark radius are not scaled. They relate to the yard layout and to Luna's own ability.
- When a timid dog starts to flee or an aggressive dog starts to chase, it pops a "!" over its head (blue for timid, red for aggressive). This is limited to once every 2.5 s per dog, so a dog hovering at the edge of its range doesn't keep showing it.

## Consequences
- Reactions happen near or on screen, with a clear warning.
- Players can make dogs slightly less alert by zooming in (at most by about a third at 300%). That's accepted as a minor, harmless exploit for a game with no way to lose.
- The tests pin the zoom to 200% so they don't depend on the player's saved setting.
