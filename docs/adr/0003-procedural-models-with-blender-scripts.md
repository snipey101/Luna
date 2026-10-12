# 3. Generate 3D models with Blender Python scripts

Date: 2026-10-12

## Status
Accepted

## Context
The game needs a cute, consistent look in the style of Animal Crossing, about 10 distinct dog breeds, and simple scenery. Free asset packs have limited breed variety and mixed styles. Modelling by hand doesn't fit a workflow driven from the terminal.

## Decision
- `tools/blender/make_dogs.py` and `make_props.py` build every model headlessly (`Blender -b -P`) from rounded primitives with flat colours, and export them as `.glb` to `game/assets/models/`. Each breed is a row of parameters: proportions, ear and tail type, colours and markings.
- **No rigging.** The legs, head, ears and tail are separate named child objects with their pivots at the joint (`Body`, `Head`, `EarL/R`, `LegFL/FR/BL/BR`, `Tail`). The game animates them in code (`game/scripts/dog_anim.gd`): leg swing, bob, wag, sit, pant, crouch and squash.
- Dogs are built at `GLOBAL_SCALE = 1.8` times their nominal size so they read well on screen. `Breeds.MODEL_SCALE` in the game must match this value.
- The scripts target the installed Blender 2.92. `--preview out.png` renders a lineup image for checking the models by eye.

## Consequences
- The art is reproducible and easy to tweak, and new breeds are cheap to add.
- The game relies on the node names above. Renaming parts breaks the animation.
- The animations are simple. Complex motion would need a different approach, such as armatures.
