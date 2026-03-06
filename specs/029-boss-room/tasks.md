# Tasks: Boss Room

**Input**: Design documents from `specs/029-boss-room/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: Foundational (Data Layer + Schema Consumers)

**Purpose**: Restructure enemies.json, add boss data, update both consumers of the new schema. MUST complete before US1 or US2 work can begin — Enemy.gd and ResourceManagerImpl will crash on the new JSON until updated.

**⚠️ CRITICAL**: T001 (enemies.json) and T006 (Enemy.gd) must both land before any enemy spawning is tested. T004 (ResourceManagerImpl) and T005 (autoload wrapper) must both land before the button threshold can be read.

- [X] T001 [P] Rewrite data/enemies.json: change `"enemies"` from flat array to category dict `{"common": [...], "boss": [...]}` with slime + skeleton in common and new boss entry (`max_health: 40, damage: 5, damage_cooldown: 2, rooms_required: 6`) in boss — see plan.md Phase 1 for full JSON
- [X] T002 [P] Add `"BossRoom01"` entry to `spawn_configs` in data/dungeon_config.json with one spawn point `{enemy_id: "boss", position: {x:0,y:0}, radius: 0}`
- [X] T003 [P] Add `var rooms_required: int = 0` to scripts/data_models/EnemyData.gd and parse it in `from_dict()` with `d.rooms_required = int(data.get("rooms_required", 0))`
- [X] T004 [P] Update scripts/managers/ResourceManager.gd (ResourceManagerImpl): add `_enemy_rooms_required_cache: Dictionary = {}` field; replace `_load_enemy_data()` flat-array loop with nested category-dict iteration (see contracts/interfaces.md); add `get_enemy_rooms_required(id: String) -> int` method
- [X] T005 Add `get_enemy_rooms_required(id: String) -> int` wrapper to autoload/ResourceManager.gd (depends T004)
- [X] T006 [P] Update scenes/combat/enemies/Enemy.gd `_ready()` lookup: replace `var enemies_array: Array = parsed["enemies"]` flat loop with category-dict iteration over `parsed.get("enemies", {}).values()` (see contracts/interfaces.md)

**Checkpoint**: All enemy data loads cleanly from the new schema. Existing slime/skeleton enemies still spawn correctly.

---

## Phase 2: User Story 1 — Boss Spawns with Scaled HP (Priority: P1) 🎯 MVP

**Goal**: Teleporting to the boss room spawns exactly one boss enemy whose HP equals `base_hp × (1 + 0.06 × rooms_cleared)` at the moment of teleport.

**Independent Test**: Use DevPanel "Start Boss" stub (or call `_on_boss_teleport_pressed()` directly from DevPanel) → boss room appears → one enemy spawns → inspect `StatsComponent.max_health` in debugger (≈ 40.0 with 0 rooms cleared, ≈ 54.4 with 6 rooms cleared).

- [X] T007 [US1] Add `free_current_room() -> void` public method to scripts/dungeon/RoomLoader.gd (null-guard, clears `_current_room_node` and `RunManager.current_room` — see contracts/interfaces.md)
- [X] T008 [US1] Add to scenes/core/Main.gd: `const _BOSS_ROOM_DATA := preload("res://data/rooms/BossRoom01.tres")`, `const BOSS_ROOM_WORLD_POS: Vector2 = Vector2(0.0, -3000.0)`, and `@onready var _room_loader: RoomLoader = $RoomLoader`
- [X] T009 [US1] Add `_on_boss_teleport_pressed()` method to scenes/core/Main.gd: calls `_room_loader.free_current_room()`, computes `boss_mult = 1.0 + 0.06 * float(RunManager.cleared_rooms.size())`, spawns `_BOSS_ROOM_DATA` via `RunManager.spawn_room()` at `BOSS_ROOM_WORLD_POS`, sets `spawner.difficulty_mult = boss_mult`, places player and camera at `BOSS_ROOM_WORLD_POS` (see contracts/interfaces.md for full method)
- [X] T010 [US1] Extend `_process()` in scenes/core/Main.gd: add `else` branch after the `rooms_by_id.has(room_id)` check — `_camera.global_position = (RunManager.current_room as RoomSpawner).get_parent().global_position` — so camera tracks the boss room without requiring it in `rooms_by_id`

**Checkpoint**: Calling `_on_boss_teleport_pressed()` (wired via DevPanel or test hook) transports player to boss room, camera snaps to `(0, −3000)`, one boss enemy spawns with HP scaling applied.

---

## Phase 3: User Story 2 — "Teleport to Boss" Button Unlock Gate (Priority: P2)

**Goal**: The "Teleport to Boss" button in ExplorationHUD is hidden until the player has cleared at least `rooms_required` rooms in the current run. Pressing it triggers the teleport from Phase 2.

**Independent Test**: Start run → clear 5 rooms → confirm button invisible → clear 6th room → confirm button appears → press it → player transported to boss room.

- [X] T011 [P] [US2] Add boss button logic to scenes/ui/hud/ExplorationHUD.gd: `const BOSS_ENEMY_ID: String = "boss"`, `signal boss_teleport_pressed`, `@export var _boss_button: Button`; in `_ready()` add `_boss_button.visible = false`, connect `_boss_button.pressed`, `RunManager.room_cleared`, and `RunManager.run_started` (to reset button); add `_on_room_cleared_for_boss()` (checks `cleared_rooms.size() >= ResourceManager.get_enemy_rooms_required(BOSS_ENEMY_ID)`) and `_on_boss_button_pressed()` (hide button, emit signal) — see contracts/interfaces.md
- [X] T012 [P] [US2] In scenes/core/Main.gd `_ready()`, add `_exploration_hud.boss_teleport_pressed.connect(_on_boss_teleport_pressed)` after the existing signal connections
- [ ] T013 [US2] In Godot Editor: open scenes/ui/hud/ExplorationHUD.tscn, add a `Button` child node named `BossButton` with text `"Teleport to Boss"`, then assign it to the `_boss_button` export on the ExplorationHUD script in the Inspector (requires T011 to be saved first)

**Checkpoint**: Button invisible before 6 rooms cleared. Button appears on the 6th clear. Pressing it runs the full teleport flow from US1.

---

## Phase 4: Polish

- [ ] T014 Run all 7 quickstart scenarios from specs/029-boss-room/quickstart.md

---

## Dependencies & Execution Order

- **T001–T004**: No cross-dependencies — all modify different files; run in parallel
- **T005**: Depends on T004 (method must exist in impl before wrapping)
- **T006**: Can run in parallel with T004 (different files; both consume the new JSON schema)
- **T007**: No dependencies; can start immediately after Phase 1 is complete
- **T008**: No dependencies on Phase 2 tasks; can start immediately after Phase 1
- **T009**: Depends on T007 (calls `free_current_room`) and T008 (uses `_BOSS_ROOM_DATA`, `_room_loader`)
- **T010**: No dependencies within Phase 2; can parallel T007/T008 (same file as T008, but targets `_process()`)
- **T011**: No dependencies on T007–T010; can start after Phase 1 (different file)
- **T012**: Can parallel T011 (different file — Main.gd vs ExplorationHUD.gd); requires T009 to exist (references `_on_boss_teleport_pressed`)
- **T013**: Depends on T011 (export must exist in script before Inspector assignment)
- **T014**: Depends on all prior tasks

### Parallel Opportunities

```
Phase 1 (run together):
  T001  enemies.json rewrite
  T002  dungeon_config.json BossRoom01 entry
  T003  EnemyData.gd rooms_required field
  T004  ResourceManagerImpl loop + cache + method
  T006  Enemy.gd lookup loop update

  Then T005 (ResourceManager autoload wrapper — after T004)

Phase 2 (run together after Phase 1):
  T007  RoomLoader.free_current_room()
  T008  Main.gd declarations

  Then T009 (after T007 + T008)
  Then T010 (after T008; can parallel T009 — same file, different method)

Phase 3 (run together after Phase 1 + T009):
  T011  ExplorationHUD.gd boss button
  T012  Main.gd signal connection

  Then T013 (editor — after T011)
```

---

## Implementation Strategy

### MVP (US1 only)
1. Complete Phase 1 (data layer + schema consumers)
2. Complete T007–T010 (boss spawn + HP scaling + camera)
3. Validate via quickstart scenarios 1–2 (boss HP at 0 and 6 rooms cleared)

### Full Feature
4. Complete T011–T013 (button unlock gate)
5. Validate via quickstart scenarios 3–7

### Notes
- All Phase 1 tasks can be coded before opening Godot Editor; T013 requires the Editor
- T001 + T006 must be committed together — the JSON schema change and the Enemy.gd consumer update are a matched pair; testing with only one breaks enemy spawning
- RoomLoader.gd is at `scripts/dungeon/RoomLoader.gd` (not `scenes/`) — use the correct path
