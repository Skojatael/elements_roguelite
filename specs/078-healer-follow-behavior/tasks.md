# Tasks: Healer Follow Behavior

**Input**: Design documents from `/specs/078-healer-follow-behavior/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: No project setup is required — this feature modifies an existing script with no new dependencies.

*(No setup tasks needed — proceed directly to Foundational.)*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Understand and verify the current movement block in `Enemy.gd` before adding the healer branch.

- [x] T001 Read `scenes/combat/enemies/Enemy.gd` in full and confirm the exact line range of the movement section in `_physics_process` (lines 213–228 as of last read) — no code changes; just confirm the insertion point

**Checkpoint**: Movement insertion point confirmed — implementation can begin.

---

## Phase 3: User Story 1 — Healer Orbits Its Closest Ally (Priority: P1) 🎯 MVP

**Goal**: Healer enemies reposition to stay `heal_radius - 20` units from their nearest living ally, dynamically switching target as room positions change.

**Independent Test**: Spawn `forest_healer` alongside one other enemy. Observe the healer move toward the ally and stop when the gap is `heal_radius - 20` (= 60 for forest_healer). Move the player — the healer must not follow the player while an ally is alive.

### Tests for User Story 1

- [x] T002 [P] [US1] Create `tests/unit/test_enemy_healer_follow.gd` with stubs for a mock healer node and mock ally nodes (inline dicts, no autoloads). Cover: healer moves toward ally when too far, healer stops at `heal_radius - 20`, healer switches target when a closer ally appears, healer exposes `_follow_target` as null initially.

### Implementation for User Story 1

- [x] T003 [US1] In `scenes/combat/enemies/Enemy.gd`, add `var _follow_target: Enemy = null` alongside the existing runtime state field declarations (near `_heal_cooldown_remaining` on line 32). This field caches the closest ally reference for the current frame.

- [x] T004 [US1] In `scenes/combat/enemies/Enemy.gd`, insert a new healer movement branch at the start of the pursuit movement section (before the `not (_state == EnemyState.PURSUING …)` guard on line 214). The branch must:
  1. Return immediately (skip the branch) if `not _data.id.ends_with("_healer")`.
  2. Scan `get_parent().get_children()` for `Enemy` instances excluding `self`, tracking the closest by `global_position.distance_to()`.
  3. Store the closest ally in `_follow_target` (null if none found).
  4. If `_follow_target` is null: fall through to the existing player-chase path (no `return`).
  5. If `_follow_target` is non-null: compute distance; if greater than `_data.heal_radius - 20.0`, set `velocity` toward target at `_data.move_speed`; otherwise set `velocity = Vector2.ZERO`. Call `move_and_slide()` and `return` to skip the player-chase path.
  Use early returns and a `continue` guard for the sibling scan loop (Constitution VI). Maximum nesting depth: 2.

**Checkpoint**: forest_healer orbits its ally at 60 units standoff and ignores the player while allies are alive.

---

## Phase 4: User Story 2 — Healer Falls Back to Default Behavior When Alone (Priority: P2)

**Goal**: When all allies die, the healer immediately reverts to chasing the player.

**Independent Test**: Kill all non-healer enemies in a room. Observe the healer stop holding position and begin chasing the player.

### Tests for User Story 2

- [x] T005 [P] [US2] Extend `tests/unit/test_enemy_healer_follow.gd` with cases: no siblings → `_follow_target` is null → healer falls through to player-chase path; last ally dies (sibling list empty) → same result on next physics frame.

### Implementation for User Story 2

- [ ] T006 [US2] Verify (no code change needed) that the fall-through path implemented in T004 step 4 correctly handles the no-ally case: when `_follow_target` is null after the scan, the existing player-chase block executes unchanged. Run the game with only a healer in a room to confirm it chases the player.

**Checkpoint**: Lone healer chases the player — US1 and US2 both work end-to-end.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [ ] T007 [P] Run all existing GUT unit tests to confirm zero regressions in non-healer enemy behavior (`gut -gtest=tests/unit/` or via the Godot GUT panel).

- [ ] T008 Playtest a room containing `forest_healer` + at least one ally: verify healer orbits ally at ~60 px standoff, switches target when ally positions change, and chases player when all allies are dead.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately.
- **US1 (Phase 3)**: Depends on Phase 2 (insertion-point confirmation). T002 (test stub) and T003 (field declaration) can be done in parallel; T004 (movement branch) depends on T003.
- **US2 (Phase 4)**: T005 (test extension) can run in parallel with T004; T006 (verification) depends on T004.
- **Polish (Phase 5)**: Depends on US1 and US2 complete.

### Parallel Opportunities

- T002 and T003 can start together after T001.
- T005 can start while T004 is being written.

---

## Parallel Example: User Story 1

```
Parallel after T001:
  Task T002 — Write unit test stubs (tests/unit/test_enemy_healer_follow.gd)
  Task T003 — Add _follow_target field (scenes/combat/enemies/Enemy.gd)

Sequential after T002+T003:
  Task T004 — Insert healer movement branch (scenes/combat/enemies/Enemy.gd)
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 2 (T001) — confirm insertion point.
2. Complete Phase 3 (T002 → T003 → T004) — healer follows closest ally.
3. **STOP and VALIDATE** in-game: forest_healer orbits ally, ignores player.

### Incremental Delivery

1. US1 complete → healer orbits allies ✅
2. US2 complete → lone healer chases player ✅ (largely free — fall-through from US1)
3. Polish → regressions confirmed clear ✅

---

## Notes

- [P] tasks touch different files or are independent within the same file phase.
- T006 is a verification-only task — the fall-through behavior is implemented as part of T004; no separate code change is expected.
- All constitution principles pass: no new files beyond the test, no new JSON fields, no new autoload.
