# Implementation Plan: Boss Entry Position

**Branch**: `035-boss-entry-position` | **Date**: 2026-03-07 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/035-boss-entry-position/spec.md`

## Summary

When the player teleports to the boss room, place them at `BOSS_ROOM_WORLD_POS + Vector2(0, 400)` (lower-center of screen) rather than at the room origin. Camera targeting stays unchanged. One constant added, one line changed in `scenes/core/main.gd`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: None
**Storage**: N/A
**Testing**: Manual in-editor playtesting
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Project Type**: Godot 4.6 mobile game
**Performance Goals**: 60 fps — positional assignment has zero performance impact
**Constraints**: Change must cover all three boss entry paths without duplication
**Scale/Scope**: One file, one constant, one assignment line

## Constitution Check

*GATE: Must pass before implementation.*

- **I. Single Responsibility** ✅ — Only `main.gd` is modified; no new scripts, scenes, or autoloads introduced. Change is scoped to the existing `_on_boss_teleport_pressed()` method in Main.
- **II. Data-Driven Content** ✅ — The spawn offset is a layout/structural positional constant (same category as `BOSS_ROOM_WORLD_POS`, `ENTRY_OFFSET`, `SPACING_X`, `SPACING_Y`), not a balance/content value. Hard-coding it as a named `const` follows existing project conventions.
- **III. Mobile-First Performance** ✅ — A single `Vector2` addition has no measurable cost.
- **IV. Editor-Centric Workflow** ✅ — No `.tscn` changes; no node references affected.
- **V. Simplicity & YAGNI** ✅ — Minimum change: one const + one assignment line. No new abstractions.
- **VI. Early Return** ✅ — `_on_boss_teleport_pressed()` control flow is not changed; no nesting introduced.

**Gate result: PASS — proceed to implementation.**

## Project Structure

### Documentation (this feature)

```text
specs/035-boss-entry-position/
├── plan.md        ← this file
├── research.md    ← Phase 0 output
└── tasks.md       ← Phase 2 output (/speckit.tasks)
```

### Source Code (files changed)

```text
scenes/core/main.gd     # Add BOSS_PLAYER_SPAWN_OFFSET const; update player placement line
```

No new files. No scene changes. No data changes.

## Implementation Design

### Change 1 — New constant in `main.gd`

Add after the existing `BOSS_ROOM_WORLD_POS` constant (line 10):

```gdscript
const BOSS_PLAYER_SPAWN_OFFSET: Vector2 = Vector2(0.0, 400.0)
```

### Change 2 — Update player position in `_on_boss_teleport_pressed()`

Current (line 233):
```gdscript
_player.global_position = BOSS_ROOM_WORLD_POS
```

Replace with:
```gdscript
_player.global_position = BOSS_ROOM_WORLD_POS + BOSS_PLAYER_SPAWN_OFFSET
```

Camera line (line 234) is **unchanged**:
```gdscript
_camera.global_position = BOSS_ROOM_WORLD_POS
```

### Why only `_on_boss_teleport_pressed()` needs changing

All three entry paths call this same method:
- HUD "Teleport to Boss" button → `boss_teleport_pressed` signal → `_on_boss_teleport_pressed()`
- Hub boss-run shortcut → `_on_hub_boss_run_pressed()` → `_on_boss_teleport_pressed()`
- Dev panel "Start Boss" → `_on_dev_start_boss()` → `_on_boss_teleport_pressed()`

A single change covers all paths.
