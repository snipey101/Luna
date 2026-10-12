# 9. Fixed orthographic isometric camera and camera-relative WASD

Date: 2026-10-12

## Status
Accepted

## Context
The brief asks for a simple isometric 3D game with WASD controls.

## Decision
`IsoCamera` is an orthographic camera at 45° yaw and 38° pitch, with an ortho size of 13. It smoothly follows Luna and never rotates. WASD movement is rotated by the camera's yaw, so W always means "up the screen".

## Consequences
- Simple and readable controls with a classic isometric look.
- Tall trees can sometimes hide Luna. Fading objects in front of her is an option if that's a problem.
