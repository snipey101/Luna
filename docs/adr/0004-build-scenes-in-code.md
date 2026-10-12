# 4. Build the world, dogs and HUD in code

Date: 2026-10-12

## Status
Accepted

## Context
The original plan had a separate `.tscn` file for the world, Luna, a dog and the HUD. Hand-editing Godot scene files (resource IDs, sub-resources, node paths) is error-prone without the editor, and the world layout is partly random anyway.

## Decision
`scenes/Main.tscn` is a single node running `scripts/main.gd`. Everything else is created in code:
- `World` builds the ground, the fenced yards and gardens, the tree border, props and the navmesh.
- `Luna`, `Dog` and `Hud` build their own child nodes.
- The world layout uses fixed fenced rectangles (`World.YARDS` / `World.GARDENS`) plus seeded random scattering. `--seed=N` reproduces a layout.

## Consequences
- Easy to change and review as plain code, and the seeds make the scattering reproducible.
- You can't arrange things visually in the Godot editor. Layout changes are code changes.
- If the project later needs designer-made levels, this should be revisited, for example by moving the layout into scenes.
