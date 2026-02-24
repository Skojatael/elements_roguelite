# Tasks: Room Factory

**Input**: Design documents from `specs/006-room-factory/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Setup creates the two data classes. Foundational creates the `.tres` room assets
(Editor task). Core phase implements RoomFactory and wires it into RoomSpawner and RunManager.
Factory returns `RoomSpawner` directly — no wrapper class.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Setup — Data Classes

**Purpose**: `RoomData` and `SpawnContext` are parameter types used in every subsequent signature.
Both must parse before any other script references them.

- [x] T001 [P] Create `scripts/data_models/RoomData.gd`: `class_name RoomData extends Resource`; `@export var room_type_id: String = ""`; `@export var scene: PackedScene` — `scripts/data_models/RoomData.gd`
- [x] T002 [P] Create `scripts/data_models/SpawnContext.gd`: `class_name SpawnContext extends RefCounted`; `var parent: Node`; `var position: Vector2`; `static func create(p_parent: Node, p_position: Vector2) -> SpawnContext` that sets both fields and returns the instance — `scripts/data_models/SpawnContext.gd`

**Checkpoint**: Both scripts load without errors. Project compiles cleanly.

---

## Phase 2: Foundational — Room Assets (Editor Task)

**Purpose**: `.tres` assets must exist before callers can load them and before quickstart validation.
This is a Godot Editor task — cannot be scripted.

**⚠️ CRITICAL**: T001 must be complete before this phase (RoomData class must exist to create
`.tres` instances of it).

- [ ] T003 In the Godot Editor, create folder `data/rooms/`; create four resources via right-click → New Resource → RoomData: `CombatRoom01.tres` (`room_type_id="CombatRoom01"`, scene=`CombatRoom01.tscn`), `CombatRoom02.tres` (`room_type_id="CombatRoom02"`, scene=`CombatRoom02.tscn`), `EliteRoom01.tres` (`room_type_id="EliteRoom01"`, scene=`EliteRoom01.tscn`), `BossRoom01.tres` (`room_type_id="BossRoom01"`, scene=`BossRoom01.tscn`) — `data/rooms/`

**Checkpoint**: All four `.tres` files appear in the FileSystem dock. Opening each in the Inspector
shows both fields filled correctly.

---

## Phase 3: User Story 1 — Request a Room by Type and Receive a Spawner (Priority: P1) 🎯 MVP

**Goal**: `RunManager.spawn_room(room_data, room_id, context)` instantiates the correct room scene,
attaches it under the specified parent at the specified position, and returns the `RoomSpawner`.
Caller supplies `room_id` — neither factory nor RunManager generates it.
US2 (lifecycle signals) is delivered in the same phase — RunManager connects to `RoomSpawner`
signals directly, exactly as `register_room` does today.

**Independent Test**: Load `CombatRoom01.tres`, call `RunManager.spawn_room(room_data, "room_01", context)`,
confirm the room appears at the correct position and a non-null RoomSpawner is returned. Confirm
`room_entered` and `room_cleared` fire on player entry and enemy defeat.

### Implementation

- [x] T004 [US1] Create `scenes/dungeon/RoomFactory.gd`: `class_name RoomFactory extends RefCounted`; `func spawn_room(room_data: RoomData, room_id: String, context: SpawnContext) -> RoomSpawner` — validate `room_data != null` and `room_data.scene != null` (push_error + return null if invalid); instantiate `room_data.scene`; locate `RoomSpawner` child via `get_node("RoomSpawner")`; set `spawner.room_id = room_id` and `spawner.auto_register = false` before `add_child`; call `context.parent.add_child(room_root)`; set `room_root.global_position = context.position`; return `spawner`; log success and errors with `.format()` — `scenes/dungeon/RoomFactory.gd`
- [x] T005 [US1] Update `scenes/dungeon/RoomSpawner.gd`: add `@export var auto_register: bool = true` on the line after `@export var room_id`; in `_ready()` wrap `RunManager.register_room(self)` with `if auto_register:` — `scenes/dungeon/RoomSpawner.gd`
- [x] T006 [US1] Update `autoload/RunManager.gd`: add `var room_factory: RoomFactory` field; initialize `room_factory = RoomFactory.new()` in `_ready()`; add `func spawn_room(room_data: RoomData, room_id: String, context: SpawnContext) -> RoomSpawner` that delegates to `room_factory.spawn_room(...)`, on non-null result connects `spawner.room_entered` → `_on_room_entered.bind(spawner)` and `spawner.room_cleared` → `_on_room_cleared`, sets `current_room = spawner`, and returns spawner; `register_room()` and `_on_room_entered` signatures unchanged — `autoload/RunManager.gd`

**Checkpoint**: US1 + US2 complete. `RunManager.spawn_room(...)` returns a RoomSpawner. Room
appears in world at correct position. `room_entered` and `room_cleared` fire correctly.
Pre-placed rooms still work via `register_room` (auto_register=true default).

---

## Phase 4: Polish & Validation

**Purpose**: Confirm all quickstart scenarios pass end-to-end.

- [ ] T007 Run all 7 quickstart.md validation scenarios: factory spawns CombatRoom01 at correct position; null RoomData returns null with error logged; factory room does NOT trigger register_room; room_entered fires on player entry; room_cleared fires after all enemies defeated; pre-placed rooms unaffected; room_id is never generated by factory or RunManager — `specs/006-room-factory/quickstart.md`

---

## Dependencies & Execution Order

```text
T001 [P]        T002 [P]
(RoomData.gd)   (SpawnContext.gd)
	 |
	 v
   T003 (Editor: .tres assets)
	 |
	 v
   T004 (RoomFactory.gd)
	 v
   T005 (RoomSpawner — auto_register)
	 v
   T006 (RunManager — spawn_room)
	 v
   T007 (validate)
```

| Relationship | Constraint |
|---|---|
| T001 ‖ T002 | Different files — parallel |
| T001 before T003 | RoomData.gd must exist to create `.tres` instances |
| T001 + T002 before T004 | RoomFactory signature uses both RoomData and SpawnContext types |
| T003 before T004 | Practical: .tres assets needed to test factory output |
| T004 before T005 | Logical ordering; T005 is trivial but follows core factory |
| T005 before T006 | RunManager.spawn_room relies on auto_register=false behaviour |
| T006 before T007 | Full integration required before validation |

---

## Parallel Opportunities

```
# Phase 1 — run together:
T001: Create RoomData.gd
T002: Create SpawnContext.gd
```

---

## Implementation Strategy

### MVP (US1 + US2 delivered together)

1. Complete T001 + T002 in parallel (data classes)
2. Complete T003 in Godot Editor (`.tres` assets)
3. Complete T004 (RoomFactory)
4. Complete T005 (RoomSpawner auto_register flag)
5. Complete T006 (RunManager spawn_room wiring)
6. Complete T007 (validate all 7 scenarios)

---

## Notes

- T003 is an Editor task — must be done in the Godot Editor after T001 completes.
- `RoomSpawner.auto_register` is an `@export` — pre-placed rooms in the Editor keep the default
  `true` with no scene file changes required.
- `RunManager.register_room()` is unchanged — pre-placed rooms continue to work exactly as before.
- `RunManager.spawn_room()` uses the same signal-connection pattern as `register_room` — just
  via the factory path with `auto_register=false`.
- Mark tasks `[x]` after completion.
