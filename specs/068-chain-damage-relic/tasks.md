# Tasks: Chain Damage Relic

**Input**: Design documents from `/specs/068-chain-damage-relic/`
**Prerequisites**: spec.md ✅, plan.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Foundational (Data)

**Purpose**: Add the relic entry to `relics.json` — this must exist before any logic can reference it.

- [x] T001 Add `chain_power_stone` entry to the `"common"` block in `data/relics.json` with `tier: "common"`, `tags: ["chain_unlocked"]`, `effect_stat: ""`, `effect_mult: 1.0`, `condition_type: "chain_damage_bonus"`, `condition_threshold: 0.0`, `condition_mult: 0.15`, `description: "Chain hits deal 65% of primary damage instead of 50%."`, `deck_count: 1`

**Checkpoint**: Relic data present — logic implementation can now proceed.

---

## Phase 2: User Story 1 — Relic Appears After Chain Mechanic is Unlocked (Priority: P1) 🎯 MVP

**Goal**: `chain_power_stone` is correctly gated by `chain_unlocked` tag and appears in offers only after `chaining_stone` is held.

**Independent Test**: Pick `chaining_stone` via DevPanel, trigger a room offer, verify `chain_power_stone` is in the draw pool. Without `chaining_stone`, verify it is absent.

### Implementation for User Story 1

- [x] T002 [US1] Add `get_chain_damage_bonus() -> float` method to `scripts/managers/RelicManagerImpl.gd` — iterates `active_relic_ids`, looks up each in the relic pool, sums `condition_mult` for entries where `condition_type == "chain_damage_bonus"`, returns `0.0` if none match. Use early-return guard and `continue` loop pattern.
- [x] T003 [US1] Add thin-wrapper `get_chain_damage_bonus() -> float` to `autoload/RelicManager.gd` — delegates to `_impl.get_chain_damage_bonus()`, following the existing delegation pattern of `has_chain_relic()` and `get_stat_mult()`.

### Tests for User Story 1

- [x] T004 [P] [US1] Add test cases to `tests/unit/test_relic_deck.gd` (or create `tests/unit/test_relic_chain_bonus.gd` if separation is cleaner) covering: `get_chain_damage_bonus()` returns `0.0` with no relics active; returns `0.15` when `chain_power_stone` is in `active_relic_ids`; returns `0.30` when two `chain_damage_bonus`-typed relics are held (additive stacking). Use inline stub relic dicts — no autoloads.

**Checkpoint**: US1 fully functional. `chain_power_stone` is pool-eligible after `chaining_stone` is picked, absent otherwise (handled by 064 mechanic unlock system — no additional code needed here).

---

## Phase 3: User Story 2 — Chain Hits Deal 0.65× Damage When Relic is Held (Priority: P1)

**Goal**: When `chain_power_stone` is held, chain hits apply `_damage * (_chain_damage_mult + 0.15)` = 0.65× primary damage.

**Independent Test**: Hold both relics via DevPanel, fire at two enemies, verify second enemy takes 0.65× the damage the first took.

### Implementation for User Story 2

- [x] T005 [US2] Modify `_try_chain()` in `scenes/combat/projectiles/Projectile.gd` — change the chain damage application from `_damage * _chain_damage_mult` to `_damage * (_chain_damage_mult + RelicManager.get_chain_damage_bonus())`. Single-line change inside the existing `if chain_target == null: return` guard.

**Checkpoint**: US2 complete. With both relics held, second target takes 13 damage when primary takes 20 (at default chain_damage_mult 0.5).

---

## Phase 4: Polish & Validation

- [ ] T006 [P] Run existing relic unit tests (`tests/unit/test_relic_deck.gd`) to confirm no regressions from the new relic entry in `data/relics.json`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Data)**: No dependencies — start immediately
- **Phase 2 (US1)**: Depends on T001 (relic entry must exist in JSON for pool-building logic to find it)
- **Phase 3 (US2)**: Depends on T002–T003 (`get_chain_damage_bonus()` must exist before Projectile can call it)
- **Phase 4 (Polish)**: Depends on all prior phases complete

### Task Dependencies

- T002 → T003 (impl method before wrapper)
- T001 → T002, T003 (relic data before logic)
- T003 → T005 (autoload method before Projectile call site)
- T004 can run in parallel with T003

### Parallel Opportunities

T002 and T001 touch different files — both can start after the plan is read. T004 (tests) can be written in parallel with T003.

---

## Implementation Strategy

### MVP (minimum shippable)

1. T001 — add relic JSON entry
2. T002 — add `get_chain_damage_bonus()` to impl
3. T003 — expose on autoload
4. T005 — wire into `_try_chain()`
5. Validate in-game: pick both relics, confirm 0.65× chain damage

### Full delivery adds

- T004 — unit test coverage
- T006 — regression check

---

## Notes

- The 064 mechanic unlock system already gates `chain_unlocked` relics — no additional filtering code is needed in this feature.
- `condition_type: "chain_damage_bonus"` is a new string constant that `get_chain_damage_bonus()` matches against — it is not handled by the existing `get_hit_damage_mult()` loop (which handles `"target_hp_below"`, `"attacker_hp_below"`, `"target_is_burning"`).
- All three bonus values (0.0, 0.15, stacked) in T004 can be tested with inline dicts; no Godot engine required.
