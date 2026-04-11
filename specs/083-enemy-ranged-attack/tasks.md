# Tasks: Enemy Ranged Attack

**Input**: Design documents from `/specs/083-enemy-ranged-attack/`
**Prerequisites**: plan.md ✅, spec.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Exact file paths in every description

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Data config, new EnemyProjectile scene and script — must exist before Enemy.gd can reference them.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Add `"enemy_ranged_threshold": 40` to the `enemy_spawn` object in `data/dungeon_config.json` (alongside the existing `spawn_delay` field)
- [x] T002 [P] Create `scenes/combat/enemies/EnemyProjectile.gd` — `class_name EnemyProjectile extends Node2D`; `@export var _hit_area: Area2D`; `var _direction: Vector2`, `var _damage: float`, `var _speed: float = 400.0`, `var _distance_traveled: float = 0.0`, `const MAX_RANGE: float = 1200.0`; `setup(direction: Vector2, damage: float) -> void` stores direction (normalized) and damage, connects `_hit_area.body_entered` to `_on_body_entered`; `_physics_process(delta)` moves by `_direction * _speed * delta`, accumulates distance, calls `queue_free()` when `_distance_traveled >= MAX_RANGE`; `_on_body_entered(body)` returns early if body is not in group `"player"`, otherwise calls `body.get_node("StatsComponent").take_damage(_damage)` and calls `queue_free()`
- [ ] T003 Create `scenes/combat/enemies/EnemyProjectile.tscn` in the Godot Editor — Node2D root with `EnemyProjectile.gd` attached; child `Area2D` node named `HitArea` (assign to `_hit_area` export) with a `CircleShape2D` (radius 8); child `ColorRect` visual (small, distinct color e.g. orange); set the Area2D collision layer to 0 (no layer) and collision mask to the player's physics layer only — so it detects the player but never detects other enemies

**Checkpoint**: EnemyProjectile scene exists and is loadable. Enemy.gd can now reference it.

---

## Phase 2: User Story 1 — Ranged Enemy Fires Projectile (Priority: P1) 🎯 MVP

**Goal**: Enemies with attack_range > 40 fire a projectile when the player is in range instead of applying contact damage.

**Independent Test**: Spawn a `forest_healer` or `forest_buffer`, walk the player into attack range, and confirm a projectile appears traveling toward the player while no direct contact damage is applied.

- [x] T004 [P] [US1] Add `static func is_ranged_attacker(attack_range: float, threshold: float) -> bool` to `scripts/data_models/EnemyData.gd` — returns `attack_range > threshold`; pure static, no autoload calls
- [x] T005 [US1] Add `var _is_ranged: bool = false` field to `scenes/combat/enemies/Enemy.gd` (alongside other state fields near line 34); in `initialize(data: EnemyData)` after the existing `enemy_spawn_cfg` read (line ~79), read `float(enemy_spawn_cfg.get("enemy_ranged_threshold", 40.0))` and set `_is_ranged = EnemyData.is_ranged_attacker(data.attack_range, threshold)`
- [x] T006 [US1] Add `_fire_projectile() -> void` to `scenes/combat/enemies/Enemy.gd` — preloads `EnemyProjectile.tscn`, instantiates it, computes `direction = global_position.direction_to(_player_ref.global_position)` (guard: return early if `_player_ref` is not valid), calls `projectile.setup(direction, _data.damage)`, sets `projectile.global_position = global_position`, adds it as a sibling via `get_parent().add_child(projectile)`
- [x] T007 [US1] Modify the contact-damage tick in `_physics_process` in `scenes/combat/enemies/Enemy.gd` (lines ~210–215) — add guard at start of the tick block: `if _is_ranged: _fire_projectile(); _damage_timer = _data.damage_cooldown; return` so ranged enemies fire a projectile on the cooldown cycle instead of applying direct `take_damage`
- [x] T008 [US1] Create `tests/unit/test_enemy_ranged_attack.gd` — test `EnemyData.is_ranged_attacker()`: verify returns `false` at exactly 40, `false` below 40 (e.g. 20), `true` above 40 (e.g. 80); verify `true` at 41; verify custom threshold works (e.g. threshold 100 with range 80 → false)

**Checkpoint**: US1 functional. Ranged enemies fire projectiles; melee enemies unaffected.

---

## Phase 3: User Story 2 — Projectile Travels in a Straight Line (Priority: P1)

**Goal**: The projectile moves in a fixed direction set at fire time and does not home or curve.

**Independent Test**: Fire a projectile, move the player perpendicular — the projectile continues in the original direction and misses.

- [x] T009 [US2] Add direction-lock tests to `tests/unit/test_enemy_ranged_attack.gd` — instantiate `EnemyProjectile` without adding to tree; call `setup(Vector2.RIGHT, 10.0)`; assert `_direction` equals `Vector2.RIGHT`; call `setup(Vector2(3.0, 4.0), 5.0)`; assert `_direction` is approximately `Vector2(0.6, 0.8)` (normalized); assert `_damage == 5.0`; assert `_distance_traveled == 0.0` before any physics step

**Checkpoint**: US2 verified. Direction stored correctly at setup; no subsequent mutation path exists in the script.

---

## Phase 4: User Story 3 — Projectile Passes Through Enemies (Priority: P1)

**Goal**: The projectile collides only with the player; enemies in its path are unaffected.

**Independent Test**: Position enemies between the firing enemy and the player; confirm their HP is unchanged after a projectile passes through.

- [x] T010 [US3] Add pass-through logic test to `tests/unit/test_enemy_ranged_attack.gd` — instantiate `EnemyProjectile` without adding to tree; call `setup(Vector2.RIGHT, 10.0)`; call `_on_body_entered()` with a stub node NOT in the `"player"` group; assert `queue_free()` was NOT called (node remains valid); verify the early-return guard `if not body.is_in_group("player"): return` is the first statement in `_on_body_entered`
- [ ] T011 [US3] Verify `EnemyProjectile.tscn` collision mask in the Godot Editor — confirm the `HitArea` Area2D collision mask includes only the player physics layer and excludes the enemy physics layer; no script change required if T003 was done correctly

**Checkpoint**: All three user stories functional. Full feature complete.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately
- **US1 (Phase 2)**: Requires T001 (JSON), T002 (script), T003 (scene) complete
- **US2 (Phase 3)**: Requires T002 complete (tests reference EnemyProjectile.gd); independent of US1
- **US3 (Phase 4)**: Requires T002 + T003 complete; independent of US1 and US2

### Within Phase 1

- T001 and T002 are parallel (different files)
- T003 depends on T002 (scene attaches the script)

### Within Phase 2 (US1)

- T004 parallel with T005 (different files)
- T006 depends on T004 (calls `EnemyData.is_ranged_attacker`)
- T007 depends on T005 + T006
- T008 depends on T004 (tests the static method)

### Parallel Opportunities

- T001 + T002 in Phase 1
- T004 + T005 in Phase 2
- T009 (US2) + T010 (US3) can run in parallel after T002 is done

---

## Implementation Strategy

### MVP (Phase 1 + US1 only)

1. Complete Phase 1 (T001–T003) — EnemyProjectile scene ready
2. Complete Phase 2 (T004–T008) — Enemy.gd wired, ranged enemies fire
3. **STOP and VALIDATE**: Enter combat with forest_healer or forest_buffer — confirm projectile fires and no contact damage is applied
4. Melee enemies confirmed unchanged

### Incremental Delivery

1. Phase 1 → EnemyProjectile exists but nothing fires it yet
2. Phase 2 → Ranged enemies fire projectiles (all three behaviors active simultaneously since collision is set up in Phase 1)
3. Phase 3 → Direction-lock formally verified in tests
4. Phase 4 → Pass-through formally verified in tests + editor check
