# Tasks: Damage Reduction

**Input**: Design documents from `/specs/062-damage-reduction/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Foundational data changes first (Constitution II), then US1 (player DR), then US2 (enemy DR + burn bypass). US3 (stacking) is fully covered by US1's implementation and tests.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

---

## Phase 1: Foundational — Data-First Changes

**Purpose**: JSON schema changes that all implementation tasks depend on (Constitution II: data before code).

**⚠️ CRITICAL**: Complete before any script changes.

- [x] T001 [P] Add `"damage_reduction_cap": 0.5` to the `stats` object in `data/player.json`
- [x] T002 [P] Add `iron_veil` common relic entry to the `relics.common` object in `data/relics.json`: `id="iron_veil"`, `name="Iron Veil"`, `tags=["survival"]`, `effect_stat="damage_reduction"`, `effect_mult=0.10`, `description="Take 10% less damage"`, `deck_count=2`
- [x] T003 [P] Add `var damage_reduction: float = 0.0` field to `scripts/data_models/EnemyData.gd` and read it in `from_dict()` as `result.damage_reduction = float(data.get("damage_reduction", 0.0))`

**Checkpoint**: Data layer complete — all three JSON/data-model changes can be committed independently.

---

## Phase 2: User Story 1 — Player Acquires Damage Reduction (Priority: P1) 🎯 MVP

**Goal**: Player holding a damage-reduction relic takes less melee and projectile damage for the rest of the run.

**Independent Test**: Equip `iron_veil` relic in-game (via DevPanel), receive enemy contact damage, observe HP loss is 10% lower than baseline.

### Unit Tests for User Story 1

> Write these FIRST; they MUST fail before T005 is implemented.

- [x] T004 [US1] Create `tests/unit/test_damage_reduction.gd` with the following test cases covering the new `StatsComponent` static helper `compute_reduced_damage(amount, reduction)` and the `take_damage` / `take_damage_raw` methods:
  - `test_no_reduction`: `compute_reduced_damage(100.0, 0.0)` → `100.0`
  - `test_ten_percent`: `compute_reduced_damage(100.0, 0.10)` → `90.0`
  - `test_fifty_percent_cap`: `compute_reduced_damage(100.0, 0.50)` → `50.0`
  - `test_zero_amount`: `compute_reduced_damage(0.0, 0.10)` → `0.0`
  - `test_take_damage_applies_reduction`: instantiate `StatsComponent` with `is_player=false`, `max_health=100`, set `damage_reduction=0.20`, call `take_damage(50.0)`, assert `current_health == 60.0`
  - `test_take_damage_raw_ignores_reduction`: same setup, set `damage_reduction=0.50`, call `take_damage_raw(50.0)`, assert `current_health == 50.0`
  - `test_health_floor`: set `damage_reduction=0.0`, call `take_damage(200.0)` on a 100-HP instance, assert `current_health == 0.0` (never negative)

### Implementation for User Story 1

- [x] T005 [US1] Update `scenes/player/components/StatsComponent.gd` (depends on T001, T004):
  1. Add fields: `var damage_reduction: float = 0.0` and `var _damage_reduction_cap: float = 0.5`
  2. Add static helper (enables unit testing without Node lifecycle): `static func compute_reduced_damage(amount: float, reduction: float) -> float: return amount * (1.0 - reduction)`
  3. In `_ready()` player branch, after reading `_base_max_health`, add: `_damage_reduction_cap = float(stats.get("damage_reduction_cap", 0.5))`
  4. Replace `take_damage()` body to use the helper: `var effective: float = compute_reduced_damage(amount, damage_reduction)`; then `current_health = maxf(current_health - effective, 0.0)` + existing signal + died check
  5. Add `take_damage_raw(amount: float) -> void` — identical to current `take_damage()` before this feature (no DR applied): `current_health = maxf(current_health - amount, 0.0)` + same signal + died check
  6. In `_on_relic_applied()`, append after the existing `health_changed.emit()` line: `damage_reduction = minf(_damage_reduction_cap, RelicManager.get_stat_addend("damage_reduction"))`

**Checkpoint**: Player DR fully functional. `iron_veil` relic reduces melee and projectile damage. Unit tests pass.

---

## Phase 3: User Story 2 — Enemy Has Innate Damage Reduction (Priority: P2)

**Goal**: Enemies authored with a `damage_reduction` value in `enemies.json` take proportionally less damage from the player.

**Independent Test**: Temporarily set `damage_reduction: 0.20` on `slime` in `enemies.json`, attack a slime, observe it takes 20% less damage per hit (HP bar depletes more slowly).

### Implementation for User Story 2

- [x] T006 [US2] Update `scenes/combat/enemies/Enemy.gd` (depends on T003, T005):
  1. In `initialize(data: EnemyData)`, after `_stats.max_health = data.max_health`, add: `_stats.damage_reduction = data.damage_reduction`
  2. In `_physics_process()`, replace `take_damage(burn_dmg)` with `_stats.take_damage_raw(burn_dmg)` so burn damage bypasses DR entirely

**Checkpoint**: Enemy DR works. Burn damage ignores DR on all enemies.

---

## Phase 4: User Story 3 — Multiple Reduction Sources Stack (Priority: P3)

**Goal**: Holding two or more damage-reduction relics produces accurate additive stacking, capped at 50%.

**Independent Test**: Run unit tests from T004 covering multi-source stacking; confirm in-game that two `iron_veil` relics produce 20% total reduction (not 10%).

### Implementation for User Story 3

No new code required — additive stacking is handled by `RelicManager.get_stat_addend("damage_reduction")` (already sums `effect_mult` additively across held relics) and the `minf(_damage_reduction_cap, ...)` clamp added in T005. US3 is fully covered by T004's stacking test cases.

- [x] T007 [US3] Extend `tests/unit/test_damage_reduction.gd` with multi-source stacking tests (depends on T005):
  - `test_additive_stacking_two_sources`: manually call `compute_reduced_damage(100.0, 0.10 + 0.10)` → `80.0`
  - `test_additive_stacking_three_sources`: `compute_reduced_damage(100.0, 0.10 + 0.10 + 0.20)` → `60.0`
  - `test_cap_enforced_over_50`: `compute_reduced_damage(100.0, minf(0.5, 0.10 * 6))` → `50.0` (six 10% relics still cap at 50%)

**Checkpoint**: All three user stories fully functional and independently verified.

---

## Phase 5: Polish

- [x] T008 Update `repo_map.md` — add `damage_reduction` and `_damage_reduction_cap` to the `StatsComponent` fields entry; add `take_damage_raw(amount)` to its methods list; add `damage_reduction` to the `EnemyData` fields entry

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies — all three tasks [P], start immediately
- **Phase 2 (US1)**: T001 must complete before T005; T004 written before T005
- **Phase 3 (US2)**: T003 and T005 must complete before T006
- **Phase 4 (US3)**: T005 must complete before T007
- **Phase 5 (Polish)**: All implementation complete

### User Story Dependencies

- **US1 (P1)**: Depends on T001 (player.json), T002 (relics.json)
- **US2 (P2)**: Depends on T003 (EnemyData field) and T005 (take_damage_raw exists)
- **US3 (P3)**: Depends on T005 (clamp logic); no new code, only additional tests

### Parallel Opportunities

- T001, T002, T003 — all different files, fully parallel
- T004 (write tests) and T001/T002/T003 — parallel (test file is a new file)
- T007 can begin as soon as T005 is done

---

## Parallel Example: Phase 1

```
# All three can run simultaneously:
Task T001: edit data/player.json
Task T002: edit data/relics.json
Task T003: edit scripts/data_models/EnemyData.gd
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 1 (T001, T002, T003)
2. Write tests T004 — verify they FAIL
3. Implement T005 — verify tests now PASS
4. **Validate**: Equip `iron_veil` via DevPanel, confirm reduced damage in-game
5. **Stop here** — enemy DR and stacking are additive improvements

### Incremental Delivery

1. Phase 1 + US1 → player DR working, `iron_veil` relic available
2. US2 → enemy DR available to content authors; burn bypass live
3. US3 → stacking tests confirm additive model is correct
4. Polish → repo_map updated

---

## Notes

- [P] tasks = different files, no dependencies between them
- T004 must be written and confirmed failing before T005 is implemented (test-first)
- `take_damage_raw()` is the canonical bypass for any future unmitigated damage source (burn, poison, etc.)
- No `.tscn` edits required — no Godot Editor work needed for this feature
