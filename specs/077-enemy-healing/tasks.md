# Tasks: Enemy Healing Mechanics

**Input**: Design documents from `/specs/077-enemy-healing/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks grouped by user story. US1 = enemy regen (passive self-heal). US2 = enemy ally-heal skill.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 or US2

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extend the `EnemyData` data model and its unit tests. Both user stories depend on the new fields.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Add `var regen_rate: float = 0.0`, `var heal_amount: float = 0.0`, `var heal_radius: float = 0.0`, `var heal_cooldown: float = 5.0` to `scripts/data_models/EnemyData.gd` after the existing optional fields. In `from_dict`, read each with `data.get(...)` and the matching default, following the existing `root_duration` / `poison_duration` pattern.
- [x] T002 [P] Create `tests/unit/test_enemy_data_healing.gd` extending `GutTest`. Preload `EnemyData`. Test: (a) a full dict with all four fields populates each field correctly; (b) a dict with no new fields defaults `regen_rate=0.0`, `heal_amount=0.0`, `heal_radius=0.0`, `heal_cooldown=5.0`; (c) a dict with only `heal_cooldown: 0` stores `0.0` as-is (no clamping in the data model). Can run in parallel with T001 (different file). Depends on T001 to pass at runtime.

**Checkpoint**: `EnemyData` fully extended. Both user stories can proceed.

---

## Phase 3: User Story 1 — Enemy Regeneration (Priority: P1) 🎯 MVP

**Goal**: Enemies with `regen_rate > 0` continuously recover HP during combat at `regen_rate × max_HP` per second, capped at max HP. Enemies with no `regen_rate` field are unaffected.

**Independent Test**: Open `data/enemies.json`, temporarily add `"regen_rate": 0.05` to the slime entry. Start a run, damage the slime without killing it, then stop attacking. Observe the HP bar slowly refilling. Remove the temporary field afterward.

### Implementation for User Story 1

- [x] T003 [US1] In `scenes/combat/enemies/Enemy.gd`, inside `_physics_process(delta)`, add a regen block after the existing burn/root/contact-damage blocks. Guard: `if _data.regen_rate <= 0.0: skip`. Call `_stats.heal(StatsComponent.regen_tick_amount(_data.regen_rate, _stats.max_health, delta))`. No new state variable is needed — `delta` is used directly each frame. Depends on T001.

**Checkpoint**: Enemies with `regen_rate` in JSON visibly recover HP. No existing enemies are affected.

---

## Phase 4: User Story 2 — Enemy Ally Heal Skill (Priority: P2)

**Goal**: Enemies with `heal_amount > 0` periodically restore `heal_amount` HP to all living ally `Enemy` instances within `heal_radius`, on a `heal_cooldown` cycle. The caster does NOT heal itself.

**Independent Test**: Set `forest_healer` in `data/enemies.json` to have `heal_amount: 8`, `heal_radius: 80`. Spawn a forest_healer alongside a damaged slime within 80 px. Wait 5 seconds. Observe the slime's HP bar increase by 8. Verify the healer's own HP bar does not change. Move the slime > 80 px away and verify no heal occurs.

### Implementation for User Story 2

- [x] T004 [US2] Add public method `receive_heal(amount: float) -> void` to `scenes/combat/enemies/Enemy.gd`. Body: call `_stats.heal(amount)`. This is the safe external entry point so the heal-skill caster does not reach into another instance's `_stats` directly. Depends on T001.
- [x] T005 [US2] Add private state variable `_heal_cooldown_remaining: float = 0.0` to `scenes/combat/enemies/Enemy.gd`. In `initialize(data)`, set `_heal_cooldown_remaining = data.heal_cooldown`. Depends on T001.
- [x] T006 [US2] In `scenes/combat/enemies/Enemy.gd`, inside `_physics_process(delta)`, add a heal-skill block after the regen block. Guard: `if _data.heal_amount <= 0.0: skip`. Decrement `_heal_cooldown_remaining -= delta`. When `_heal_cooldown_remaining <= 0.0`: iterate `get_parent().get_children()`, for each child that `is Enemy` and is not `self` and whose `global_position` distance to `global_position` is ≤ `_data.heal_radius`, call `child.receive_heal(_data.heal_amount)`. Then reset `_heal_cooldown_remaining = _data.heal_cooldown`. Depends on T004, T005.

**Checkpoint**: `forest_healer` heals nearby allies every 5 s (default cooldown). Healer itself is unaffected. Allies outside radius unaffected.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T007 Run existing unit tests to confirm no regressions: `test_enemy_data_healing.gd` passes; `test_damage_reduction.gd` and `test_regen_math.gd` pass (StatsComponent unchanged).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: T001 and T002 can start in parallel immediately (different files). T002 depends on T001 to pass.
- **US1 (Phase 3)**: T003 depends on T001.
- **US2 (Phase 4)**: T004, T005 depend on T001. T006 depends on T004 and T005.
- **Polish (Phase 5)**: After T003 and T006.

### User Story Dependencies

- **US1**: Depends only on T001 (EnemyData). Independent of US2.
- **US2**: Depends on T001 (EnemyData). Independent of US1 — can be worked in parallel once foundational is done.

### Parallel Opportunities

- T001 ‖ T002 (data model vs test file)
- T003 (US1) ‖ T004 + T005 (US2) — different code blocks in the same file; must be sequential within Enemy.gd edits but logically independent

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. T001 (extend EnemyData)
2. T002 (write + verify test)
3. T003 (regen tick in Enemy.gd)
4. **Validate**: Add `regen_rate` to any enemy in JSON, start a run, confirm HP bar fills passively.

### Full Delivery

1. Foundational: T001 + T002
2. US1: T003
3. US2: T004 → T005 → T006
4. Polish: T007
