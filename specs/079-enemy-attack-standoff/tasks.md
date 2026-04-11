# Tasks: Enemy Attack Standoff Distance

**Input**: Design documents from `/specs/079-enemy-attack-standoff/`
**Prerequisites**: plan.md ✅, spec.md ✅

## Format: `[ID] [P?] [Story] Description`

---

## Phase 3: User Story 1 — Enemy Stops Before Attack Radius Edge (Priority: P1) 🎯 MVP

**Goal**: Pursuing enemy halts at `attack_range - 10` units from the player rather than at `attack_range`.

**Independent Test**: In-game: place the player, observe a pursuing enemy — it stops with a small gap before the attack radius edge. Unit test: construct an `EnemyData`-equivalent dict with `attack_range = 100`, simulate the stop condition, verify enemy stops when `dist = 89` but not when `dist = 91`.

### Tests for User Story 1

- [x] T001 [P] [US1] Write GUT unit test covering the pursuit stop threshold in `tests/unit/test_enemy_attack_standoff.gd`: test that the stop distance equals `maxf(0.0, attack_range - 10.0)` for a normal range (e.g. 100→90), a small range below 10 (e.g. 5→0 clamp), and that the enemy continues moving when `dist > standoff`. Use inline dict stubs; no autoloads needed.

### Implementation for User Story 1

- [x] T002 [US1] In `scenes/combat/enemies/Enemy.gd` line 241, change the pursuit stop guard from `dist < _data.attack_range` to `dist < maxf(0.0, _data.attack_range - 10.0)` so the enemy halts 10 units before the attack radius boundary.

**Checkpoint**: Pursuing enemy stops at `attack_range - 10`. Healer follow behavior and all other movement paths are unchanged.

---

## Phase 4: User Story 2 — Healer Follow Unaffected (Priority: P2)

**Goal**: Confirm the healer orbit standoff (`heal_radius - 20`) is unchanged.

**Independent Test**: Observe a healer enemy orbiting an ally — standoff distance is still `heal_radius - 20`.

*No implementation tasks required* — US2 is a non-regression constraint satisfied by the minimal scope of T002. Verify manually or by running existing healer tests after T002.

---

## Dependencies & Execution Order

- **T001** (test): No dependencies — write and confirm it FAILS before T002.
- **T002** (implementation): Depends on T001 existing. After T002, T001 MUST pass.

---

## Notes

- Total tasks: 2
- Parallel opportunity: T001 can be written before T002 begins (different concerns, no file overlap).
- MVP: T001 + T002 fully deliver the feature.
