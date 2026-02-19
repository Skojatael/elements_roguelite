# Implementation Plan: Player Movement Joystick Controls

**Branch**: `001-joystick-movement` | **Date**: 2026-02-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-joystick-movement/spec.md`

## Summary

Implement a fixed-position virtual joystick in the bottom-left HUD that translates
touch drag input into a normalised movement vector, consumed by MovementComponent
each physics frame to drive player locomotion. All scenes are currently empty
scaffolding; this is a greenfield implementation.

## Technical Context

**Language/Version**: GDScript 4.6 (Godot 4.6)
**Primary Dependencies**: Godot 4.6 built-in — `Control`, `InputEventScreenTouch`,
`InputEventScreenDrag`, `CharacterBody2D.move_and_slide()`
**Storage**: N/A — no persistent data; joystick parameters are `@export` vars
**Testing**: Manual playtesting in Godot Editor + physical device / touch emulation
**Target Platform**: Android mobile (portrait 1080×1920); Windows for development
**Project Type**: Mobile game (single Godot project)
**Performance Goals**: 60 fps on mid-range Android; joystick input processed within
one `_physics_process` frame (≤ 16 ms)
**Constraints**: Mobile renderer (D3D12/Vulkan); portrait 1080×1920 layout; no
Forward+ shader effects; touch-only input
**Scale/Scope**: ~3 scripts, ~3 scenes modified/built; isolated HUD + player wiring

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design — all gates still pass.*

| Principle | Gate | Status |
|-----------|------|--------|
| I. Single Responsibility | `Joystick.gd` does only input→vector. `MovementComponent.gd` does only vector→velocity. Wiring lives in coordinator only. | ✅ Pass |
| II. Data-Driven Content | No game-balance constants hard-coded in scripts. Joystick parameters (`max_radius`, `dead_zone_percentage`, `move_speed`) are `@export` vars, tunable in Editor. | ✅ Pass |
| III. Mobile-First Performance | `Control` node with `TextureRect` children — no shader. Input handled in `_gui_input` (event-driven). Physics in `_physics_process`. No Forward+ effects. | ✅ Pass |
| IV. Editor-Centric Workflow | All scene hierarchy built in Godot Editor. `.tscn` files not hand-edited. | ✅ Pass |
| V. Simplicity & YAGNI | Fixed joystick only (no floating). No configurable position v1. `Joystick.gd` co-located with `Joystick.tscn` in `scenes/ui/hud/`. | ✅ Pass |

## Project Structure

### Documentation (this feature)

```text
specs/001-joystick-movement/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── joystick-interface.md   # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
scenes/
├── ui/
│   └── hud/
│       ├── Joystick.tscn          # EXISTS (empty) — build out in Editor
│       ├── Joystick.gd            # NEW — touch input logic, input_vector property
│       └── ExplorationHUD.tscn    # EXISTS (empty) — add Joystick child in Editor
├── player/
│   ├── Player.tscn                # EXISTS (empty) — add CharacterBody2D + component
│   └── components/
│       └── MovementComponent.gd   # EXISTS (stub) — implement physics movement
└── core/
    ├── Main.tscn                  # EXISTS (empty) — add Player + HUD, add Main.gd
    └── Main.gd                    # NEW — coordinator: wire joystick → MovementComponent
```

**Structure Decision**: Single Godot project. Scenes own their scripts. No new
`res://scripts/` files needed (all scripts are scene-specific). Follows Principle V
(co-location rule) and existing folder conventions from CLAUDE.md.

## Complexity Tracking

> No Constitution Check violations. Table omitted per template instructions.
