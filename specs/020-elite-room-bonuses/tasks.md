# Tasks: Elite Room Bonuses

**Input**: Design documents from `specs/020-elite-room-bonuses/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Config and data model extensions that both user stories depend on. Must be complete before any user story work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T001 [P] Add `"enemy_count_mult": 1.5` and `"essence_mult": 1.8` to the `EliteRoom01` entry in `data/dungeon_config.json → spawn_configs`
- [X] T002 [P] Add `var enemy_count_mult: float = 1.0` and `var essence_mult: float = 1.0` to `scripts/data_models/RoomSpawnConfig.gd`; parse both in `from_dict()` using `float(data.get("enemy_count_mult", 1.0))` and `float(data.get("essence_mult", 1.0))`

**Checkpoint**: Config values defined and data model parses them — user story phases can begin.

---

## Phase 2: User Story 1 — Elite Rooms Spawn More Enemies (Priority: P1) 🎯 MVP

**Goal**: `RoomSpawner._spawn_enemies()` spawns `floor(base_count × enemy_count_mult)` enemies (capped at MAX_ENEMIES=10), cycling through the configured spawn_points list for any extras beyond the base.

**Independent Test**: Enter an EliteRoom01. Confirm 3 enemies spawn (floor(2 × 1.5) = 3) — slime, skeleton, and one extra slime (index 2 % 2 = 0). Enter a CombatRoom01. Confirm 2 enemies spawn (floor(2 × 1.0) = 2 — unchanged).

### Implementation

- [X] T003 [US1] Modify `_spawn_enemies()` in `scripts/dungeon/RoomSpawner.gd`: replace `_living_count = _config.spawn_points.size()` and the `for sp in spawn_points` loop with a count-multiplied loop — compute `var base_count: int = _config.spawn_points.size()`, set `_living_count = mini(floori(float(base_count) * _config.enemy_count_mult), MAX_ENEMIES)`, iterate `for i in _living_count` selecting `_config.spawn_points[i % base_count]` as the spawn point per contracts/interfaces.md

**Checkpoint**: US1 complete — elite rooms spawn 3 enemies; standard rooms unaffected.

---

## Phase 3: User Story 2 — Elite Room Kills Yield More Essence (Priority: P2)

**Goal**: Each enemy killed in an elite room awards `floor(depth_scaled_essence × 1.8)` essence. Standard rooms are unaffected.

**Independent Test**: Kill a slime at depth 1 in EliteRoom01 — confirm 18 essence (floor(10 × 1.0 × 1.8)). Kill a slime at depth 1 in CombatRoom01 — confirm 10 essence (no multiplier). Kill a skeleton at depth 2 in EliteRoom01 — confirm 29 essence (floor(15 × 1.1 × 1.8)).

### Implementation

- [X] T004 [US2] Add computed property `var essence_mult: float: get: return _config.essence_mult if _config != null else 1.0` to `scripts/dungeon/RoomSpawner.gd` per contracts/interfaces.md
- [X] T005 [US2] Modify `_on_enemy_defeated()` in `scripts/managers/RunManager.gd`: add `var room_essence_mult: float = (current_room as RoomSpawner).essence_mult if current_room != null else 1.0` and multiply it into the essence formula: `floori(base_essence * (1.0 + essence_depth_scale * float(current_room_depth - 1)) * room_essence_mult)` per contracts/interfaces.md (depends on T004)

**Checkpoint**: US2 complete — elite room kills yield 1.8× essence on top of depth scaling; standard rooms unchanged.

---

## Phase 4: Polish & Validation

- [ ] T006 Run all 10 manual validation scenarios from `specs/020-elite-room-bonuses/quickstart.md` and confirm each passes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately. T001 and T002 are parallel (different files).
- **US1 (Phase 2)**: Requires T001 + T002 complete. T003 uses `_config.enemy_count_mult` from T002.
- **US2 (Phase 3)**: Requires T002 complete. T004 uses `_config.essence_mult` from T002. T005 depends on T004 (reads the property). Both are in different files but sequential within US2.
- **Polish (Phase 4)**: Requires US1 and US2 complete.

### User Story Dependencies

- **US1 (P1)**: Foundational → T003
- **US2 (P2)**: Foundational → T004 → T005

### Parallel Opportunities

- T001 + T002: parallel, different files
- US1 (T003) and US2 (T004) can start simultaneously after Foundational — they modify different parts of RoomSpawner.gd (different method vs new property) and different files (RunManager)

---

## Parallel Example: After Foundational Phase

```
# T003 and T004 can start together (different concerns, US1 vs US2):
Task A (US1): Modify _spawn_enemies() in scripts/dungeon/RoomSpawner.gd
Task B (US2): Add essence_mult property to scripts/dungeon/RoomSpawner.gd

# After Task B completes:
Task C (US2): Modify _on_enemy_defeated() in scripts/managers/RunManager.gd
```

---

## Implementation Strategy

### MVP (US1 Only)

1. Complete Phase 1 (Foundational — T001 + T002)
2. Complete Phase 2 (US1 — T003 only)
3. **Validate**: Enter EliteRoom01, confirm 3 enemies spawn; CombatRoom01 unchanged

### Full Delivery

1. Phase 1 → Phase 2 (US1) → Phase 3 (US2) → Phase 4 (validation)
2. Each phase independently testable before moving on

---

## Notes

- T003 and T004 both touch `RoomSpawner.gd` but in non-overlapping locations (method body vs class-level property). They can be applied sequentially in either order with no conflict.
- Standard rooms omit `enemy_count_mult` and `essence_mult` from config — `from_dict()` defaults both to `1.0`, so `floor(n × 1.0) = n` and essence multiplier = 1.0 (no change).
- The `i % base_count` cycling in T003 is safe even when `base_count = 0` because `_living_count = 0` in that case and the loop never executes.
- Scenario 10 in quickstart.md (change multiplier to 2.0) is a temporary config edit to verify config-driven behaviour — revert after testing.
