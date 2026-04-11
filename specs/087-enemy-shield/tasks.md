# Tasks: Enemy Shield Mechanic

**Input**: Design documents from `/specs/087-enemy-shield/`
**Prerequisites**: plan.md ✅, spec.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths in all descriptions

---

## Phase 1: Setup

No setup tasks required — project is already configured.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema and data-model changes that all user story phases depend on.

**⚠️ CRITICAL**: Both tasks must be complete before any Enemy.gd work begins.

- [x] T001 Add `"shield_hp": 200` and `"shield_stun_duration": 3.0` to the `forest_boss_thorns` entry in `data/enemies.json` (inside `boss.forest.forest_boss_thorns`)
- [x] T002 [P] Add `var shield_hp: int = 0` and `var shield_stun_duration: float = 3.0` fields to `scripts/data_models/EnemyData.gd`, and parse both with `.get()` fallbacks in `from_dict` after the existing `charge_speed_mult` line (line 83, before `return d`)

**Checkpoint**: Data layer ready. Enemy.gd and test work can now proceed.

---

## Phase 3: User Story 1 — Shield Absorbs Incoming Damage (Priority: P1) 🎯 MVP

**Goal**: Incoming damage depletes shield HP before regular HP; overflow carries over in the same hit. Heals are unaffected.

**Independent Test**: Manually call `activate_shield()` on `forest_boss_thorns` in DevPanel, deal damage below shield HP and verify regular HP is unchanged, then deal enough to overflow and verify correct regular HP loss.

### Tests for User Story 1

- [x] T003 [US1] Write unit tests for shield absorption arithmetic in `tests/unit/test_enemy_shield.gd` using inline helper functions (no autoloads, mirrors pattern from `test_enemy_attack_standoff.gd`). Cover: (a) amount < shield_hp → shield decreases, overflow = 0; (b) amount == shield_hp → shield = 0, overflow = 0; (c) amount > shield_hp → shield = 0, overflow = amount − shield_hp; (d) shield_hp = 0 → no absorption (full damage passes through)

### Implementation for User Story 1

- [x] T004 [P] [US1] Add runtime fields `_current_shield_hp: int = 0` to `scenes/combat/enemies/Enemy.gd` alongside the existing state variables (~line 51), and add public method `activate_shield()` that sets `_current_shield_hp = _data.shield_hp` with an early return guard when `_data.shield_hp <= 0`
- [x] T005 [US1] Rewrite `take_damage()` in `scenes/combat/enemies/Enemy.gd` (line 146) to intercept shield HP: if `_current_shield_hp <= 0` skip to `_stats.take_damage(amount, attacker)` unchanged; otherwise compute `overflow = amount - _current_shield_hp`, deduct from shield (clamping at 0), if shield reaches 0 call `_on_shield_broken()` stub (stub body: just zeros `_current_shield_hp`), then if overflow > 0 call `_stats.take_damage(overflow, attacker)`; also add the `_on_shield_broken()` private method as a stub now (it will be filled out in T007 and T009)

**Checkpoint**: US1 complete — shield absorbs damage and overflow carries over correctly.

---

## Phase 4: User Story 2 — Shield Break Stuns the Enemy (Priority: P2)

**Goal**: When shield HP hits 0, enemy enters STUNNED state for the configured duration; all movement and attacks are suppressed until stun expires.

**Independent Test**: With shield active, deal exactly enough damage to zero the shield, then observe enemy is frozen for ~3 s and resumes movement after.

### Tests for User Story 2

- [x] T006 [P] [US2] Add stun countdown tests to `tests/unit/test_enemy_shield.gd`: (a) timer decrements by delta each tick; (b) timer clamped to 0, not negative; (c) stun expires when timer reaches 0 — use inline arithmetic helpers, no Enemy node instantiation

### Implementation for User Story 2

- [x] T007 [P] [US2] Add `STUNNED` to the `EnemyState` enum (line 40) and add `_stun_remaining: float = 0.0` field in `scenes/combat/enemies/Enemy.gd`
- [x] T008 [US2] Fill out `_on_shield_broken()` in `scenes/combat/enemies/Enemy.gd` to set `_stun_remaining = _data.shield_stun_duration` and `_state = EnemyState.STUNNED`; add the stun guard block in `_physics_process()` immediately after the existing root guard (~line 195): if `_state == EnemyState.STUNNED`, decrement `_stun_remaining` by delta, when it reaches 0 set `_state = EnemyState.IDLE`, zero velocity, call `move_and_slide()`, and return (depends on T005, T007)

**Checkpoint**: US2 complete — shield break stuns the enemy for the configured duration.

---

## Phase 5: User Story 3 — Shield Visual Feedback (Priority: P3)

**Goal**: A semi-transparent ColorRect overlay is visible on the enemy while shield is active and removed when shield breaks.

**Independent Test**: Call `activate_shield()` — verify `_shield_visual.visible == true`; deal enough damage to break shield — verify `_shield_visual.visible == false`.

### Implementation for User Story 3

- [x] T009 [P] [US3] Add `_shield_visual: ColorRect = null` field to `scenes/combat/enemies/Enemy.gd` and create the ColorRect node programmatically at the end of `initialize()`: size it ~10 % larger than the enemy body (e.g. `_visual.size * 1.1`), center it, set `color = Color(0.3, 0.6, 1.0, 0.4)` (semi-transparent blue), add as child, set `visible = false`
- [x] T010 [US3] Wire the visual into `activate_shield()` (set `_shield_visual.visible = true` after setting `_current_shield_hp`) and into `_on_shield_broken()` (set `_shield_visual.visible = false` before setting the stun state) in `scenes/combat/enemies/Enemy.gd` (depends on T008, T009)

**Checkpoint**: All three user stories complete. Shield absorption, stun, and visual all functional for `forest_boss_thorns`.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T011 [P] Verify `receive_heal()` in `scenes/combat/enemies/Enemy.gd` does not touch shield HP (it delegates to `_stats.heal()` — confirm no change needed and add an inline comment noting this is intentional)
- [x] T012 [P] Add one edge-case test to `tests/unit/test_enemy_shield.gd`: enemy that takes damage mid-stun still loses regular HP (shield HP = 0 during stun, so normal damage path is taken)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately
- **US1 (Phase 3)**: Depends on T001 + T002
- **US2 (Phase 4)**: Depends on Phase 3 complete (T005 must exist for T008)
- **US3 (Phase 5)**: Depends on T008 (needs `_on_shield_broken()` to exist)
- **Polish (Phase 6)**: Depends on all phases complete

### Within Each Phase

- T001 and T002 are independent of each other — run in parallel
- T003 and T004 within Phase 3 are independent — run in parallel
- T007 and T006 within Phase 4 are independent — T008 depends on both
- T009 within Phase 5 is independent of T008 — T010 depends on both

---

## Parallel Execution Examples

```
# Phase 2 — run in parallel:
T001: enemies.json update
T002: EnemyData.gd fields

# Phase 3 — run T003 and T004 in parallel, then T005:
T003: unit tests
T004: runtime fields + activate_shield()
→ T005: take_damage interception (after T004)

# Phase 4 — run T006 and T007 in parallel, then T008:
T006: stun tests
T007: STUNNED enum + _stun_remaining field
→ T008: stun logic in _on_shield_broken + _physics_process (after T005 + T007)

# Phase 5 — run T009 in parallel with T008, then T010:
T009: _shield_visual creation
→ T010: visual wiring (after T008 + T009)
```

---

## Implementation Strategy

### MVP (User Story 1 only)

1. Complete Phase 2 (T001 + T002)
2. Complete Phase 3 (T003–T005)
3. **STOP and validate**: `activate_shield()` works, damage absorbed, overflow correct, heals unaffected

### Full Delivery

Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 (sequential by priority)

Each phase delivers a testable increment without breaking the previous one.
