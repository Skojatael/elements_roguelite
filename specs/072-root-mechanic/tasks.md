# Tasks: Root Mechanic

**Input**: Design documents from `/specs/072-root-mechanic/`
**Prerequisites**: spec.md ✓, plan.md ✓

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Data model and new component must exist before any story touches movement or enemy logic.

**⚠️ CRITICAL**: All story phases depend on these tasks.

- [x] T001 Add `root_duration: float = 0.0` and `root_cooldown: float = 0.0` fields to `scripts/data_models/EnemyData.gd`; parse both via `.get()` with `0.0` defaults in `from_dict()` — backward-compatible
- [x] T002 [P] Create `scenes/player/components/RootComponent.gd` with `class_name RootComponent extends Node`; declare `_root_remaining: float = 0.0`; add computed property `var is_rooted: bool` returning `_root_remaining > 0.0`; add `apply_root(duration: float) -> void` using `maxf` refresh logic; tick `_root_remaining` down in `_physics_process(delta)`

**Checkpoint**: `EnemyData` carries root fields; `RootComponent` script exists and compiles — story work can begin.

---

## Phase 2: User Story 1 — Enemy Roots Player on Melee Hit (Priority: P1) 🎯 MVP

**Goal**: A root-capable enemy (forest_disruptor) roots the player on contact damage; root expires automatically.

**Independent Test**: Start a run, let forest_disruptor hit the player — player cannot move for ~0.6 s then regains movement automatically.

- [x] T003 [US1] In `scenes/player/components/MovementComponent.gd`, add `@export var _root: RootComponent`; in `_physics_process` add early guard — if `_root != null and _root.is_rooted`, zero velocity, call `move_and_slide()`, and return
- [x] T004 [US1] In `scenes/combat/enemies/Enemy.gd`, add `_player_root: RootComponent = null` and `_root_cooldown_remaining: float = 0.0`; in `_on_contact_entered` assign `_player_root = body.get_node_or_null("RootComponent")`; null it in `_on_contact_exited`; tick `_root_cooldown_remaining` down each frame (guarded by `> 0.0`); after contact-damage fires, if `_data.root_duration > 0.0` and `_root_cooldown_remaining <= 0.0` call `_player_root.apply_root(_data.root_duration)` and reset `_root_cooldown_remaining = _data.root_cooldown`
- [ ] T005 [US1] In the Godot Editor: add a `Node` child named `RootComponent` to `Player.tscn`, attach `RootComponent.gd`; assign the `_root` export on `MovementComponent` to point to this node

**Checkpoint**: US1 fully playable — root applies and expires correctly.

---

## Phase 3: User Story 2 — Player Roots Enemies via Root Relic (Priority: P2)

**Goal**: Equipping the Root Relic gives melee hits a 20% chance to root the struck enemy for 0.6 s. Rooted enemies stop pursuing. All values read from relic data.

**Independent Test**: Equip the Root Relic (via DevPanel), land many melee hits — enemy freezes periodically (≈20% of hits) for ≈0.6 s; without the relic, no enemy root ever occurs.

- [x] T009 [P] [US2] In `scripts/data_models/RelicData.gd`, add `var root_chance: float = 0.0` and `var root_duration: float = 0.0`; parse both in `from_dict()` with `.get("root_chance", 0.0)` and `.get("root_duration", 0.0)`
- [x] T010 [P] [US2] In `data/relics.json`, add entry `"root_relic"` inside the `"uncommon"` dictionary: `"name": "Rootweave Band"`, `"tags": ["melee"]`, `"effect_stat": ""`, `"effect_mult": 1.0`, `"condition_type": "root_on_melee_hit"`, `"root_chance": 0.20`, `"root_duration": 0.6`, `"description": "Melee hits have a 20% chance to root enemies for 0.6s."`, `"deck_count": 1`
- [x] T011 [US2] In `scripts/managers/RelicManagerImpl.gd`, add `has_root_relic() -> bool` returning `active_relic_ids.has("root_relic")`; add `get_root_on_hit_duration() -> float` — early-return `0.0` if `has_root_relic()` is false; look up the relic in `_relics_by_id`, roll `randf()`, return the relic's `root_duration` if `randf() < root_chance` else `0.0` (depends on T009, T010)
- [x] T012 [US2] In `autoload/RelicManager.gd`, add `func has_root_relic() -> bool` delegating to `_impl.has_root_relic()` and `func get_root_on_hit_duration() -> float` delegating to `_impl.get_root_on_hit_duration()` (depends on T011)
- [x] T013 [US2] In `scenes/combat/enemies/Enemy.gd`, add `var _root: RootComponent = null`; in `_ready()` instantiate `_root = RootComponent.new()` and call `add_child(_root)`; add public `func apply_root(duration: float) -> void` delegating to `_root.apply_root(duration)`; in `_physics_process` after the spawn-delay guard, add early-return: if `_root != null and _root.is_rooted`, set `velocity = Vector2.ZERO`, call `move_and_slide()`, and return (depends on T002)
- [x] T014 [US2] In `scenes/player/components/CombatComponent.gd`, after `target.take_damage(dmg)`, add: `var root_dur: float = RelicManager.get_root_on_hit_duration()` and `if root_dur > 0.0: target.apply_root(root_dur)` (depends on T012, T013)
- [x] T015 [P] [US2] Write GUT unit tests in `tests/unit/test_relic_manager_impl_root_relic.gd`; instantiate `RelicManagerImpl` directly; call `build_pool()` with a synthetic relics dict containing `root_relic` with `root_chance: 1.0` and `root_duration: 0.6`; call `pick_relic("root_relic")`; assert `has_root_relic()` is true; assert `get_root_on_hit_duration()` returns `0.6` (chance=1.0 always hits); also test with `root_chance: 0.0` — assert always returns `0.0`; also test without picking any relic — assert always returns `0.0` (depends on T009, T011)

**Checkpoint**: US2 fully playable — relic roots enemies at the configured rate; no false positives without the relic.

---

## Phase 4: User Story 3 — Root Refresh Behaviour (Priority: P3)

**Goal**: A second root applied while already rooted refreshes to the longer of the two durations — no stacking, no infinite extension.

**Independent Test**: `apply_root(1.5)` followed by `apply_root(0.6)` leaves `_root_remaining` at 1.5; `apply_root(0.6)` followed by `apply_root(1.5)` leaves `_root_remaining` at 1.5.

- [x] T006 [US3] Write GUT unit tests in `tests/unit/test_root_component.gd`; test `apply_root` refresh-to-longest logic, expiry, and zero/negative duration edge cases using a manually instantiated `RootComponent` (no autoloads needed)

**Checkpoint**: `apply_root` refresh behaviour verified by unit tests.

---

## Phase 5: User Story 4 — Root Prevents Dodge (Priority: P4)

**Goal**: `DodgeComponent.activate()` is suppressed while rooted; dodge works normally after root expires.

**Independent Test**: Root the player, press dodge — dash does not fire; wait for root to expire, press dodge — dash fires.

- [x] T007 [US4] In `scenes/player/components/DodgeComponent.gd`, add `@export var _root: RootComponent`; add early-return guard in `activate()` after existing guards: `if _root != null and _root.is_rooted: return`
- [ ] T008 [US4] In the Godot Editor: assign the `_root` export on `DodgeComponent` to the `RootComponent` node inside `Player.tscn` (depends on T005)

**Checkpoint**: All four user stories fully implemented and independently testable.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies — start immediately; T001 and T002 are parallel
- **Phase 2 (US1)**: Depends on T001 + T002
- **Phase 3 (US2)**: T009 and T010 depend on T002 only; T011 depends on T009+T010; T012 on T011; T013 on T002; T014 on T012+T013; T015 on T009+T011
- **Phase 4 (US3)**: Depends on T002 only (RootComponent must exist to test)
- **Phase 5 (US4)**: T008 depends on T005 (RootComponent wired in Player.tscn)

### Parallel Opportunities

- T001 and T002 (Phase 1) can run in parallel — different files
- T003 and T004 (Phase 2) can run in parallel — different files; both depend on T001+T002
- T009 and T010 (Phase 3) can run in parallel — different files
- T013 and T014 can be started in parallel once their respective dependencies are met
- T015 can run in parallel with T014 (different files; both depend on T011)
- T006 (Phase 4) can run in parallel with all of Phase 3 — only depends on T002

---

## Implementation Strategy

### MVP (US1 only — enemy roots player)

1. T001 + T002 in parallel
2. T003 + T004 in parallel
3. T005 (editor wiring)
4. **Validate**: let forest_disruptor hit the player in-game

### Relic extension (US2)

5. T009 + T010 in parallel
6. T011 (depends on T009+T010)
7. T012 (depends on T011)
8. T013 (can overlap with T012)
9. T014 (depends on T012+T013)
10. T015 (unit tests — can run after T011)

### Full delivery

11. T006 (unit test — can run any time after T002)
12. T007 + T008 (dodge suppression; T008 after T005)

---

## Notes

- `enemies.json` already has `root_duration: 0.6` and `root_cooldown: 2.0` on `forest_disruptor` — no JSON changes needed for Phase 2
- T005 and T008 are Godot Editor tasks (Inspector wiring); cannot be done in code
- `RootComponent` has no autoload dependencies — unit tests in T006 can instantiate it directly
- `RelicManagerImpl` unit tests (T015) require synthetic relic data passed to `build_pool()` — no autoloads needed
- Enemy's `RootComponent` is instantiated via `add_child()` in `_ready()` (T013) — no `.tscn` edit needed
