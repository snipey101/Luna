# 2. Use Godot 4 as the game engine

Date: 2026-10-12

## Status
Accepted

## Context
The game must run natively on Windows, but it is developed on macOS (Apple Silicon). Unity was already installed, and Godot was another option. Most of the code is written by an AI assistant from the terminal, so the project files need to be readable and editable as text.

## Decision
Use Godot 4 (4.7.2 stable, installed with `arch -arm64 brew install --cask godot`) with GDScript and the Forward+ renderer.

## Consequences
- Free and lightweight. Scenes, scripts and project settings are plain text, which suits editing without the editor.
- Windows builds are exported from macOS with export templates (see ADR 0012).
- The Forward+ renderer needs Vulkan or D3D12 on Windows. Very old GPUs would need the Compatibility renderer.
- Unity's asset store and ecosystem aren't available.
