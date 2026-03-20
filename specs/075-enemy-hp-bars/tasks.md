# Tasks: Enemy HP Bars

**Input**: Design documents from `/specs/075-enemy-hp-bars/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Fix `apply_difficulty()` so the HP bar reflects scaled stats. Must complete before any story work.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 In `scenes/combat/enemies/Enemy.gd`, update `apply_difficulty(mult)` to emit `_stats.health_changed` after writing `_stats.max_health` and `_stats.current_health`, so any connected HP bar updates immediately when difficulty scaling is applied.

**Checkpoint**: `apply_difficulty()` now emits `health_changed` — HP bar listeners will receive the corrected scaled values.

---

## Phase 3: User Story 1 — HP Bar Visible Under Enemy (Priority: P1) 🎯 MVP

**Goal**: Each enemy spawned in a combat room displays a health bar positioned below its sprite. The bar shrinks as the enemy takes damage and disappears when the enemy is freed.

**Independent Test**: Start a run, enter any combat room, confirm an HP bar appears under each enemy, shrinks on hit, and vanishes on kill.

### Implementation for User Story 1

- [ ] T002 [US1] In the Godot Editor, open `scenes/combat/enemies/Enemy.tscn`. Add an instanced child node of `scenes/ui/hud/HPBar.tscn` to the root `Enemy` node. Set its local position to approximately `(-50, 30)` so the bar is centred below the enemy's sprite. Assign the new node to the `_hp_bar` export slot on the Enemy script (created in T003).
- [x] T003 [US1] In `scenes/combat/enemies/Enemy.gd`, add `@export var _hp_bar: HPBar`. At the end of `_ready()`, after the `initialize()` call, add `_hp_bar.setup(_stats)` to connect the bar to the enemy's StatsComponent.

**Checkpoint**: Every enemy in a combat room shows a live HP bar that follows it and empties to zero on death.

---

## Phase 4: User Story 2 — Bar Matches Player HP Bar Behaviour (Priority: P2)

**Goal**: The enemy HP bar follows the same fill-fraction logic as the player bar, including growing back when a healer enemy restores health.

**Independent Test**: Spawn a `forest_healer` enemy alongside a damaged enemy; confirm the damaged enemy's bar grows as the healer applies healing.

### Implementation for User Story 2

No additional code required — `HPBar.setup()` connects to `health_changed`, which fires on both `take_damage` and `heal`. The foundational fix (T001) ensures `apply_difficulty()` also triggers an update. This story is satisfied by T001–T003.

- [ ] T004 [US2] Manual validation: confirm that after a `forest_healer` restores HP on an ally enemy (once healer AI is wired), the target enemy's bar visibly grows. If the healer's `heal()` call on the ally goes through `StatsComponent.heal()`, no additional code is needed — log a pass or file a follow-up task if the healer bypasses StatsComponent.

**Checkpoint**: HP bar behaviour is visually consistent with the player HP bar across all HP change sources.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [ ] T005 In the Godot Editor, fine-tune the `HPBar` child node position and size in `Enemy.tscn` so the bar looks visually centred and proportional at runtime on a 1080×1920 portrait screen.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately.
- **User Story 1 (Phase 3)**: Depends on T001 (apply_difficulty fix). T002 and T003 can be done in parallel once T001 is merged.
- **User Story 2 (Phase 4)**: Satisfied by T001–T003. T004 is a manual validation step.
- **Polish (Phase 5)**: Depends on T002 (bar must exist in editor before size tuning).

### Within User Story 1

- T002 (editor) and T003 (script) can be done in parallel — they touch different parts of the same scene.
- T003 requires the `_hp_bar` export node to exist in the scene (T002) before it can be assigned in the Inspector.

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete T001 (apply_difficulty fix)
2. Complete T002 + T003 in parallel
3. **Validate**: enter a combat room, confirm HP bars appear, shrink on damage, disappear on death

### Full Delivery

1. T001 → T002 + T003 → T004 (manual check) → T005 (polish)
