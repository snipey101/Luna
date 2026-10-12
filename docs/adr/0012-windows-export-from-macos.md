# 12. Export a single Windows .exe from macOS

Date: 2026-10-12

## Status
Accepted

## Context
The target platform is Windows, and development happens on a Mac.

## Decision
- `game/export_presets.cfg` defines "Windows Desktop": x86_64, with the game data embedded in the `.exe` (`embed_pck`), and `application/modify_resources=false` so no rcedit or Wine is needed. Test files are excluded.
- `make windows` writes `build/Luna.exe`.
- Only the Windows x86_64 export templates for 4.7.2 are installed, extracted from the official template archive into `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.

## Consequences
- Produces one file to copy to a PC.
- The exe keeps Godot's default icon and version info, and it can't be run on the Mac. A Windows smoke test is a manual step.
- Upgrading Godot means installing matching templates.
