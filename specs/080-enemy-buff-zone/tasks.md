# Tasks: Enemy Buff Zone

**Input**: Design documents from `/specs/080-enemy-buff-zone/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Exact file paths included in all descriptions

---

## Phase 1: Foundational (Blocking Prerequisite)

**Purpose**: Extend `EnemyData` with buff fields so all subsequent tasks have typed data to read.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Add five optional float fields to `scripts/data_models/EnemyData.gd`: `buff_zone_radius`, `buff_cooldown`, `buff_zone_duration`, `buff_regen_rate`, `buff_attack_speed_bonus` — all default to `0.0`; parse each via `data.get(field, 0.0)` in `from_dict`, following the pattern of `root_duration` / `poison_modifier`

**Checkpoint**: `EnemyData.from_dict` correctly reads all buff fields (with and without them present in JSON) before any zone or enemy logic is written.

---

## Phase 2: User Stories 1 & 4 — Buff Zone Appears, Persists, and Excludes Player (Priority: P1) 🎯 MVP

**Goal**: A buffer enemy periodically spawns a circular zone at the position of the enemy closest to the player. The zone persists for its configured duration then disappears. The player walking into the zone has no effect.

**Independent Test**: Spawn a `forest_buffer` in a combat room; observe a colored circle appear near the enemy cluster after `buff_cooldown` seconds, persist for `buff_zone_duration`, then disappear. Walk the player into it and confirm no stat change.

### Tests for Phase 2

- [x] T002 [P] Create `tests/unit/test_enemy_buff_zone.gd` — cover `EnemyData.from_dict` with all five buff fields present (verify correct values) and with all five absent (verify 0.0 defaults); use inline dict stubs, no autoloads

### Implementation for Phase 2

- [x] T003 [P] Create `scenes/combat/enemies/EnemyBuffZone.gd` — `class_name EnemyBuffZone extends Area2D`; exported `_collision_shape: CollisionShape2D` and `_visual: ColorRect`; public `setup(radius: float, duration: float, regen_rate: float, attack_speed_bonus: float)` method that stores values and sizes the collision circle and visual; counts down duration in `_process` and calls `queue_free()` on expiry; `body_entered` / `body_exited` callbacks guarded with `if not body is Enemy: return` (player exclusion — US4); tracks `_buffed_enemies: Array[Enemy]`
- [ ] T004 *(editor task)* Create `scenes/combat/enemies/EnemyBuffZone.tscn` in the Godot Editor: Area2D root node, `CollisionShape2D` child with a `CircleShape2D` resource, `ColorRect` child for the visual; attach `EnemyBuffZone.gd` to the root; assign `_collision_shape` and `_visual` exports via the Inspector
- [x] T005 [US1] Add buff-cast behaviour to `scenes/combat/enemies/Enemy.gd`: add `_buff_cooldown_remaining: float = 0.0`; in `initialize()` set it to `data.buff_cooldown`; in `_physics_process()` add a cast block guarded by `if _data.buff_cooldown <= 0.0: return` (early return, then tick timer and spawn); the spawn logic scans `get_parent().get_children()` for the `Enemy` sibling with the shortest distance to `_player_ref` (skip self, skip non-Enemy; fall back to `global_position` if `_player_ref` is null or no siblings found); preload and instantiate `EnemyBuffZone.tscn`, call `setup()` with caster's buff values, set `global_position` to the chosen position, add as sibling via `get_parent().add_child(zone)`, reset `_buff_cooldown_remaining`

**Checkpoint**: Zone appears at correct position on cooldown, persists for configured duration, disappears on expiry, player entry has no effect.

---

## Phase 3: User Stories 2 & 3 — Buff Effects Applied on Entry and While Inside (Priority: P2)

**Goal**: Enemies inside the zone gain only the bonuses configured for that caster (`buff_regen_rate` and/or `buff_attack_speed_bonus`). Bonuses apply immediately on entry, are removed immediately on exit or zone expiry, and stack additively from overlapping zones.

**Independent Test**: Place a regen-only zone over two enemies — verify HP rises each second and attack interval is unchanged. Place an attack-speed-only zone — verify attack interval shortens and HP does not regen. Move an enemy out mid-duration — verify bonus drops immediately.

### Tests for Phase 3

- [x] T006 [P] [US2] Extend `tests/unit/test_enemy_buff_zone.gd` — add tests for `apply_zone_buff` and `remove_zone_buff` accumulation: call `apply_zone_buff(0.05, 0.25)` twice and assert accumulators equal 0.10 and 0.50; call `remove_zone_buff(0.05, 0.25)` once and assert accumulators equal 0.05 and 0.25; verify clamping to 0.0 on over-remove

### Implementation for Phase 3

- [x] T007 [P] [US2] Add accumulator fields and public methods to `scenes/combat/enemies/Enemy.gd`: `_zone_regen_rate: float = 0.0` and `_zone_attack_speed_bonus: float = 0.0`; `apply_zone_buff(regen: float, speed: float) -> void` adds to each accumulator; `remove_zone_buff(regen: float, speed: float) -> void` subtracts and clamps each to `maxf(0.0, value)`
- [x] T008 [P] [US2] Implement buff application callbacks in `scenes/combat/enemies/EnemyBuffZone.gd`: in `body_entered`, after the `is Enemy` guard, cast `body` to `Enemy`, call `apply_zone_buff(regen_rate, attack_speed_bonus)`, and add to `_buffed_enemies`; in `body_exited`, remove from list and call `remove_zone_buff`; in the expiry path (before `queue_free()`), iterate `_buffed_enemies` and call `remove_zone_buff` on each valid instance
- [x] T009 [US2] Modify regen tick in `scenes/combat/enemies/Enemy.gd`: change the existing `if _data.regen_rate > 0.0` block to use `_data.regen_rate + _zone_regen_rate` as the rate argument to `StatsComponent.regen_tick_amount`; guard with `if _data.regen_rate + _zone_regen_rate <= 0.0: skip` (early return / continue pattern)
- [x] T010 [US2] Modify attack timer reset in `scenes/combat/enemies/Enemy.gd`: wherever `_damage_timer` is reset to `_data.damage_cooldown`, compute the effective interval as `_data.damage_cooldown / (1.0 + _zone_attack_speed_bonus)` so a non-zero bonus produces a shorter interval; guard with `maxf` to prevent division producing a timer below a safe floor (e.g. `maxf(0.1, effective)`)

**Checkpoint**: All four buff scenarios work correctly — regen-only, speed-only, both, neither. Stacking from two overlapping zones doubles the effect. Exit removes the bonus immediately. Expiry removes it from all enemies still inside.

---

## Phase 4: Polish

**Purpose**: Visual clarity and edge-case robustness.

- [x] T011 Set a distinct translucent color on `EnemyBuffZone`'s `ColorRect` visual in `EnemyBuffZone.gd` `setup()` so the zone is clearly visible on the ground — use a fixed color constant defined at the top of the script (satisfies Constitution II for visual tuning; no balance value involved)
- [x] T012 Add `is_instance_valid` guard in `EnemyBuffZone.gd` expiry loop over `_buffed_enemies` to safely skip any enemy that died while inside the zone before expiry

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately
- **Phase 2 (US1+US4)**: Depends on T001 — `EnemyData` must have buff fields
- **Phase 3 (US2+US3)**: Depends on T003 (EnemyBuffZone.gd must exist) and T007 (Enemy accumulators must exist)
- **Phase 4 (Polish)**: Depends on all prior phases complete

### User Story Dependencies

- **US1+US4 (Phase 2)**: Requires T001 only
- **US2+US3 (Phase 3)**: Requires T003 (zone script), T004 (tscn), T007 (Enemy methods)
- T009 and T010 (regen + attack speed ticks) depend on T007

### Parallel Opportunities

Within Phase 2: T002 and T003 can run in parallel (different files, no shared dependency)
Within Phase 3: T006, T007, and T008 can all run in parallel (different concerns / files)

---

## Implementation Strategy

### MVP (Phase 1 + Phase 2 only)

1. T001 — extend EnemyData
2. T002 — write data-layer unit test
3. T003 — create EnemyBuffZone.gd
4. T004 — create EnemyBuffZone.tscn in editor
5. T005 — wire cast logic in Enemy.gd
6. **Validate**: zone appears, persists, disappears; player unaffected

### Full Feature (add Phase 3)

7. T006 — extend unit test for accumulators
8. T007 + T008 (parallel) — Enemy methods + zone callbacks
9. T009 + T010 (parallel) — regen and attack speed ticks
10. **Validate**: buff effects apply, stack, and remove correctly

### Polish (Phase 4)

11. T011 + T012 — visual color and expiry guard

---

## Notes

- T004 is an **editor task** — requires opening `EnemyBuffZone.tscn` in the Godot Editor
- `[P]` tasks touch different files and have no shared incomplete dependency — safe to run simultaneously
- US4 (player exclusion) is implemented as a single `if not body is Enemy: return` guard in T003/T008 — no dedicated phase needed
- US2 and US3 share the same implementation path (entry callback handles both "already inside" at zone spawn and "walks in later"); they are combined in Phase 3
