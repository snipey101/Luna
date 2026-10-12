# 13. Configurable camera zoom, defaulting to 200%

Date: 2026-10-12

## Status
Accepted (amends ADR 0009)

## Context
The art looks cuter up close. A closer view shows less of the park, so players should be able to choose their own trade-off.

## Decision
`IsoCamera` has a `zoom` multiplier: ortho size = `BASE_SIZE (13) / zoom`.
- The default is `DEFAULT_ZOOM = 2.0`.
- Players adjust it with the mouse wheel or +/−, in steps of 0.25 between 1.0 and 3.0. Changes are smoothed and saved to `user://settings.cfg`.
- `--zoom=N` overrides it for one run without saving.

## Consequences
- At 200% you can see about 5 m around Luna, which is less than the timid notice range (8 m) and the aggressive notice range (7 m). Dogs may react before they're on screen. Revisit these ranges if that feels unfair.
- World-space text (popups) scales with the zoom. The HUD doesn't.
