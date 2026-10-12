# 15. Aggressive dogs can be befriended just after being barked at

Date: 2026-10-12

## Status
Accepted (amends ADR 0006 and ADR 0010)

## Context
Aggressive dogs only ever cost points, so the yards were simply places to avoid. Barking (ADR 0010) gave players a way to fend these dogs off, but no reward for being brave.

## Decision
- A bark puts an aggressive dog into a new `SCARED` state instead of sending it straight home. It cowers (crouching animation) and flees from Luna at `scared_speed` (3.8 m/s, slower than Luna's 5.5 m/s) for `scared_time` (3 s), then goes home with the rest of its 5 s cooldown.
- Touching a dog while it's `SCARED` befriends it: +1, heart, follows Luna, then wanders happily, and it never chases or bites again. Touching it at any other time behaves as before.
- Befriended aggressive dogs wag their tails and ignore barks.
- Both values live in `Breeds.STATS[AGGRESSIVE]`.

## Consequences
- All 17 dogs can now be befriended (13 before), which makes reaching 10 easier and gives the yards a risk-and-reward role.
- Catching a scared dog takes timing: from the edge of bark range (4.5 m), Luna closes the gap at about 1.7 m/s, which just fits in the 3 s window. Barking from closer up makes it easy.
- ADR 0006's "aggressive dogs never give a point" no longer applies.
