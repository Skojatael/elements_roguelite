# Tasks: Depth-Scaled Combat

**Input**: Design documents from `specs/059-depth-scaled-combat/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: `DepthTierConfig` has two pure static methods (`from_dict`, `find_for_depth`) — GUT unit test is **mandatory**. `RoomSpawner` changes involve Node/autoload dependencies — tests optional, not included.

**Organization**: Single user story. Data layer and data model are blocking prerequisites. All RoomSpawner changes can be done in one pass after T001–T003.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: JSON schema and typed data model must exist before RoomSpawner can consume them.

**⚠️ CRITICAL**: T001–T003 must be complete before Phase 2 begins.

- [x] T001 In `data/dungeon_config.json`: remove the top-level `"wave_config"` key entirely, and add a `"depth_tiers"` array with 4 entries:
  ```json
  "depth_tiers": [
    { "depth_min": 1, "depth_max": 1,  "waves": [3],       "trigger_threshold": 2, "alive_cap": 4, "min_spawn_distance": 200.0 },
    { "depth_min": 2, "depth_max": 2,  "waves": [4],       "trigger_threshold": 2, "alive_cap": 4, "min_spawn_distance": 200.0 },
    { "depth_min": 3, "depth_max": 4,  "waves": [4, 2],    "trigger_threshold": 2, "alive_cap": 4, "min_spawn_distance": 200.0 },
    { "depth_min": 5, "depth_max": -1, "waves": [4, 2, 1], "trigger_threshold": 2, "alive_cap": 4, "min_spawn_distance": 200.0 }
  ]
  ```

- [x] T002 [P] Create `scripts/data_models/DepthTierConfig.gd` with `class_name DepthTierConfig extends Resource`. Fields: `var depth_min: int = 1`, `var depth_max: int = -1`, `var waves: Array[int] = []`, `var trigger_threshold: int = 2`, `var alive_cap: int = 4`, `var min_spawn_distance: float = 200.0`. Two static methods:
  - `static func from_dict(data: Dictionary) -> Resource` — reads all six fields with safe defaults as above
  - `static func find_for_depth(tiers: Array, depth: int) -> Resource` — iterates tiers; for each, casts to `DepthTierConfig`; returns the first where `tier.depth_min <= depth` and `(tier.depth_max == -1 or depth <= tier.depth_max)`; returns `null` if none match

- [x] T003 [P] Write GUT unit tests for `DepthTierConfig` in `tests/unit/test_depth_tier_config.gd`. Use `const DepthTierConfigScript = preload("res://scripts/data_models/DepthTierConfig.gd")` and call `DepthTierConfigScript.from_dict(...)` and `DepthTierConfigScript.find_for_depth(...)`. Cover:
  - `from_dict` with full valid dict populates all six fields correctly
  - `from_dict` with empty dict returns safe defaults (`waves=[]`, `trigger_threshold=2`, `alive_cap=4`, `min_spawn_distance=200.0`, `depth_min=1`, `depth_max=-1`)
  - `from_dict` `waves` values stored as `int`
  - `find_for_depth` returns correct tier for depth 1 (tier A)
  - `find_for_depth` returns correct tier for depth 3 (tier C, depth_min=3 depth_max=4)
  - `find_for_depth` returns correct tier for depth 5 (tier D, depth_max=-1)
  - `find_for_depth` returns `null` for depth 0 (no tier covers it)
  - Use inline stub arrays of dicts — no autoloads

**Checkpoint**: Data layer complete, `DepthTierConfig` tested. `RoomSpawner` changes can now begin.

---

## Phase 2: User Story 1 — Combat Scales With Dungeon Depth (Priority: P1) 🎯 MVP

**Goal**: Each combat room's enemy count and wave structure is determined by its depth using the depth_tiers table.

**Independent Test**: Enter a depth-1, depth-2, depth-3/4, and depth-5+ room. Verify kill counts and wave triggers per quickstart.md scenarios 1–4.

### Implementation for User Story 1

- [x] T004 [US1] In `scripts/dungeon/RoomSpawner.gd`, add `var _depth_tiers: Array = []` as a new field. In `_load_config()`, replace the existing block that reads `raw.get("wave_config", {})` and assigns `cfg.wave_config` with new code: read `raw.get("depth_tiers", [])`, iterate each entry calling `DepthTierConfig.from_dict(entry)`, append each result to `_depth_tiers`. Do **not** set `cfg.wave_config` in `_load_config()` anymore — remove that logic entirely.

- [x] T005 [US1] In `scripts/dungeon/RoomSpawner.gd`, add `func _resolve_wave_config() -> void`:
  1. Guard: `if room_type_id.contains("Boss") or room_type_id.contains("Elite"): return`
  2. `var tier := DepthTierConfig.find_for_depth(_depth_tiers, depth) as DepthTierConfig`
  3. Guard: `if tier == null or tier.waves.is_empty(): return`
  4. Build wave config dict and call `WaveConfig.from_dict`: `_config.wave_config = WaveConfig.from_dict({"waves": tier.waves, "trigger_threshold": tier.trigger_threshold, "alive_cap": tier.alive_cap, "min_spawn_distance": tier.min_spawn_distance}) as WaveConfig`
  5. Print: `[RoomSpawner] depth={d} resolved tier waves={w} threshold={t}`

- [x] T006 [US1] In `scripts/dungeon/RoomSpawner.gd`, update `_on_player_entered()`: add `_resolve_wave_config()` call immediately after `_spawned = true`, before the existing `if _config.wave_config != null:` check.

**Checkpoint**: Depth-scaled waves fully functional. Room clears after correct kill count per depth tier.

---

## Phase 3: Polish & Validation

- [ ] T007 Run quickstart.md validation scenarios 1–6: verify all depth tiers, elite/start unaffected, alive cap respected.

- [x] T008 Update `repo_map.md`:
  - Add `DepthTierConfig` entry under Scripts — Data Models with fields and static methods
  - Update `RoomSpawner` entry: add `_depth_tiers: Array` field; add `_resolve_wave_config()` method

---

## Dependencies & Execution Order

- T001 has no dependencies — start immediately
- T002 and T003 can run in parallel with each other (different files) and with T001
- T004 depends on T001 (JSON schema must exist) and T002 (DepthTierConfig type must exist)
- T005 depends on T004 (_depth_tiers field must exist)
- T006 depends on T005 (_resolve_wave_config must exist)
- T007 depends on T004–T006
- T008 can run alongside T007

---

## Implementation Strategy

1. T001 — update JSON (remove wave_config, add depth_tiers)
2. T002 + T003 in parallel — create DepthTierConfig.gd and its tests
3. Run tests to confirm DepthTierConfig logic is correct before touching RoomSpawner
4. T004 → T005 → T006 — update RoomSpawner in a single pass
5. **STOP and VALIDATE** via T007
6. T008 — repo_map update

---

## Notes

- `_depth_tiers` stores `Array` (not `Array[DepthTierConfig]`) because typed arrays require the class to be globally registered — using untyped array avoids potential headless load-order issues; cast at use site (`as DepthTierConfig`) is sufficient
- `find_for_depth` returns `null` for depth 0 (start room) — `_resolve_wave_config` guard returns early, leaving `_config.wave_config = null` → legacy flat-spawn path → `_living_count == 0` → no lock, no spawn
- The old `wave_config` global trigger_threshold was 1; new tiers use 2 — this is intentional per spec
- Commit after T003 (data model + tests passing), then after T006 (full feature)
