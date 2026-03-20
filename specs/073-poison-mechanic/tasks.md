# Tasks: Poison Mechanic

**Input**: Design documents from `/specs/073-poison-mechanic/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Data schema and new shared class — blocks all user stories.

- [x] T001 Add `poison_duration: float = 0.0` and `poison_modifier: float = 0.0` to `EnemyData.gd` (fields + `from_dict()` parsing with 0.0 defaults) in `scripts/data_models/EnemyData.gd`
- [x] T002 [P] Add `poison_chance: float = 0.0`, `poison_duration: float = 0.0`, `poison_modifier: float = 0.0` to `RelicData.gd` (fields + `from_dict()` parsing with 0.0 defaults) in `scripts/data_models/RelicData.gd`
- [x] T003 [P] Fix `forest_poisoner.poison_modifier` from `10.0` to `0.10` in `data/enemies.json`
- [x] T004 Create `PoisonComponent` Node class with `apply(duration, modifier)`, `get_damage_mult()`, `is_poisoned` property, and `_physics_process` tick in `scripts/PoisonComponent.gd`
- [x] T005 Write GUT unit tests for `PoisonComponent` covering: fresh apply sets duration and modifier; re-apply stacks duration and keeps modifier; `get_damage_mult()` returns `1.0 - modifier` while active and `1.0` after expiry; apply with duration ≤ 0 is a no-op in `tests/unit/test_poison_component.gd`

**Checkpoint**: Data models extended, PoisonComponent implemented and tested — user story phases can begin.

---

## Phase 2: User Story 1 — Enemy Applies Poison to Player (Priority: P1) 🎯 MVP

**Goal**: Poisonous enemies (those with `poison_duration > 0` in enemies.json) reduce the player's outgoing attack damage while the player is poisoned.

**Independent Test**: Enter combat with the `forest_poisoner` enemy, take a contact hit, verify the player's melee attack damage is multiplied by `0.90` (1.0 − 0.10) for 3 seconds; take a second hit before expiry and verify duration extends.

- [ ] T006 [US1] Add `PoisonComponent` child node to Player in `scenes/player/Player.tscn` via the Godot Editor (script: `res://scripts/PoisonComponent.gd`; no Inspector exports needed)
- [x] T007 [US1] Add `_poison: PoisonComponent` field (instantiated in `_ready()` via `PoisonComponent.new(); add_child(...)`) to Enemy to track its own poison state, mirroring the existing `_root: RootComponent` pattern in `scenes/combat/enemies/Enemy.gd`
- [x] T008 [US1] Add `_player_poison: PoisonComponent` field to Enemy; grab it in `_on_contact_entered` via `body.get_node_or_null("PoisonComponent")` and clear in `_on_contact_exited` in `scenes/combat/enemies/Enemy.gd`
- [x] T009 [US1] Add `_try_apply_poison()` private method to Enemy: guard on `_data.poison_duration <= 0.0` and `_player_poison == null`; call `_player_poison.apply(_data.poison_duration, _data.poison_modifier)` in `scenes/combat/enemies/Enemy.gd`
- [x] T010 [US1] Call `_try_apply_poison()` after contact damage fires in Enemy `_physics_process` in `scenes/combat/enemies/Enemy.gd`
- [x] T011 [US1] Add `@onready var _poison: PoisonComponent = $"../PoisonComponent"` to CombatComponent; multiply final `dmg` by `_poison.get_damage_mult()` before `target.take_damage(dmg)` in `scenes/player/components/CombatComponent.gd`

**Checkpoint**: Poisonous enemy reduces player damage output for duration; stacking works; player without poison is unaffected.

---

## Phase 3: User Story 2 — Player Applies Poison to Enemy via Relic (Priority: P2)

**Goal**: The `venomous_strike` relic causes the player's melee hits to have a 25% chance to poison the struck enemy, reducing that enemy's outgoing contact damage.

**Independent Test**: Equip `venomous_strike` via DevPanel; land multiple melee hits; verify the enemy's contact damage decreases by ~15% roughly 1 in 4 hits; verify duration stacks on successive procs.

- [x] T012 [US2] Add `venomous_strike` relic entry (Common tier) to `data/relics.json`: `name: "Venom Fang"`, `tags: ["melee", "debuff"]`, `effect_stat: ""`, `effect_mult: 1.0`, `condition_type: ""`, `poison_chance: 0.25`, `poison_duration: 3.0`, `poison_modifier: 0.15`, `description: "Melee hits have a 25% chance to poison enemies, reducing their damage by 15% for 3s."`, `deck_count: 2`
- [x] T013 [US2] Add `apply_poison(duration: float, modifier: float)` public method to Enemy that delegates to `_poison.apply(duration, modifier)` in `scenes/combat/enemies/Enemy.gd`
- [x] T014 [US2] Add `POISON_RELIC_ID: String = "venomous_strike"` constant, `has_poison_relic() -> bool`, and `try_apply_poison(target: Enemy) -> void` (rolls `randf()` against relic's `poison_chance`; calls `target.apply_poison(duration, modifier)` on success) to `scripts/managers/RelicManagerImpl.gd`
- [x] T015 [US2] Add thin-wrapper method `try_apply_poison(target: Enemy) -> void` delegating to `_impl.try_apply_poison(target)` in `autoload/RelicManager.gd`
- [x] T016 [US2] Call `RelicManager.try_apply_poison(target)` after `target.take_damage(dmg)` in the melee attack block of CombatComponent `_physics_process` in `scenes/player/components/CombatComponent.gd`
- [x] T017 [US2] Multiply `_data.damage` by `_poison.get_damage_mult()` before `_player_stats.take_damage(...)` in Enemy `_physics_process` contact-damage block (reduces poisoned enemy's outgoing damage) in `scenes/combat/enemies/Enemy.gd`
- [x] T018 [US2] Write GUT unit tests for `RelicManagerImpl` poison methods: `has_poison_relic()` returns false when relic absent; `try_apply_poison()` is a no-op when relic absent; method reads correct fields from relic data in `tests/unit/test_relic_manager_impl_poison.gd`

**Checkpoint**: Player with relic probabilistically poisons enemies; enemy contact damage is visibly reduced; player without relic is unaffected.

---

## Phase 4: User Story 3 — Data-Driven Parameters (Priority: P3)

**Purpose**: Validate the system is fully data-driven; no editor or scene work needed — this phase is purely data + verification.

**Independent Test**: Change `forest_poisoner.poison_duration` from `3.0` to `6.0` and `poison_modifier` from `0.10` to `0.20` in `enemies.json`; verify in-game that poison now lasts 6 seconds and reduces player output by 20%; revert both values.

- [x] T019 [P] [US3] Verify `forest_poisoner` entry in `data/enemies.json` has correct final values: `poison_duration: 3.0`, `poison_modifier: 0.10` (the T003 fix should already satisfy this — confirm as a review step, no code change needed)
- [x] T020 [P] [US3] Verify `venomous_strike` entry in `data/relics.json` has correct final values: `poison_chance: 0.25`, `poison_duration: 3.0`, `poison_modifier: 0.15` (the T012 entry should already satisfy this — confirm as a review step, no code change needed)

**Checkpoint**: All parameters sourced exclusively from JSON; no numeric constants in any `.gd` file for poison values.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [ ] T021 [P] Verify `forest_poisoner` enemy spawns in at least one combat room (check `data/dungeon_config.json` spawn configs or add to an existing CombatRoom spawn config if absent) — no new file, edit `data/dungeon_config.json` if needed
- [ ] T022 [P] Confirm `venomous_strike` relic appears in DevPanel's "Get Relic" dropdown (relies on pool being built from `relics.json` — no code change expected; verify manually or via print statement)
- [ ] T023 Playtest validation: enter combat with `forest_poisoner`; get hit; verify player damage reduction is visible; acquire `venomous_strike` via DevPanel; verify enemy damage reduction on subsequent run

---

## Dependencies

```
T001 → T004 → T005        (data model first, then class, then tests)
T002 → T012               (RelicData fields needed before JSON entry adds meaning to parsing)
T003                      (independent data fix)

T004, T001 → T006         (PoisonComponent must exist before Editor task)
T004, T001 → T007, T008   (PoisonComponent must exist; EnemyData must have fields)
T007, T008 → T009 → T010  (sequential within Enemy.gd)
T006, T004 → T011         (Player node must have PoisonComponent; CombatComponent reads it)

T007 → T013               (Enemy must have _poison before apply_poison public method)
T002, T012 → T014         (RelicData fields + JSON entry needed for impl to read)
T014 → T015 → T016        (impl → wrapper → caller)
T010 → T017               (contact damage block already modified; add mult in same block)
T014, T015 → T018         (tests for the impl)

T003, T012 → T019, T020   (review tasks confirm data fixes are in place)
T016, T010 → T021, T022, T023
```

## Parallel Opportunities

**During Phase 1**:
- T001, T002, T003 can all run in parallel (different files)
- T004 starts immediately (no dependencies)
- T005 starts after T004

**During Phase 2** (after T001, T004 done):
- T007 and T008 can run in parallel (same file but logically separate additions; coordinate)
- T006 is independent of T007–T010 and can proceed in parallel

**During Phase 3** (after T001, T002, T004 done):
- T012, T013 can run in parallel (different files)
- T018 can run in parallel with T016 (different files)

**During Phase 4**:
- T019 and T020 are purely review steps — can run in parallel

## Implementation Strategy

**MVP (Phase 1 + Phase 2)**: Implements the core threat mechanic — poisonous enemies meaningfully reduce player effectiveness. This is the minimum to validate the mechanic feels good in play.

**Full delivery (+ Phase 3)**: Adds the offensive/relic side so the player can turn poison against enemies. Phase 4 is a data-hygiene confirmation requiring no code. Phase 5 is playtest validation.

**Total tasks**: 23
- Phase 1 (Setup): 5 tasks
- Phase 2 (US1): 6 tasks
- Phase 3 (US2): 7 tasks
- Phase 4 (US3): 2 tasks
- Phase 5 (Polish): 3 tasks

**Parallel opportunities**: 8 tasks marked `[P]`
