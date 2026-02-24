# Tasks: Dungeon Generator

**Input**: Design documents from `specs/007-dungeon-generator/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Setup adds the data config key. Foundational adds the RunManager signal that
DungeonGenerator connects to. Core phase delivers US1 + US2 together (room spawning and player
placement are the same script, same loop — inseparable). Editor task wires it into the scene.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Setup — Data Config

**Purpose**: Add `room_sequence` to `dungeon_config.json` so the generator has data to read.
No code depends on this at parse time, so it can be done independently.

- [x] T001 Add `"room_sequence": ["CombatRoom01", "CombatRoom02", "EliteRoom01"]` as the first key in `data/dungeon_config.json` (before `"spawn_configs"`). Result: `{ "room_sequence": [...], "spawn_configs": { ... } }` — `data/dungeon_config.json`

**Checkpoint**: `dungeon_config.json` parses as valid JSON. `room_sequence` key exists and contains exactly 3 strings.

---

## Phase 2: Foundational — RunManager Signal

**Purpose**: `DungeonGenerator` connects to `RunManager.run_started` in `_ready()`. The signal
must exist in RunManager before the generator script can be written and used.

**⚠️ CRITICAL**: T001 must be complete before this phase only for test purposes; T002 can start
in parallel with T001 since they touch different files.

- [x] T002 [P] Update `autoload/RunManager.gd`: add `## Emitted at the end of start_run(), after all state is reset.\nsignal run_started(mode: String)` in the signals block (after `signal room_cleared`); add `run_started.emit(mode)` as the final line of `start_run()` — `autoload/RunManager.gd`

**Checkpoint**: Project compiles. `RunManager.run_started` exists as a typed signal.

---

## Phase 3: User Stories 1 + 2 — Room Spawning & Player Placement (Priority: P1) 🎯 MVP

**Goal**: `DungeonGenerator` reacts to `RunManager.run_started`, spawns the configured room
sequence in a horizontal line, and places the player at the first room's position.
US1 (rooms) and US2 (player placement) are delivered together — both live in the same script
and the same `_generate()` call.

**Independent Test**: Start a run. Confirm three rooms appear in the scene tree at x=0, 1200, 2400.
Confirm player's `global_position` matches the first room's position.

### Implementation

- [x] T003 [US1] Create `scenes/dungeon/DungeonGenerator.gd`: `class_name DungeonGenerator extends Node`; `const ROOM_SPACING: int = 1200`; `func _ready() -> void` connects `RunManager.run_started` to `_on_run_started`; `func _on_run_started(_mode: String) -> void` calls `_generate()`; `func _generate() -> void` — reads `raw: Dictionary = ResourceManager.get_dungeon_config()`, gets `sequence: Array = raw.get("room_sequence", [])`, push_error + return if empty, loops `for i: int in range(sequence.size())` — for each: `type_id: String = sequence[i]`, `room_data: RoomData = load("res://data/rooms/{id}.tres".format({"id": type_id}))`, push_error + break if null, `pos: Vector2 = global_position + Vector2(i * ROOM_SPACING, 0)`, `context: SpawnContext = SpawnContext.create(get_parent(), pos)`, `spawner: RoomSpawner = RunManager.spawn_room(room_data, "room_{i}".format({"i": i}), context)`, push_error + break if null, track `first_room_pos = pos` when `i == 0`, print success with .format(); after loop call `_place_player(first_room_pos)` if at least one room spawned — `scenes/dungeon/DungeonGenerator.gd`
- [x] T004 [US2] Add `func _place_player(target_pos: Vector2) -> void` to `scenes/dungeon/DungeonGenerator.gd`: `var player: Node = get_tree().get_first_node_in_group("player")`; push_error + return if null; `player.global_position = target_pos`; `print("[DungeonGenerator] player placed at {pos}".format({"pos": target_pos}))` — `scenes/dungeon/DungeonGenerator.gd`
- [ ] T005 In the Godot Editor: open `scenes/core/Main.tscn`; add a `Node` child named `DungeonGenerator` to the Main root; attach `scenes/dungeon/DungeonGenerator.gd` as its script; delete the pre-placed `CombatRoom01` and `CombatRoom02` child instances; save the scene — `scenes/core/Main.tscn`

**Checkpoint**: US1 + US2 complete. Press Play — three rooms appear at correct positions. Player starts in first room. `room_entered` fires on player entry. No errors in Output.

---

## Phase 4: Polish & Validation

**Purpose**: Confirm all quickstart scenarios pass end-to-end.

- [ ] T006 Run all 7 quickstart.md validation scenarios: three rooms spawn on run start; rooms spaced 1200 px apart; room IDs are `"room_0"`, `"room_1"`, `"room_2"`; player placed at first room position; `room_entered` fires on player entry; missing RoomData logs error and stops gracefully; re-starting run spawns a new set of rooms — `specs/007-dungeon-generator/quickstart.md`

---

## Dependencies & Execution Order

```text
T001 [P]              T002 [P]
(dungeon_config.json) (RunManager signal)
       \                /
        v              v
          T003 (DungeonGenerator._generate)
               |
               v
          T004 (DungeonGenerator._place_player)
               |
               v
          T005 (Editor: add node, remove pre-placed)
               |
               v
          T006 (validate)
```

| Relationship | Constraint |
|---|---|
| T001 ‖ T002 | Different files — parallel |
| T001 + T002 before T003 | Generator reads config (T001) and connects signal (T002) |
| T003 before T004 | T004 adds a method to the file T003 creates |
| T004 before T005 | Editor task needs the script to exist before attaching |
| T005 before T006 | Full integration required before validation |

---

## Parallel Opportunities

```
# Phase 1 + 2 — run together:
T001: Add room_sequence to dungeon_config.json
T002: Add run_started signal to RunManager.gd
```

---

## Implementation Strategy

### MVP (US1 + US2 delivered together)

1. Complete T001 + T002 in parallel (data + signal)
2. Complete T003 (DungeonGenerator._generate)
3. Complete T004 (DungeonGenerator._place_player)
4. Complete T005 in Godot Editor (add node, remove pre-placed rooms)
5. Complete T006 (validate all 7 scenarios)

---

## Notes

- T005 is an Editor task — must be done in Godot after T004 completes (script must exist before it can be attached).
- 006-room-factory T003 (`.tres` assets in `data/rooms/`) must be complete before T006 validation. If not done yet, do it in the Editor before running quickstart.
- `ROOM_SPACING` is a GDScript constant (1200 px) — not in JSON. It's a layout constant, not a balance parameter. Promote to config when dungeon layout becomes procedural.
- All print statements MUST use `.format()` with named keys. `%` specifiers are prohibited (constitution v1.1.1).
- Mark tasks `[x]` after completion.
