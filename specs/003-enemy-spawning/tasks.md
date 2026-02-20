# Tasks: Enemy Spawning

**Input**: Design documents from `specs/003-enemy-spawning/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅
**Tests**: No test tasks — not requested in specification.
**Organization**: Tasks grouped by user story; each story is independently implementable and testable.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: User story this task belongs to ([US1]–[US4])

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create data schema and data model scripts that all user story phases depend on.

- [x] T001 Extend data/dungeon_config.json: add top-level "spawn_configs" key; add CombatRoom01 entry (2× slime, positions x=-100/+100 y=0, radius=0) and CombatRoom02 entry (1× skeleton, position x=0 y=0, radius=0) — data/dungeon_config.json
- [x] T002 [P] Create SpawnPointData.gd: class_name SpawnPointData extends RefCounted with fields enemy_id:String, position:Vector2, radius:float and static factory func from_dict(d:Dictionary)->SpawnPointData — scripts/data_models/SpawnPointData.gd
- [x] T003 [P] Create RoomSpawnConfig.gd: class_name RoomSpawnConfig extends RefCounted with fields room_id:String, spawn_points:Array[SpawnPointData] and static factory func from_dict(room_id:String, d:Dictionary)->RoomSpawnConfig — scripts/data_models/RoomSpawnConfig.gd

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infrastructure that MUST be in place before any user story can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T004 [P] Add ResourceManager helpers to autoload/ResourceManager.gd: func get_dungeon_config()->Dictionary (loads and returns parsed data/dungeon_config.json, caches result) and func enemy_id_exists(id:String)->bool (checks id against loaded enemies.json array) — autoload/ResourceManager.gd
- [x] T005 [P] Add cleared-room state to autoload/RunManager.gd: var cleared_rooms:Dictionary={}, func mark_room_cleared(room_id:String)->void, func is_room_cleared(room_id:String)->bool; also reset cleared_rooms={} in the existing new-run start method — autoload/RunManager.gd
- [ ] T006 [P] In the Godot Editor, add Player node (scenes/player/Player.tscn root) to the group named "player" via the Node → Groups panel — scenes/player/Player.tscn

**Checkpoint**: Foundation ready — all user story phases can now begin.

---

## Phase 3: User Story 1 — Room Populates with Enemies on Entry (Priority: P1) 🎯 MVP

**Goal**: When the player enters a room, all configured enemies are instantiated at their spawn positions before the player can act.

**Independent Test**: Configure CombatRoom01 with 2 slime spawn points. Enter the room. Confirm 2 Slime enemies appear within 0.5 seconds. (Quickstart Scenario 1)

- [x] T007 [US1] Create RoomSpawner.gd: @export var room_id:String; signal room_cleared; const ENEMY_SCENE=preload("res://scenes/combat/enemies/Enemy.tscn"); const MAX_ENEMIES=10; @onready var _entry_area:Area2D=$EntryArea; var _config:RoomSpawnConfig; var _living_count:int=0; var _spawned:bool=false; implement _ready() (call _load_config, connect _entry_area.body_entered→_on_player_entered), _load_config()->RoomSpawnConfig (read via ResourceManager.get_dungeon_config, parse into RoomSpawnConfig, validate count≤10 and all enemy_ids exist via ResourceManager.enemy_id_exists, push_error and return empty config on failure), _on_player_entered(body) stub (guard: body in "player" group, return if _spawned; call _spawn_enemies), _spawn_enemies() (set _spawned=true, set _living_count, for each SpawnPointData instantiate Enemy.tscn, set enemy_type_id, add_child, set global_position to spawn centre); leave _on_enemy_defeated as empty func for US3 — scenes/dungeon/RoomSpawner.gd
- [ ] T008 [P] [US1] In the Godot Editor: open CombatRoom01.tscn, add child Area2D named EntryArea (Layer=0 Mask=1), add CollisionShape2D child with RectangleShape2D sized to room floor; add child Node named RoomSpawner, attach script res://scenes/dungeon/RoomSpawner.gd, set room_id="CombatRoom01" in Inspector — scenes/dungeon/rooms/CombatRoom01.tscn
- [ ] T009 [P] [US1] In the Godot Editor: open CombatRoom02.tscn, add EntryArea (Area2D, Layer=0 Mask=1, RectangleShape2D child) and RoomSpawner node (attach RoomSpawner.gd), set room_id="CombatRoom02" — scenes/dungeon/rooms/CombatRoom02.tscn

**Checkpoint**: US1 complete — enter CombatRoom01, 2 slimes appear; enter CombatRoom02, 1 skeleton appears.

---

## Phase 4: User Story 2 — Enemy Composition Defined in Game Data (Priority: P2)

**Goal**: Room variety is controlled entirely by dungeon_config.json; zero code changes are needed to change which enemies appear in a room.

**Independent Test**: Change CombatRoom01's enemy_id from "slime" to "skeleton" in dungeon_config.json; relaunch game; confirm skeletons appear — no code changes made. (Quickstart Scenario 3)

- [x] T010 [P] [US2] Extend data/dungeon_config.json: add EliteRoom01 entry with 2 spawn points — one "slime" (position x=-80 y=0, radius=0) and one "skeleton" (position x=80 y=0, radius=0) — demonstrating mixed enemy composition with zero code changes — data/dungeon_config.json
- [ ] T011 [P] [US2] In the Godot Editor: open EliteRoom01.tscn, add EntryArea (Area2D, Layer=0 Mask=1, RectangleShape2D child) and RoomSpawner node (attach RoomSpawner.gd), set room_id="EliteRoom01" — scenes/dungeon/rooms/EliteRoom01.tscn

**Checkpoint**: US2 complete — enter EliteRoom01, a slime and skeleton appear; changing dungeon_config.json changes who spawns with no code edits.

---

## Phase 5: User Story 3 — Room Clears When All Enemies Are Defeated (Priority: P3)

**Goal**: The room tracks living enemies. When the last is defeated, the room transitions to cleared state immediately and prevents re-spawning on re-entry.

**Independent Test**: Spawn 2 enemies in CombatRoom01; defeat both; confirm room_cleared signal fires the same frame; re-enter room; confirm no enemies spawn. (Quickstart Scenario 4)

- [x] T012 [US3] Complete _on_enemy_defeated in scenes/dungeon/RoomSpawner.gd: decrement _living_count; if _living_count==0 call RunManager.mark_room_cleared(room_id) then emit room_cleared; also update _on_player_entered to call RunManager.is_room_cleared(room_id) and return early if true (preventing re-spawn); connect each spawned enemy's defeated signal to _on_enemy_defeated inside _spawn_enemies — scenes/dungeon/RoomSpawner.gd

**Checkpoint**: US3 complete — defeat all enemies in a room; re-enter; no new enemies appear.

---

## Phase 6: User Story 4 — Randomised Spawn Positions (Priority: P4)

**Goal**: Each spawn point has a configurable radius. Enemies appear at a random position within that radius, producing variety between runs.

**Independent Test**: Set radius=50 on a CombatRoom01 spawn point; run twice; confirm enemy start positions differ by ≥1 unit on at least one axis and both remain within 50 units of the configured centre. (Quickstart Scenario 5)

- [x] T013 [US4] Add position randomisation to _spawn_enemies in scenes/dungeon/RoomSpawner.gd: after add_child(enemy), compute offset=Vector2(randf_range(-sp.radius, sp.radius), randf_range(-sp.radius, sp.radius)) and set enemy.global_position = sp.position + offset (when sp.radius==0 offset is zero, exact position preserved) — scenes/dungeon/RoomSpawner.gd
- [x] T014 [P] [US4] Update data/dungeon_config.json: set CombatRoom01 spawn points to radius=30 (non-zero, enables randomisation verification); keep CombatRoom02 skeleton at radius=0 (verifies exact-position behaviour); update EliteRoom01 points with radius=20 each — data/dungeon_config.json

**Checkpoint**: US4 complete — two runs of CombatRoom01 produce different enemy start positions; CombatRoom02 produces identical positions.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Remaining room setup, full-scenario validation, and housekeeping from prior features.

- [ ] T015 [P] In the Godot Editor: open BossRoom01.tscn, add EntryArea (Area2D, Layer=0 Mask=1, RectangleShape2D child) and RoomSpawner node (attach RoomSpawner.gd), set room_id="BossRoom01"; add BossRoom01 entry to data/dungeon_config.json with placeholder spawn points (to be tuned by designer) — scenes/dungeon/rooms/BossRoom01.tscn
- [ ] T016 [P] Run all quickstart.md validation scenarios (1–7): room populates, empty room, data-driven composition, cleared state + no re-spawn, randomised positions, invalid enemy ID error, >10 enemies error — specs/003-enemy-spawning/quickstart.md
- [x] T017 [P] Remove debug print statement from scenes/player/components/CombatComponent.gd: delete the line `print("AttackArea body_entered: ..."` (carried over from 002-enemy-combat debugging) — scenes/player/components/CombatComponent.gd

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately. T002 and T003 run in parallel.
- **Foundational (Phase 2)**: Depends on Phase 1 completion. T004, T005, T006 run in parallel.
- **US1 (Phase 3)**: Depends on Phase 2 completion. T007 first; T008 and T009 parallel after T007.
- **US2 (Phase 4)**: Depends on Phase 3 (needs RoomSpawner.gd from T007). T010 and T011 run in parallel.
- **US3 (Phase 5)**: Depends on Phase 3 (extends T007's RoomSpawner.gd). T012 sequential (same file as T007).
- **US4 (Phase 6)**: Depends on Phase 5 (extends RoomSpawner.gd again). T013 sequential after T012; T014 parallel with T013.
- **Polish (Phase 7)**: Depends on all user story phases complete. T015, T016, T017 all run in parallel.

### Within-Phase File Conflicts

| Tasks | File | Constraint |
|-------|------|-----------|
| T007, T012, T013 | scenes/dungeon/RoomSpawner.gd | Sequential: T007 → T012 → T013 |
| T001, T010, T014, T015 | data/dungeon_config.json | Sequential per phase; T001 (Phase 1) → T010 (Phase 4) → T014 (Phase 6) → T015 (Phase 7) |

---

## Parallel Execution Examples

### Phase 1: Setup

```text
Parallel (T002 + T003 simultaneously):
  Task A: "Create SpawnPointData.gd in scripts/data_models/SpawnPointData.gd"
  Task B: "Create RoomSpawnConfig.gd in scripts/data_models/RoomSpawnConfig.gd"
Sequential before above:
  T001: extend dungeon_config.json (establishes the JSON shape both models parse)
```

### Phase 2: Foundational

```text
All three parallel:
  Task A: "Add ResourceManager helpers in autoload/ResourceManager.gd"
  Task B: "Add cleared_rooms state to autoload/RunManager.gd"
  Task C: "Add Player to 'player' group in Godot Editor"
```

### Phase 3: US1

```text
Sequential then parallel:
  T007: "Create RoomSpawner.gd"                    ← must complete first
  T008 ‖ T009: "Editor: add nodes to CombatRoom01" ‖ "Editor: add nodes to CombatRoom02"
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T006) — CRITICAL gate
3. Complete Phase 3: US1 (T007–T009)
4. **STOP and VALIDATE**: Run Quickstart Scenario 1 — enemies appear on room entry
5. Feature is usable; combat system now has enemies to fight

### Incremental Delivery

1. Setup + Foundational → data and infrastructure ready
2. US1 (T007–T009) → enemies spawn on entry (**MVP**)
3. US2 (T010–T011) → designer can change enemy types with zero code changes
4. US3 (T012) → rooms become clearable; re-entry safe
5. US4 (T013–T014) → position variety across runs
6. Polish (T015–T017) → all rooms set up, full validation

### Notes

- T008, T009, T011, T015 are Godot Editor tasks — they require opening the editor and cannot be done via code alone
- Editor tasks: always save the scene (Ctrl+S) after adding nodes before committing
- When implementing T007, write the full file first then T012/T013 extend it with specific functions — avoid rewriting whole-file
- T016 (quickstart validation) should be run in the Godot editor play mode, not code-only
