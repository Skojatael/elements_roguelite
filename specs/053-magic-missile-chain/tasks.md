# Tasks: Magic Missile Chain Relic

**Input**: Design documents from `/specs/053-magic-missile-chain/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths included in all descriptions

---

## Phase 1: Setup

No project setup required — all target files already exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Relic data and the `has_chain_relic()` query must exist before any user story work can be verified.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 [P] Add `chaining_stone` entry to the `"uncommon"` tier in `data/relics.json` — fields: `name: "Chaining Stone"`, `tier: "uncommon"`, `tags: ["projectile", "chain"]`, `effect_stat: ""`, `effect_mult: 1.0`, `description: "Magic Missile strikes a second enemy for 50% damage."`
- [x] T002 [P] Add `has_chain_relic() -> bool` method to `scripts/managers/RelicManagerImpl.gd` — returns `active_relic_ids.has("chaining_stone")`
- [x] T003 Add `has_chain_relic() -> bool` thin-wrapper method to `autoload/RelicManager.gd` — delegates to `_impl.has_chain_relic()` (depends on T002)

**Checkpoint**: Foundation ready — relic is in the draw pool and queryable.

---

## Phase 3: User Story 1 — Acquire Chaining Stone Relic (Priority: P1) 🎯 MVP

**Goal**: `chaining_stone` exists in the uncommon relic pool, can be offered and picked up, and is correctly tracked in `active_relic_ids`.

**Independent Test**: Use DevPanel to trigger a relic offer, confirm `chaining_stone` appears in draws; pick it; verify `RelicManager.active_relic_ids` contains it. No missiles need to be fired.

### Unit Tests for User Story 1

> **Write these tests FIRST; run them to confirm they FAIL before implementing.**

- [x] T004 [P] [US1] Extend `tests/unit/test_relic_deck.gd` with tests for `RelicManagerImpl.has_chain_relic()`:
  - `test_has_chain_relic_false_when_empty`: construct impl with empty `active_relic_ids`; assert `has_chain_relic()` returns `false`
  - `test_has_chain_relic_true_after_pick`: call `pick_relic("chaining_stone")`; assert `has_chain_relic()` returns `true`
  - `test_has_chain_relic_false_for_other_relic`: pick `"sharp_edge"`; assert `has_chain_relic()` returns `false`
  - Use inline stub dict for relic pool; no autoloads needed

### Implementation for User Story 1

*(T001–T003 in Phase 2 are sufficient — no additional code needed for US1)*

**Checkpoint**: Run unit tests (T004); pick relic via DevPanel; confirm it appears in active relics list.

---

## Phase 4: User Story 2 — Magic Missile Chains to Nearest Enemy (Priority: P1)

**Goal**: With `chaining_stone` held and ≥2 living enemies in the room, every magic missile hit applies damage to the closest other living enemy to the impact point.

**Independent Test**: Enter a combat room with 2+ enemies, pick `chaining_stone` via DevPanel, fire magic missile — both enemies take damage. With only 1 enemy alive, no crash and only that enemy takes damage.

### Implementation for User Story 2

- [x] T005 [P] [US2] Add `chain_damage_mult: 0.5` field to the `magic_missile` entry in `data/skills.json`
- [x] T006 [P] [US2] Add `var _chain_damage_mult: float = 1.0` instance variable to `scenes/player/components/SkillComponent.gd`; read from JSON in `_load_skill_data()` — `_chain_damage_mult = float((entry as Dictionary).get("chain_damage_mult", 1.0))` — place after the `_cooldown_duration` line inside the loop body
- [x] T007 [US2] Extend `Projectile.setup()` signature in `scenes/combat/projectiles/Projectile.gd` to accept a final `chain_damage_mult: float` parameter; add `var _chain_damage_mult: float = 1.0` field; assign in `setup()` (depends on T006 being ready so both files change together)
- [x] T008 [US2] Add `_try_chain(primary_target: Enemy) -> void` helper to `scenes/combat/projectiles/Projectile.gd` — guard clauses: early return if `not RelicManager.has_chain_relic()`, if `RunManager.current_room == null`; iterate `RunManager.current_room.get_parent().get_children()`, skip non-Enemy/same-as-primary/invalid nodes, find minimum-distance child; if found call `chain_target.take_damage(_damage * _chain_damage_mult)` (depends on T007)
- [x] T009 [US2] Update `Projectile._on_body_entered()` in `scenes/combat/projectiles/Projectile.gd` — cast body to local `var primary: Enemy`, call `primary.take_damage(_damage)`, then call `_try_chain(primary)`, then `queue_free()` (depends on T008)
- [x] T010 [US2] Update `SkillComponent._on_skill_button_pressed()` in `scenes/player/components/SkillComponent.gd` — change `projectile.setup(target, damage, _speed, _max_distance)` to `projectile.setup(target, damage, _speed, _max_distance, _chain_damage_mult)` (depends on T006 and T007)

**Checkpoint**: Fire missile with relic + 2 enemies → second enemy loses HP. Fire with 1 enemy → no crash. Fire without relic → second enemy HP unchanged.

---

## Phase 5: User Story 3 — Chain Damage is Data-Driven (Priority: P2)

**Goal**: `chain_damage_mult` is read from `data/skills.json`; changing it tunes chain damage without any code change.

**Independent Test**: Change `chain_damage_mult` in `data/skills.json` from `0.5` to `0.25`; relaunch; confirm chain target takes 25% of primary damage. Revert to `0.5`.

*(T005 and T006 in Phase 4 are the implementation tasks for US3. The JSON field and SkillComponent read are already covered. This phase is validation-only.)*

- [ ] T011 [US3] Validation: set `chain_damage_mult: 0.25` in `data/skills.json`; run game, fire missile with relic, confirm chain damage = 25% of primary (note enemy HP before and after); restore to `0.5`

**Checkpoint**: All three user stories fully functional and validated.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T012 Run all GUT unit tests (`tests/unit/`) and confirm no regressions from the `Projectile.setup()` signature change

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately. T001 and T002 are independent files and can run in parallel.
- **US1 (Phase 3)**: Depends on T001, T002, T003.
- **US2 (Phase 4)**: Depends on Phase 2 complete + T003 (RelicManager wrapper). T005 and T006 are independent and can run in parallel. T007 → T008 → T009 are sequential. T010 depends on T006 and T007.
- **US3 (Phase 5)**: Depends on Phase 4 complete (T005 + T006 already implement the data-driven path).
- **Polish (Phase 6)**: Depends on all phases complete.

### User Story Dependencies

- **US1**: Only needs Phase 2 data + query method.
- **US2**: Needs US1 complete (relic must be in pool to test chaining). Also needs Phase 4 implementation.
- **US3**: Automatically satisfied by T005+T006 from Phase 4; Phase 5 is validation only.

### Within Phase 4 (US2) — Strict Order

```
T005 [P] skills.json        ──┐
T006 [P] SkillComponent.gd  ──┤── T007 Projectile setup() sig ── T008 _try_chain() ── T009 _on_body_entered() ── T010 SkillComponent call
```

### Parallel Opportunities

- **Phase 2**: T001 (data/relics.json) and T002 (RelicManagerImpl) touch different files — run in parallel.
- **Phase 3**: T004 (unit tests) can be written during or after Phase 2 — independent file.
- **Phase 4**: T005 (skills.json) and T006 (SkillComponent) touch different files — run in parallel. Then T007→T008→T009 are sequential Projectile changes.

---

## Parallel Example: Phase 2

```
Task T001: Add chaining_stone to data/relics.json
Task T002: Add has_chain_relic() to RelicManagerImpl.gd

(Both touch different files — no conflict.)

Then sequentially:
Task T003: Add has_chain_relic() wrapper to RelicManager.gd
```

## Parallel Example: Phase 4 start

```
Task T005: Add chain_damage_mult field to data/skills.json
Task T006: Add _chain_damage_mult var + JSON read to SkillComponent.gd

(Both touch different files — no conflict.)

Then sequentially on Projectile.gd:
Task T007 → T008 → T009 → T010
```

---

## Implementation Strategy

### MVP (Phase 2 + Phase 3 + Phase 4)

1. Complete Phase 2: Foundational data + query
2. Complete Phase 3: Unit tests passing
3. Complete Phase 4: Chain logic wired end-to-end
4. **STOP and VALIDATE**: Fire missile with relic; two enemies take damage
5. Phase 5 is configuration-validation only — no further code needed

### Incremental Delivery

1. Phase 2 complete → relic exists in pool, queryable ✅
2. Phase 3 complete → unit tests green ✅
3. Phase 4 complete → chain mechanic live in-game ✅
4. Phase 5 complete → confirmed data-driven ✅
5. Phase 6 complete → regression-free ✅

---

## Notes

- `_try_chain()` in Projectile must use early-return guard clauses (Constitution VI). Max nesting depth: 2.
- The `Projectile.setup()` signature change is backward-breaking — confirm `SkillComponent` is the only caller before completing T007 (it is, per research.md).
- `SkillData.gd` is an empty stub and intentionally not touched (YAGNI — no second caller).
- No `.tscn` edits required anywhere in this feature.
