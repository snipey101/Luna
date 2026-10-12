# 7. Follow navmesh paths with our own 2D follower, not NavigationAgent3D

Date: 2026-10-12

## Status
Accepted

## Context
Dogs need to path around fences when wandering, fleeing and chasing. The navmesh is baked at runtime from static colliders (`World`). Testing showed the baked surface sits about 0.5 m above the ground. That is exactly `NavigationAgent3D.path_desired_distance`, so agents never moved past their first waypoint and dogs got stuck. The bake also creates small unreachable "islands" on top of rocks and fence colliders.

## Decision
- `Dog` queries `NavigationServer3D.map_get_path()` directly and steps through the waypoints using distance on the ground plane only (`_next_waypoint()`, 0.35 m threshold).
- Flee targets come from `map_get_closest_point()`, ignoring points higher than 1 m (the islands).
- No path queries are made before the map's first sync (`map_get_iteration_id(map) == 0`).
- Navmesh agent values are multiples of the cell size (radius 0.5, height 1.0, climb 0.25) to avoid precision warnings.

## Consequences
- Movement is reliable, and the code is small and easy to follow.
- Godot's built-in avoidance between agents isn't used, so dogs can overlap each other. They only collide with the world.
