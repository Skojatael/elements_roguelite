# Tasks: Room Wave System

**Input**: Design documents from `specs/056-wave-system/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: `WaveConfig.from_dict` is a static method with pure logic — GUT unit test is **mandatory**. `RoomSpawner` changes involve Node/autoload dependencies — tests optional, not included.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Data layer and data model must exist before `RoomSpawner` can consume them.

**⚠️ CRITICAL**: T001–T004 must be complete before Phase 2 and Phase 3 begin.

- [x] T001 Add top-level `"wave_config"` block to `data/dungeon_config.json`: `{ "waves": [3,2,1], "trigger_threshold": 1, "alive_cap": 4, "min_spawn_distance": 200.0 }`

- [x] T002 Expand `CombatRoom01` spawn points in `data/dungeon_config.json` to 4 entries at positions `(-350,-250)`, `(350,-250)`, `(-350,250)`, `(350,250)` with `radius: 40`, all `enemy_id: "slime"`

- [x] T003 Expand `CombatRoom02` spawn points in `data/dungeon_config.json` to 4 entries at positions `(-300,0)`, `(300,0)`, `(0,-250)`, `(0,250)` with `radius: 30`, all `enemy_id: "skeleton"`

- [x] T004 [P] Create `scripts/data_models/WaveConfig.gd` with `class_name WaveConfig extends Resource`, fields `waves: Array[int]`, `trigger_threshold: int = 1`, `alive_cap: int = 4`, `min_spawn_distance: float = 200.0`, and `static func from_dict(data: Dictionary) -> WaveConfig` that reads all four fields with safe defaults

- [x] T005 Add `var wave_config: WaveConfig` field to `scripts/data_models/RoomSpawnConfig.gd` (default `null`; no changes to `from_dict` signature)

- [x] T006 Write GUT unit tests for `WaveConfig.from_dict` in `tests/unit/test_wave_config.gd`. Cover:
  - Full valid dict populates all four fields correctly
  - Empty dict returns safe defaults (`waves=[]`, `trigger_threshold=1`, `alive_cap=4`, `min_spawn_distance=200.0`)
  - `waves` array values are stored as `int`
  - Use inline stub dicts only — no autoloads

**Checkpoint**: Data layer complete, `WaveConfig` tested. `RoomSpawner` changes can now begin.

---

## Phase 2: User Story 1 — Waves Spawn and Progress Automatically (Priority: P1) 🎯 MVP

**Goal**: Room entry triggers wave 1 (3 enemies); each wave fires when alive ≤ 1; room clears only after all 6 kills.

**Independent Test**: Enter CombatRoom01 → verify 3 enemies spawn → kill 2 → verify 2 more spawn (wave 2) → kill 2 → verify 1 more spawns (wave 3) → kill last → verify room cleared fires.

### Implementation for User Story 1

- [x] T007 [US1] In `scripts/dungeon/RoomSpawner.gd`, load wave config after `RoomSpawnConfig.from_dict()` in `_load_config()`: read `ResourceManager.get_dungeon_config().get("wave_config", {})`, call `WaveConfig.from_dict(...)`, assign to `cfg.wave_config`. If the resulting `waves` array is empty, leave `wave_config = null` (opt-out for rooms with no wave config).

- [x] T008 [US1] Add wave state fields to `scripts/dungeon/RoomSpawner.gd`: `var _wave_index: int = 0`, `var _total_killed: int = 0`, `var _total_enemies: int = 0`. These join the existing `_living_count: int` and `_spawned: bool`.

- [x] T009 [US1] Rename the existing `_spawn_enemies()` to `_spawn_enemies_legacy()` in `scripts/dungeon/RoomSpawner.gd` — no changes to its body. This preserves the original flat-spawn path for rooms with `wave_config == null`.

- [x] T010 [US1] Add `func _spawn_wave(wave_idx: int) -> void` to `scripts/dungeon/RoomSpawner.gd`:
  1. Guard: `if wave_idx >= _config.wave_config.waves.size(): return`
  2. `var wave_size: int = mini(_config.wave_config.waves[wave_idx], _config.wave_config.alive_cap - _living_count)`
  3. Guard: `if wave_size <= 0: return`
  4. Get player: `var player: Node2D = get_tree().get_first_node_in_group("player")`
  5. Copy and sort spawn points by descending distance from player (sort on `room_origin + sp.position`; if player is null, skip sort)
  6. For `i` in `wave_size`: pick `sorted_points[i % sorted_points.size()]`, instantiate enemy, apply difficulty, set global position with radius offset, connect `defeated` signal, increment `_living_count`
  7. Increment `_wave_index`
  8. Print: `[RoomSpawner] wave {idx} spawned {n} enemies — living={living}`

- [x] T011 [US1] In `scripts/dungeon/RoomSpawner.gd`, update `_on_player_entered()`: if `_config.wave_config != null`, set `_total_enemies` to sum of `_config.wave_config.waves` (use a loop), then call `_spawn_wave.call_deferred(0)`; else call `_spawn_enemies_legacy.call_deferred()`. Remove the old `_spawn_enemies.call_deferred()` call.

- [x] T012 [US1] In `scripts/dungeon/RoomSpawner.gd`, update `_on_enemy_defeated()`:
  - Always: `enemy_defeated.emit(enemy_type_id)`, decrement `_living_count`
  - If `wave_config != null`: increment `_total_killed`; if `_total_killed == _total_enemies` → `RunManager.mark_room_cleared`, `room_cleared.emit`, `return`; else if `_wave_index < _config.wave_config.waves.size()` and `_living_count <= _config.wave_config.trigger_threshold` → `_spawn_wave(_wave_index)`
  - If `wave_config == null` (legacy path): if `_living_count == 0` → `RunManager.mark_room_cleared`, `room_cleared.emit` (existing behaviour unchanged)

**Checkpoint**: Wave spawning and progression fully functional. Room clears after 6th kill.

---

## Phase 3: User Story 2 — Enemies Do Not Spawn on the Player (Priority: P2)

**Goal**: Every wave's enemies spawn at the farthest available spawn points from the player's current position.

**Independent Test**: Enter room and stand at center. All 3 wave-1 enemies spawn at corners (≥200 units away). Move to a corner; verify wave 2 enemies prefer the opposite corners.

### Implementation for User Story 2

- [x] T013 [US2] Verify that `_spawn_wave()` from T010 correctly sorts spawn points by player distance (the sorting logic was specified in T010 step 5 — confirm it uses `distance_to(player.global_position)` on `get_parent().global_position + sp.position`, descends, and falls back gracefully when player is null). No code change expected if T010 was implemented correctly; add a `push_warning` if player is null.

**Checkpoint**: Distance-sorted spawning confirmed. Both user stories complete.

---

## Phase 4: Polish & Validation

- [ ] T014 Run quickstart.md validation: enter CombatRoom01, observe all three waves, confirm alive count never exceeds 4, confirm room clear fires exactly on the 6th kill, confirm no enemy spawns within 200 units of a stationary player at room center

- [x] T015 Update `repo_map.md`: add `WaveConfig` entry under Scripts — Data Models; update `RoomSpawnConfig` entry (new `wave_config` field); update `RoomSpawner` entry (new methods `_spawn_wave`, `_spawn_enemies_legacy`; new fields `_wave_index`, `_total_killed`, `_total_enemies`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies — start immediately
- **Phase 2 (US1)**: Depends on T001–T005 (data + WaveConfig model must exist)
- **Phase 3 (US2)**: Depends on T010 (spawn_wave must exist to verify sorting); can overlap with T011–T012
- **Phase 4 (Polish)**: Depends on all implementation tasks complete

### Within Phase 1

- T001, T002, T003 are all JSON edits to the same file — do sequentially
- T004 (new GDScript file) is independent and parallelisable with T001–T003
- T005 depends on T004 (WaveConfig type must exist)
- T006 depends on T004

### Within Phase 2

- T007 depends on T004 + T005 (WaveConfig must be loadable from RoomSpawnConfig)
- T008 can be done alongside T007 (same file, different section)
- T009 can be done alongside T007–T008 (rename only)
- T010 depends on T007–T009 (fields and wave_config must exist)
- T011 depends on T010
- T012 depends on T010 + T011

### Parallel Opportunities

- T004 (new WaveConfig.gd) can run while T001–T003 are being edited
- T006 (unit tests) can be written alongside T001–T003 once T004 is done
- T007, T008, T009 can be done in a single editing pass on `RoomSpawner.gd`

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. T001–T005 — data layer complete
2. T006 — unit tests written and passing
3. T007–T012 — wave logic in RoomSpawner
4. **STOP and VALIDATE**: 6-kill room clear works correctly

### Full Delivery

5. T013 — confirm distance sorting (likely already correct from T010)
6. T014–T015 — validation + repo_map

---

## Notes

- T013 is expected to be a read-only verification — distance sorting was specified in T010
- The `_spawn_enemies_legacy()` rename (T009) is a safety measure; it keeps the old path intact for BossRoom01 and any future non-wave rooms
- EliteRoom01 has 2 spawn points; wave 1 needs 3 — cycling (`i % 2`) means one spawn point is used twice; this is acceptable and documented in research.md
- Commit after Phase 1 (data + model), then after Phase 2 (RoomSpawner complete)
