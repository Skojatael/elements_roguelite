# Tasks: Burn Relic Damage Scaling (065)

**Input**: Design documents from `specs/065-burn-relic-scaling/`
**Prerequisites**: spec.md ✅ plan.md ✅ research.md ✅ data-model.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Foundational (Blocking Prerequisites for US2)

**Purpose**: Data model and Enemy query method that US2 depends on. US1 (Projectile change) can proceed without these.

**⚠️ CRITICAL**: Phase 3 (US2) cannot begin until this phase is complete.

- [x] T001 [P] Add `condition_type`, `condition_threshold`, `condition_mult` fields to `executioners_mark`, `berserker_stone`, and `burn_damage` entries in `data/relics.json` (see plan.md Phase 1 for exact values)
- [x] T002 [P] Add `condition_type: String`, `condition_threshold: float`, `condition_mult: float` fields to `scripts/data_models/RelicData.gd` and parse them in `from_dict()`
- [x] T003 [P] Add `is_burning() -> bool` method to `scenes/combat/enemies/Enemy.gd` — null-safe guard on `_burn`, delegates to `_burn.is_active()`

**Checkpoint**: Foundation ready — US1 can proceed immediately; US2 can proceed once T001–T003 are complete.

---

## Phase 2: User Story 1 — Bottled Oil Increases Burn Tick Damage (Priority: P1) 🎯 MVP

**Goal**: Burn ticks deal 20% more damage when the player holds Bottled Oil. Applies to both projectile and chain burn-hit paths.

**Independent Test**: In-game, equip Bottled Oil, ignite an enemy, and verify each burn tick deals 20% more damage than without the relic. No other changes needed.

### Implementation for User Story 1

- [x] T004 [US1] In `scenes/combat/projectiles/Projectile.gd`, multiply the burn tick damage argument by `RelicManager.get_stat_mult("burn_damage")` in both `_on_body_entered()` and `_try_chain()` (see plan.md Phase 7 for exact lines)

**Checkpoint**: US1 complete — Bottled Oil relic is now functional. Verifiable in-game independently of US2.

---

## Phase 3: User Story 2 — Searing Seal Bonus Damage on Burning Targets (Priority: P2)

**Goal**: Direct hits deal 50% bonus damage to burning enemies when the player holds Searing Seal. Stacks multiplicatively with other conditional relics. Conditional logic is fully data-driven — no relic IDs or multipliers hard-coded.

**Independent Test**: Equip Searing Seal; attack an enemy while burning vs. not burning. Burning hit must be exactly 1.50× the non-burning hit. Verify Executioner's Mark and Berserker Stone still function correctly after the refactor.

**Prerequisites**: T001 (condition fields in JSON), T002 (RelicData fields), T003 (Enemy.is_burning())

### Tests for User Story 2 (mandatory — RelicManagerImpl is modified)

- [x] T005 [P] [US2] In `tests/unit/test_relic_deck.gd`, fix 6 existing `get_hit_damage_mult()` call sites by adding `false` as the third argument (see plan.md Phase 8a for the full list)

### Implementation for User Story 2

- [x] T006 [US2] Replace `get_hit_damage_mult()` in `scripts/managers/RelicManagerImpl.gd` with the generic condition loop (see plan.md Phase 4 for full body) — depends on T001, T002
- [x] T007 [US2] Update `get_hit_damage_mult()` signature in `autoload/RelicManager.gd` to forward the new `target_is_burning: bool` parameter — depends on T006
- [x] T008 [US2] Update the `get_hit_damage_mult()` call in `scenes/player/components/CombatComponent.gd` to pass `target.is_burning()` as the third argument — depends on T003, T007
- [x] T009 [P] [US2] Add 5 new Searing Seal tests to `tests/unit/test_relic_deck.gd` (see plan.md Phase 8b for full test bodies) — depends on T005, T006

**Checkpoint**: US2 complete — Searing Seal is functional, conditional relics are data-driven, all tests pass.

---

## Phase 4: Polish

- [x] T010 Update `repo_map.md` to reflect: `Enemy.is_burning() -> bool` added; `RelicData` gains 3 new fields; `get_hit_damage_mult` signature changed in `RelicManagerImpl` and `RelicManager`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — T001, T002, T003 all run in parallel immediately
- **US1 (Phase 2)**: No dependency on Phase 1 — T004 can start immediately in parallel with Phase 1
- **US2 (Phase 3)**: Depends on T001, T002, T003 (Phase 1 complete)
- **Polish (Phase 4)**: Depends on all phases complete

### User Story Dependencies

- **US1**: Independent — starts immediately, zero dependencies on US2
- **US2**: Depends on T001 (JSON), T002 (RelicData), T003 (Enemy.is_burning())

### Within US2

```
T005 (fix test call sites) ──────────────────────────┐
T006 (RelicManagerImpl generic loop, needs T001+T002) ──► T007 (RelicManager wrapper) ──► T008 (CombatComponent, needs T003+T007)
                                                              └──► T009 (new tests, needs T005+T006)
```

### Parallel Opportunities

- T001, T002, T003, T004 can all run simultaneously at the start
- T005 and T006 can start in parallel once Phase 1 is done
- T009 runs in parallel with T008 once T005 and T006 are done

---

## Implementation Strategy

### MVP (US1 only — immediate)

1. Run T004 (single file change in Projectile.gd)
2. Validate in-game: Bottled Oil burn ticks deal 20% more damage
3. Done — US1 delivers the fix for the broken relic promise

### Full Delivery

1. T001 + T002 + T003 + T004 in parallel
2. T005 + T006 in parallel (once Phase 1 done)
3. T007, T008, T009 (sequential/parallel per dependency graph)
4. T010 polish

---

## Notes

- T004 is the only change needed for US1 — it can ship before the US2 refactor
- The data-driven refactor (T001–T003, T006) does not change observable game behaviour for existing relics — `executioners_mark` and `berserker_stone` produce identical results via the generic loop
- Existing tests for `executioners_mark`/`berserker_stone` in `test_relic_deck.gd` serve as regression coverage for the refactor once T005 fixes the call signatures
