# Implementation Plan: Run End Screen

**Branch**: `015-run-end-screen` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/015-run-end-screen/spec.md`

## Summary

When a run ends, the dungeon room is freed, a `RunSummary` snapshot is created from RunManager's live session state, and `ResultsScreen.tscn` is added to the Main scene. The results screen reads exclusively from the snapshot and displays essence cashed out, enemies slain, and rooms cleared. A "Return" button frees the results screen and restores the hub room.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Godot 4.6 — CanvasLayer, Label, Button, RefCounted
**Storage**: N/A — results are computed at run-end from in-memory session state; not persisted
**Testing**: Manual — 12 validation scenarios in `quickstart.md`
**Target Platform**: Android mobile portrait (1080×1920); Windows dev
**Project Type**: Mobile game — single Godot project
**Performance Goals**: 60 fps sustained; results screen is static UI with no physics or shaders
**Constraints**: Mobile renderer only; no Forward+ effects; Jolt physics (not touched by this feature)
**Scale/Scope**: One new scene, one new data model, modifications to four existing files

## Constitution Check

### I. Single Responsibility ✅
- `RunSummary` — pure data snapshot, no logic beyond field storage and factory method.
- `ResultsScreen` — display and navigation only; reads from snapshot, emits one signal.
- `RunManager` additions — `enemies_slain` counter and `run_summary` field stay within RunManager's run-session domain.
- `RoomLoader` gains run-end room cleanup — consistent with its existing room-lifecycle ownership.
- `Main.gd` remains the scene orchestrator; adds `run_ended` handler alongside existing `hub_exited` and `player_died` handlers.
- No autoload responsibilities are merged or duplicated.

### II. Data-Driven Content ✅
- No game-balance values in this feature. N/A — UI display only.

### III. Mobile-First Performance ✅
- Static `CanvasLayer` with Labels and one Button. Trivial draw-call cost.
- No shaders, no physics, no atlases needed for placeholder implementation.

### IV. Editor-Centric Workflow ✅
- `ResultsScreen.tscn` is created in the Godot Editor; the script is attached via the editor.
- Labels and Button are assigned to `@export var` fields via the Inspector — no hardcoded `$NodeName` paths.

### V. Simplicity & YAGNI ✅
- `RunSummary` is a new data class required by FR-010 (snapshot before teardown). It has exactly one consumer (ResultsScreen). It is not speculative — the spec mandates the clean separation.
- No base classes, no registries, no abstractions beyond what the current feature requires.

**Verdict**: All five principles satisfied. No violations. Proceeding to implementation design.

## Project Structure

### Documentation (this feature)

```text
specs/015-run-end-screen/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── interfaces.md    ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code

```text
scenes/
└── ui/
    └── run_end/              ← new directory (create in Editor)
        ├── ResultsScreen.tscn   ← new scene (Editor)
        └── ResultsScreen.gd     ← new script, co-located

scripts/
└── data_models/
    └── RunSummary.gd            ← new RefCounted data class
```

**Modified files**:

```text
scripts/managers/RunManager.gd        ← add enemies_slain, run_summary; update start_run, end_run, _on_enemy_defeated
scripts/dungeon/RoomLoader.gd         ← connect run_ended, free room on run end
scenes/core/Main.gd                  ← connect run_ended, show ResultsScreen, handle return
scenes/ui/hud/ExplorationHUD.gd      ← connect run_ended to hide HUD on all end-run paths
```

**Structure Decision**: Single Godot project. New scene in `scenes/ui/run_end/` (co-located script per convention). New data model in `scripts/data_models/` (shared by RunManager and ResultsScreen).

## Implementation Design

### Signal & Data Flow

```
RunManager.end_run(reason)
  │
  ├─ compute cashed_out
  ├─ enemies_slain += 0  (already accumulated during run)
  ├─ RunSummary.create(cashed_out, enemies_slain, cleared_rooms.size(), reason)
  │   → stored as RunManager.run_summary
  │
  └─ emit run_ended(reason)
        │
        ├─ RoomLoader._on_run_ended()
        │     → _current_room_node.queue_free()
        │     → RunManager.current_room = null
        │
        ├─ ExplorationHUD._on_gameplay_ended()
        │     → visible = false
        │
        └─ Main._on_run_ended()
              → instantiate ResultsScreen
              → ResultsScreen.setup(RunManager.run_summary)
              → add_child(screen)
              → screen.return_pressed.connect(_on_results_return)

ResultsScreen — "Return" tapped
  └─ emit return_pressed
        └─ Main._on_results_return()
              → screen.queue_free()
              → _hub_room = HubRoom.instantiate()
              → add_child(_hub_room)
              → _hub_room.hub_exited.connect(_on_hub_exited)
```

### ResultsScreen label format

| Stat | Label text format |
|---|---|
| Essence | `"Essence Found: {n}"` |
| Enemies | `"Enemies Slain: {n}"` |
| Rooms | `"Rooms Cleared: {n}"` |

All values from `RunSummary`. Format strings use `String.format()` with named keys per constitution.

### Return button guard

`ResultsScreen._return_activated: bool = false` — set to `true` on first press; subsequent presses are no-ops. Prevents double-tap hub duplication.

## Phase 0 — Research

All decisions resolved. See `research.md` for rationale on:
- Results screen display method (Main child, not scene change or overlay)
- Room teardown ownership (RoomLoader, not Main or RunManager)
- RunSummary passing strategy (stored on RunManager, read after signal)
- ExplorationHUD hiding fix (connect run_ended directly)
- enemies_slain counter location (RunManager session field)

## Phase 1 — Design Artifacts

- `data-model.md` — RunSummary fields, RunManager additions, existing field usage
- `contracts/interfaces.md` — Full GDScript signatures for all new and modified scripts
- `quickstart.md` — 12 manual validation scenarios
