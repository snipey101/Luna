# 5. Keep breed and personality tuning in one GDScript table

Date: 2026-10-12

## Status
Accepted

## Context
Each breed has a fixed personality (friendly, timid or aggressive), a count in the world, and tuning values (speeds, notice ranges, timings). The plan suggested one `.tres` Resource file per breed.

## Decision
All of this lives in `game/scripts/breeds.gd`:
- `STATS` holds the defaults for each personality.
- `DATA` holds each breed's name, personality, scale, count and optional `stats` overrides.
- `Breeds.stats_for(key)` merges the two.

## Consequences
- All balancing happens in one readable file, and it's easy to compare breeds side by side.
- There's no editing in the Godot inspector. Future stats (energy, hunger) can be added to the same tables.
