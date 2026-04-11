# Tasks: Enemy Thorns Projectile

**Input**: Design documents from `/specs/089-enemy-thorns-projectile/`
**Feature**: Replace enemy `reflect_amount` damage-reflect with projectile-based thorns burst on hit

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Foundational (Data Layer)

**Purpose**: Extend the data schema with new thorn-projectile fields. All user story work depends on this phase being complete first.

**⚠️ CRITICAL**: No user story implementation can begin until T001 and T002 are both complete.

- [x] T001 [P] Update `data/enemies.json`: in the skeleton entry set `"reflect_amount": 0.0` and add `"thorns_on_hit": true, "thorns_directions": 4, "thorns_damage": 5, "thorns_speed": 400, "thorns_range": 600, "thorns_fire_cooldown": 0.5`; in the `forest_boss_thorns` entry remove `"thorns_reflect_amount_p2"` and `"thorns_reflect_amount_p3"` and add `"thorns_on_hit": false, "thorns_directions": 6, "thorns_damage": 8, "thorns_speed": 500, "thorns_range": 800, "thorns_fire_cooldown": 0.3`
- [x] T002 [P] Update `scripts/data_models/EnemyData.gd`: remove `thorns_reflect_amount_p2` and `thorns_reflect_amount_p3` field declarations and their `from_dict()` read lines; add field declarations `thorns_on_hit: bool = false`, `thorns_damage: float = 0.0`, `thorns_speed: float = 400.0`, `thorns_range: float = 600.0`, `thorns_fire_cooldown: float = 0.5`, `thorns_directions: int = 4`; add corresponding `from_dict()` read lines using `.get()` with the above defaults

**Checkpoint**: `EnemyData.from_dict()` compiles with new fields; `enemies.json` has correct thorn entries. All user story phases can now begin.

---

## Phase 2: User Story 1 — Regular Enemy Fires Thorns on Hit (Priority: P1) 🎯 MVP

**Goal**: When a thorns-enabled regular enemy is hit, four diagonal thorn projectiles burst outward from it and damage the player on contact.

**Independent Test**: Spawn a skeleton (thorns_on_hit: true, thorns_directions: 4), attack it, and confirm exactly four `EnemyProjectile` nodes appear in the parent tree heading NE/NW/SE/SW. Confirm a second attack within the fire-cooldown window produces no additional burst.

### Tests for User Story 1

- [x] T003 Write `tests/unit/test_enemy_thorns_on_hit.gd`: create minimal `EnemyData` dicts (one with all thorns fields, one minimal); assert `thorns_on_hit` parses `true`/`false` correctly; assert `thorns_directions` reads 4; assert `thorns_damage`, `thorns_speed`, `thorns_range`, `thorns_fire_cooldown` parse from dict; assert `thorns_on_hit` defaults to `false` when absent; assert `thorns_directions` defaults to `4` when absent (all tests use `EnemyData.from_dict()` — no scene or autoload needed)

### Implementation for User Story 1

- [x] T004 [US1] Implement thorn-firing in `scenes/combat/enemies/Enemy.gd`: add two class-level constant arrays — `THORNS_DIRS_4: Array[Vector2]` containing the four normalised diagonal unit vectors (NE, NW, SE, SW) and `THORNS_DIRS_6: Array[Vector2]` adding N and S; add `_thorns_fire_cooldown_remaining: float = 0.0`; add `_try_fire_thorns()` — early-returns if `not _data.thorns_on_hit` or `_thorns_fire_cooldown_remaining > 0.0`, then calls `_fire_thorns()` and sets `_thorns_fire_cooldown_remaining = _data.thorns_fire_cooldown`; add `_fire_thorns()` — selects `THORNS_DIRS_4` or `THORNS_DIRS_6` based on `_data.thorns_directions`, loads `EnemyProjectile.tscn`, loops over the chosen array and instantiates one `EnemyProjectile` per direction via `setup(dir, _data.thorns_damage, _data.thorns_speed, _data.thorns_range)`, adds each to `get_parent()`; call `_try_fire_thorns()` at the end of `take_damage()` (after shield and HP resolution); tick `_thorns_fire_cooldown_remaining` down in `_physics_process()` before the existing spawn-delay guard (`if _thorns_fire_cooldown_remaining > 0.0: _thorns_fire_cooldown_remaining = maxf(0.0, _thorns_fire_cooldown_remaining - delta)`)

**Checkpoint**: Attacking the skeleton in-game produces four outward projectile bursts. A rapid second hit within the cooldown produces no burst. T003 tests pass.

---

## Phase 3: User Story 2 — Forest Boss Fires Six-Direction Thorns During Thorns Window (Priority: P2)

**Goal**: During the forest boss's `THORNS_ACTIVE` state, player hits trigger a six-direction thorn burst (NE, NW, SE, SW, N, S) instead of the old reflect mechanic.

**Independent Test**: Fight the forest boss into Phase 2, wait for THORNS_ACTIVE, attack once, and confirm exactly six `EnemyProjectile` nodes appear. Attack again outside THORNS_ACTIVE and confirm no burst fires.

### Tests for User Story 2

- [x] T005 [P] [US2] Rewrite `tests/unit/test_forest_boss_thorns_active.gd`: update `_BOSS_DATA` fixture dict — remove `thorns_reflect_amount_p2` and `thorns_reflect_amount_p3`; add `"thorns_on_hit": false, "thorns_directions": 6, "thorns_damage": 8.0, "thorns_speed": 500.0, "thorns_range": 800.0, "thorns_fire_cooldown": 0.3`; replace the four reflect-amount assertion tests (`test_p2_reflect_is_point_three`, `test_p3_reflect_is_point_five`, `test_p3_reflect_higher_than_p2`, `test_reflect_amounts_between_zero_and_one`) and `test_reflect_zero_after_exit` with: `test_boss_thorns_on_hit_is_false()`, `test_boss_thorns_directions_is_six()`, `test_boss_thorns_damage_positive()`, `test_boss_thorns_speed_positive()`, `test_boss_thorns_fire_cooldown_positive()`; keep the existing phase-gating logic tests (phase >= 2 integer checks) and thorns duration / cooldown tests unchanged
- [x] T006 [P] [US2] Update `tests/unit/test_forest_boss_enemy_data.gd`: in `_BOSS_FULL` dict remove `thorns_reflect_amount_p2/p3`, add the six new thorn fields; replace tests `test_from_dict_reads_thorns_reflect_p2`, `test_from_dict_reads_thorns_reflect_p3`, `test_p3_reflect_higher_than_p2`, `test_thorns_reflect_p2_defaults_to_zero`, `test_thorns_reflect_p3_defaults_to_zero` with: `test_from_dict_reads_thorns_on_hit()` (asserts false for boss), `test_from_dict_reads_thorns_directions_six()`, `test_from_dict_reads_thorns_damage()`, `test_from_dict_reads_thorns_speed()`, `test_from_dict_reads_thorns_range()`, `test_from_dict_reads_thorns_fire_cooldown()`; add default-value tests for each new field using the existing `_BASE` minimal dict

### Implementation for User Story 2

- [x] T007 [US2] Update `scenes/combat/enemies/ForestBossThorns.gd`: remove the three `_stats.reflect_amount = …` assignments — in `_on_shield_broken()`, in `_on_died()`, and in `_exit_thorns_active()`; remove the `_stats.reflect_amount = reflect` line inside the `BossState.THORNS_ACTIVE` match arm; override `take_damage(amount: float, attacker: StatsComponent = null)` — call `super.take_damage(amount, attacker)` first, then guard: `if _boss_state != BossState.THORNS_ACTIVE or _thorns_fire_cooldown_remaining > 0.0: return`, then call `_fire_thorns()` (inherited from Enemy) and set `_thorns_fire_cooldown_remaining = _data.thorns_fire_cooldown`; add cooldown tick near the top of `_physics_process()` (before the DEAD return): `if _thorns_fire_cooldown_remaining > 0.0: _thorns_fire_cooldown_remaining = maxf(0.0, _thorns_fire_cooldown_remaining - delta)`

**Checkpoint**: Forest boss no longer sets `reflect_amount`. Hitting it during THORNS_ACTIVE produces a six-projectile burst. Hitting it outside THORNS_ACTIVE produces none. T005 and T006 pass.

---

## Phase 4: User Story 3 — Reflect Mechanic Removed from Enemies (Priority: P3)

**Goal**: Confirm no enemy causes instantaneous reflect damage to the player. Test fixtures for boss-related test files are cleaned up.

**Independent Test**: Attack any enemy (including the skeleton that previously had `reflect_amount: 0.2`) and confirm the player's HP only decreases when struck by a thorn projectile, never from an instant reflect event.

- [x] T008 [P] [US3] Update fixture dict in `tests/unit/test_forest_boss_charge.gd`: remove `"thorns_reflect_amount_p2"` and `"thorns_reflect_amount_p3"` keys; add the six new thorn fields with default values (`"thorns_on_hit": false, "thorns_directions": 6, "thorns_damage": 0.0, "thorns_speed": 400.0, "thorns_range": 600.0, "thorns_fire_cooldown": 0.5`) so the dict remains valid for `EnemyData.from_dict()` — no test assertion changes needed
- [x] T009 [P] [US3] Update fixture dict in `tests/unit/test_forest_boss_phases.gd`: same replacements as T008 — remove old reflect keys, add new thorn keys with defaults — no assertion changes needed
- [x] T010 [P] [US3] Update fixture dict in `tests/unit/test_forest_boss_shield.gd`: same replacements as T008 — no assertion changes needed

**Checkpoint**: All five boss test files compile and pass with no `thorns_reflect_amount_p2/p3` references. The skeleton's `reflect_amount` is 0.0 in JSON so `StatsComponent.take_damage()` never fires the reflect path for enemy attacks.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies — start immediately. T001 and T002 are independent files and can be done in parallel.
- **Phase 2 (US1)**: Depends on T002 (EnemyData fields must exist). T003 can be written before T004 but the fields must compile.
- **Phase 3 (US2)**: Depends on T002 (test fixtures use new fields) and T004 (ForestBossThorns inherits `_fire_thorns()`). T005 and T006 can be written in parallel after T002.
- **Phase 4 (US3)**: Depends on T001 and T002 (fixtures must reference new fields). T008, T009, T010 are fully independent of each other.

### User Story Dependencies

- **US1 (P1)**: Depends on Foundational only — no dependency on other stories.
- **US2 (P2)**: Depends on Foundational and US1 (`_fire_thorns()` is inherited from Enemy.gd changes in T004).
- **US3 (P3)**: Depends on Foundational only (fixture cleanup is data-model-level).

### Parallel Opportunities

Within Phase 1: T001 and T002 can run in parallel.
Within Phase 3: T005 and T006 can run in parallel (different test files).
Within Phase 4: T008, T009, T010 can all run in parallel.

---

## Parallel Execution Examples

### Phase 1 (Foundational)
```
T001: Update data/enemies.json
T002: Update scripts/data_models/EnemyData.gd
(both simultaneously — different files)
```

### Phase 3 (US2 tests)
```
T005: Rewrite test_forest_boss_thorns_active.gd
T006: Update test_forest_boss_enemy_data.gd
(both simultaneously — different files, same dependency T002)
```

### Phase 4 (US3 fixture cleanup)
```
T008: test_forest_boss_charge.gd fixture
T009: test_forest_boss_phases.gd fixture
T010: test_forest_boss_shield.gd fixture
(all three simultaneously)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (T001, T002) — data schema ready
2. Complete Phase 2 (T003, T004) — regular enemy thorns working
3. **STOP and VALIDATE**: Attack skeleton in-game, confirm 4 projectile burst. Run T003 tests.

### Incremental Delivery

1. Phase 1 → data layer consistent
2. Phase 2 → skeleton fires diagonal thorns (MVP)
3. Phase 3 → forest boss fires six-direction thorns in THORNS_ACTIVE window
4. Phase 4 → all test fixtures clean, no stale reflect field references

---

## Notes

- The `StatsComponent.reflect_amount` path and the player's Thorn Bark relic are **not affected** — `StatsComponent.take_damage()` is unchanged.
- `EnemyProjectile.tscn` is reused as-is — no new scene or script file is required.
- The boss has `thorns_on_hit: false` in data, so `Enemy._try_fire_thorns()` is a no-op for it — only the explicit `ForestBossThorns.take_damage()` override fires thorns.
- Thorn projectiles added via `get_parent().add_child()` — same pattern as existing `_fire_projectile()` and `_cast_buff_zone()`.
