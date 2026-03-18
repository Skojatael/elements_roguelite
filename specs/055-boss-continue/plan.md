# Implementation Plan: Boss Continue (Endless Mode)

**Branch**: `1-boss-continue` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/1-boss-continue/spec.md`

## Summary

When the player defeats the boss during an endless run, the "Continue" button on the victory overlay returns them to the dungeon room they left from — keeping the run active with all stats preserved. Implementation requires recording the departure room ID on boss teleport, exposing a public `return_to_room` method on `RoomLoader`, and wiring `_on_boss_continue_pressed` in `Main.gd`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing throughout
**Primary Dependencies**: Godot 4.6 engine; no external addons involved
**Storage**: N/A — no persistence; transient run-scoped state only
**Testing**: GUT (Godot Unit Testing framework) — existing `tests/unit/` suite
**Target Platform**: Android mobile (portrait 1080×1920); Windows for development
**Project Type**: Single Godot project
**Performance Goals**: 60 fps sustained on mid-range Android; room load is instant (same path as normal door navigation)
**Constraints**: Mobile renderer; Jolt physics — feature adds no rendering or physics work
**Scale/Scope**: 2 files modified, ~20 lines of code total; no new scenes or data files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Single Responsibility** | ✅ Pass | `Main.gd` owns boss lifecycle state (existing pattern); `RoomLoader` owns room loading. No responsibility mixing. `_boss_return_room_id` is naturally co-located with `_boss_room_spawner` etc. |
| **II. Data-Driven Content** | ✅ Pass | No balance values or content config. No JSON changes. |
| **III. Mobile-First** | ✅ Pass | No new rendering, physics, or draw calls. Room load reuses existing pipeline. |
| **IV. Editor-Centric** | ✅ Pass | No scene changes. `BossVictoryOverlay` already has the Continue button; `setup(show_continue)` already controls visibility. All node refs via `@export var`. |
| **V. Simplicity & YAGNI** | ✅ Pass | One new field, one new public method, one implemented stub. No new abstractions. |
| **VI. Early Return** | ✅ Pass | All new code uses guard clauses. `_on_boss_teleport_pressed` guard on null `current_room`; `_on_boss_continue_pressed` guard on empty `_boss_return_room_id`. |

**Result**: All principles satisfied. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/1-boss-continue/
├── plan.md          ← this file
├── research.md      ← Phase 0 output
├── data-model.md    ← Phase 1 output
├── quickstart.md    ← Phase 1 output
└── tasks.md         ← Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (files changed)

```text
scripts/dungeon/
└── RoomLoader.gd           ← add public return_to_room(room_id) method

scenes/core/
└── main.gd                 ← _boss_return_room_id field + continue handler
```

**No new files.** No new scenes, data models, or JSON schemas.

## Phase 0: Research

See [research.md](research.md) for full decision log. Summary:

| Decision | Choice |
|----------|--------|
| How to expose room loading | New public `RoomLoader.return_to_room(room_id)` wrapping `_load_room(room_id, "")` |
| Where to store return room ID | `Main._boss_return_room_id: String` — co-located with boss lifecycle fields |
| Continue button visibility | `run_mode == "endless" and not _boss_return_room_id.is_empty()` — auto-hides for DevPanel path |

## Phase 1: Design

### Data Model

See [data-model.md](data-model.md). One new transient field: `Main._boss_return_room_id: String`. No persistent data, no JSON changes, no new data-model classes.

### API Contracts

This is a self-contained Godot scene feature with no external API surface. The internal "contract" between components:

**`RoomLoader.return_to_room(room_id: String) -> void`**
- Pre-condition: `room_id` exists in `DungeonGenerator.rooms_by_id`
- Effect: Equivalent to `_load_room(room_id, "")` — loads room scene, places player at center, configures doors, sets `RunManager.current_room`
- Guard: delegates to `_load_room` which already holds the `_loading` flag guard

**`Main._on_boss_continue_pressed() -> void`**
- Pre-condition: `_boss_return_room_id` is non-empty (guaranteed by button visibility logic)
- Steps:
  1. Free `_boss_room_node` and null boss fields
  2. Free `_boss_victory_layer` and null overlay fields
  3. `GlobalSignals.gameplay_started.emit()` (shows ExplorationHUD)
  4. `_room_loader.return_to_room(_boss_return_room_id)`
  5. `_boss_return_room_id = ""`

**`Main._on_boss_teleport_pressed()` — change**
- Before calling `_room_loader.free_current_room()`: capture `_boss_return_room_id = (RunManager.current_room as RoomSpawner).room_id` if `RunManager.current_room != null`, else leave as `""`

**`Main._show_boss_victory_overlay()` — change**
- `setup(run_mode == "endless")` → `setup(run_mode == "endless" and not _boss_return_room_id.is_empty())`

### Agent Context Check

No new technology, libraries, or architectural patterns introduced. `CLAUDE.md` requires no updates.
