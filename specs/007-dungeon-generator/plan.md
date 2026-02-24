# Implementation Plan: Dungeon Generator

**Branch**: `007-dungeon-generator` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/007-dungeon-generator/spec.md`

## Summary

On every `RunManager.start_run()` call, a `DungeonGenerator` node reads an ordered room sequence from `dungeon_config.json`, loads each room's `.tres` RoomData asset, calls `RunManager.spawn_room()` to instantiate them in a straight horizontal line, and teleports the player to the first room. The generator reacts to a new `RunManager.run_started` signal — no changes to Main.gd are required.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: RunManager (autoload), RoomFactory (via RunManager), ResourceManager (autoload), SpawnContext, RoomData — all existing
**Storage**: `data/dungeon_config.json` — one new key `room_sequence`; `data/rooms/*.tres` — RoomData assets (created in 006-room-factory Editor task T003)
**Testing**: Manual quickstart scenarios (see `quickstart.md`)
**Target Platform**: Android mobile, 1080×1920 portrait; Windows dev
**Project Type**: Godot 4.6 game scene
**Performance Goals**: 60 fps maintained; spawning 3 rooms at run start is a one-time cost, negligible
**Constraints**: Mobile renderer (no Forward+ effects); Jolt physics
**Scale/Scope**: 3 rooms per run (hard-coded sequence for now)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Single Responsibility | ✅ PASS | DungeonGenerator has one job: spawn rooms on run start. RunManager gains one signal (symmetric to `run_ended`). No existing script gains a second responsibility. |
| II. Data-Driven Content | ✅ PASS | Room sequence stored in `dungeon_config.json` (new `room_sequence` key). Room assets are `.tres` files. No dungeon parameters hard-coded in GDScript. `ROOM_SPACING` is a layout constant (not a balance parameter) — deferred to JSON when layout becomes procedural (YAGNI justified). |
| III. Mobile-First Performance | ✅ PASS | 3 room instantiations at run start is a one-time cost. No shaders or per-frame work introduced. |
| IV. Editor-Centric Workflow | ✅ PASS | DungeonGenerator node added to Main.tscn via Godot Editor. `.tscn` not edited as raw text. |
| V. Simplicity & YAGNI | ✅ PASS | No new autoloads. No abstractions (single script, no base class). No future hooks. Room sequence is the minimal data structure needed. |

**Post-design re-check**: All five principles pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/007-dungeon-generator/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── signals.md       ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code Changes

```text
scenes/dungeon/
└── DungeonGenerator.gd       ← NEW: generator script

autoload/
└── RunManager.gd             ← MODIFIED: add signal run_started + emit in start_run()

data/
└── dungeon_config.json       ← MODIFIED: add "room_sequence" key

scenes/core/
└── Main.tscn                 ← EDITOR TASK: add Node child, attach DungeonGenerator.gd
```

**No new autoloads.** DungeonGenerator is a scene-attached node, not a singleton.

## Implementation Design

### 1. RunManager — add `run_started` signal

```gdscript
## Emitted at the end of start_run(), after all state is reset.
signal run_started(mode: String)

func start_run(mode: String) -> void:
    # ... existing state reset ...
    print("[RunManager] run started — id={id} mode={mode}".format({...}))
    run_started.emit(mode)   # ← new, last line
```

### 2. dungeon_config.json — add room_sequence

```json
{
    "room_sequence": ["CombatRoom01", "CombatRoom02", "EliteRoom01"],
    "spawn_configs": { ... }
}
```

### 3. DungeonGenerator.gd

```gdscript
class_name DungeonGenerator
extends Node

const ROOM_SPACING: int = 1200

func _ready() -> void:
    RunManager.run_started.connect(_on_run_started)

func _on_run_started(_mode: String) -> void:
    _generate()

func _generate() -> void:
    var raw: Dictionary = ResourceManager.get_dungeon_config()
    var sequence: Array = raw.get("room_sequence", [])
    if sequence.is_empty():
        push_error("DungeonGenerator: room_sequence missing or empty in dungeon_config.json")
        return

    var origin: Vector2 = global_position
    var first_room_pos: Vector2 = Vector2.ZERO
    var spawned_count: int = 0

    for i: int in range(sequence.size()):
        var type_id: String = sequence[i]
        var room_data: RoomData = load("res://data/rooms/{id}.tres".format({"id": type_id}))
        if room_data == null:
			push_error("DungeonGenerator: RoomData not found for type='{type}'".format({"type": type_id}))
            break
        var pos: Vector2 = origin + Vector2(i * ROOM_SPACING, 0)
        var context: SpawnContext = SpawnContext.create(get_parent(), pos)
        var spawner: RoomSpawner = RunManager.spawn_room(room_data, "room_{i}".format({"i": i}), context)
        if spawner == null:
			push_error("DungeonGenerator: spawn_room returned null — type='{type}'".format({"type": type_id}))
            break
        if spawned_count == 0:
            first_room_pos = pos
        spawned_count += 1
		print("[DungeonGenerator] spawned type='{type}' id='room_{i}' at {pos}".format({"type": type_id, "i": i, "pos": pos}))

    if spawned_count > 0:
        _place_player(first_room_pos)

func _place_player(target_pos: Vector2) -> void:
    var player: Node = get_tree().get_first_node_in_group("player")
    if player == null:
		push_error("DungeonGenerator: player not found in group 'player'")
        return
    player.global_position = target_pos
    print("[DungeonGenerator] player placed at {pos}".format({"pos": target_pos}))
```

### 4. Main.tscn — Editor Task

Add a `Node` child named `DungeonGenerator` to Main.tscn and attach `DungeonGenerator.gd`. No script changes to Main.gd required. Remove pre-placed CombatRoom01 and CombatRoom02 instances (if not already done).

## Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| 006-room-factory T001-T006 | ✅ Done | RoomFactory, SpawnContext, RoomData classes exist |
| 006-room-factory T003 | ⚠️ Pending | `.tres` files must exist in `data/rooms/` before testing |
| RunManager `run_started` signal | New (T001) | Must exist before DungeonGenerator can connect |

## CLAUDE.md Update

Add to the **Enemy spawning** section or create a new **Dungeon generation** section:

```
### Dungeon generation (007-dungeon-generator)

- `scenes/dungeon/DungeonGenerator.gd` — Node child of Main; connects to
  `RunManager.run_started`; reads `dungeon_config.json → room_sequence`; calls
  `RunManager.spawn_room()` for each room type; places player at first room.
- `RunManager` emits `run_started(mode)` at the end of `start_run()`.
- Room sequence is configured in `data/dungeon_config.json` under `"room_sequence"`.
```
