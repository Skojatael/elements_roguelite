---
description: "Task list for Enemy Combat System"
---

# Tasks: Enemy Combat System

**Input**: Design documents from `specs/002-enemy-combat/`
**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅

**Tests**: Not requested — no test tasks generated.

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Exact file paths are included in every description

## Path Conventions

Godot project — all paths are `res://`-relative from repository root:
- Scenes: `scenes/combat/enemies/`, `scenes/player/`, `scenes/core/`
- Scripts: co-located with their scenes (Principle V) or in `scripts/data_models/`
- Data: `data/`

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Scaffold scene hierarchies in the Godot Editor. These tasks
produce `.tscn` changes, not `.gd` changes.

- [ ] T001 In Godot Editor, create the folder `scenes/combat/enemies/` and build `Enemy.tscn`: root node type `CharacterBody2D`; add child `CollisionShape2D` with a `CircleShape2D` of radius 20 px; add child `Area2D` named `DetectionArea` with a `CollisionShape2D` child (circle radius 200 px); add child `Area2D` named `ContactArea` with a `CollisionShape2D` child (circle radius 22 px). File: `scenes/combat/enemies/Enemy.tscn`
- [ ] T002 [P] In Godot Editor, open `scenes/player/Player.tscn`: confirm `StatsComponent` (Node) and `CombatComponent` (Node) are direct children of the Player root; add a child `Area2D` named `AttackArea` under `CombatComponent` with a `CollisionShape2D` child (circle radius 30 px). File: `scenes/player/Player.tscn`

**Checkpoint**: Scene hierarchies exist; Editor shows no errors on scene load.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement the data layer, player health component, and coordinator
wiring that every user story depends on.

**⚠️ CRITICAL**: User story work cannot begin until all Phase 2 tasks are done.

- [x] T003 [P] Implement `scripts/data_models/EnemyData.gd`: change declaration to `class_name EnemyData extends Resource`; declare static-typed fields: `var id: String`, `var display_name: String`, `var max_health: float`, `var damage: float`, `var move_speed: float`, `var detection_range: float`, `var damage_cooldown: float`; implement `static func from_dict(data: Dictionary) -> EnemyData` that creates a new EnemyData instance, asserts all seven keys are present in `data`, assigns each field, and returns the instance. File: `scripts/data_models/EnemyData.gd`
- [x] T004 [P] Populate `data/enemies.json` with the initial Slime enemy type — replace the empty `{}` with: `{"enemies":[{"id":"slime","display_name":"Slime","max_health":3.0,"damage":1.0,"move_speed":60.0,"detection_range":200.0,"damage_cooldown":0.5}]}`. File: `data/enemies.json`
- [x] T005 [P] Implement `scenes/player/components/StatsComponent.gd`: declare `class_name StatsComponent extends Node`; add `@export var max_health: float = 10.0` and `var current_health: float`; declare `signal health_changed(new_health: float, max_health: float)` and `signal died`; implement `_ready()` — assert `max_health > 0.0`, set `current_health = max_health`; implement `take_damage(amount: float) -> void` — reduce `current_health = maxf(current_health - amount, 0.0)`, emit `health_changed(current_health, max_health)`, and if `current_health == 0.0` emit `died`; implement `heal(amount: float) -> void` — increase `current_health = minf(current_health + amount, max_health)`, emit `health_changed`. File: `scenes/player/components/StatsComponent.gd`
- [x] T006 Update `scenes/core/Main.gd`: add `@onready var _stats: StatsComponent = $Player/StatsComponent`; in `_ready()` after existing wiring, connect `_stats.died` to a new method `_on_player_died`; add `func _on_player_died() -> void` that calls `GlobalSignals.gameplay_ended.emit()`. File: `scenes/core/Main.gd`

**Checkpoint**: Foundation ready — EnemyData parses JSON correctly; player health is tracked; player death triggers gameplay_ended. No enemy scenes yet.

---

## Phase 3: User Story 1 — Encounter and Defeat Enemies (Priority: P1) 🎯 MVP

**Goal**: Player can damage enemies until their health reaches zero, at which
point enemies are removed from the scene.

**Independent Test**: Place one Slime enemy in Main.tscn. Run the project.
Walk the player into the enemy. After 3 attack intervals (attack_damage = 1,
max_health = 3), the enemy must disappear. No pursuit or player damage needed.

### Implementation for User Story 1

- [x] T007 [US1] Implement `scenes/combat/enemies/Enemy.gd`: declare `class_name Enemy extends CharacterBody2D`; add `@export var enemy_type_id: String = "slime"`; declare `var current_health: float`, `var _data: EnemyData`; declare `signal defeated`; implement `_ready()` — load `data/enemies.json` with `FileAccess.open("res://data/enemies.json", FileAccess.READ)`, parse JSON string, find the dict entry whose `"id"` matches `enemy_type_id` (assert one is found), call `initialize(EnemyData.from_dict(entry))`; implement `func initialize(data: EnemyData) -> void` — set `_data = data` and `current_health = data.max_health`; implement `func take_damage(amount: float) -> void` — set `current_health = maxf(current_health - amount, 0.0)`, if `current_health <= 0.0` emit `defeated` then call `queue_free()`. Attach script to Enemy node in Enemy.tscn. File: `scenes/combat/enemies/Enemy.gd`
- [x] T008 [P] [US1] Implement `scenes/player/components/CombatComponent.gd`: declare `class_name CombatComponent extends Node`; add `@export var attack_damage: float = 1.0` and `@export var attack_interval: float = 0.5`; declare `@onready var _attack_area: Area2D = $AttackArea`, `var _overlapping_enemies: Array = []`, `var _attack_timer: float = 0.0`; implement `_ready()` — assert `attack_damage > 0.0` and `attack_interval > 0.0`, connect `_attack_area.body_entered.connect(_on_body_entered)` and `_attack_area.body_exited.connect(_on_body_exited)`; implement `_on_body_entered(body: Node2D) -> void` — if `body is Enemy` append to `_overlapping_enemies`; implement `_on_body_exited(body: Node2D) -> void` — remove from `_overlapping_enemies` if present; implement `_physics_process(delta: float) -> void` — if `_overlapping_enemies.is_empty()` return, decrement `_attack_timer -= delta`, if `_attack_timer <= 0.0`: call `_overlapping_enemies[0].take_damage(attack_damage)` (check is_instance_valid first), reset `_attack_timer = attack_interval`. File: `scenes/player/components/CombatComponent.gd`
- [ ] T009 [Editor] [US1] In Godot Editor, instance `Enemy.tscn` as a child of `Main.tscn` (or `scenes/dungeon/rooms/CombatRoom01.tscn`); in the Inspector confirm `enemy_type_id` is set to `"slime"`. File: `scenes/core/Main.tscn`

**Checkpoint**: User Story 1 is fully functional — player auto-attacks enemy, enemy dies after 3 hits.

---

## Phase 4: User Story 2 — Receive Damage from Enemies (Priority: P2)

**Goal**: Enemies deal contact damage to the player, respecting a per-enemy
cooldown. Player health reaching zero triggers the run-end state.

**Independent Test**: With StatsComponent.max_health set to 2 in Inspector,
walk the player into a stationary Slime. Confirm health decreases by 1 no more
than once per 0.5 s. After 2 hits, gameplay_ended fires and HUD hides.

### Implementation for User Story 2

- [x] T010 [US2] In `scenes/combat/enemies/Enemy.gd`, add contact damage behaviour: declare `@onready var _contact_area: Area2D = $ContactArea`, `var _player_stats: StatsComponent = null`, `var _in_contact: bool = false`, `var _damage_timer: float = 0.0`; in `_ready()` connect `_contact_area.body_entered.connect(_on_contact_entered)` and `_contact_area.body_exited.connect(_on_contact_exited)`; implement `_on_contact_entered(body: Node2D) -> void` — if `body.has_node("StatsComponent")`: set `_player_stats = body.get_node("StatsComponent")`, `_in_contact = true`, `_damage_timer = 0.0`; implement `_on_contact_exited(body: Node2D) -> void` — set `_in_contact = false`; in `_physics_process(delta: float) -> void` (create or extend): if `_in_contact` and `_player_stats != null` and `is_instance_valid(_player_stats)`: decrement `_damage_timer -= delta`, if `<= 0.0`: call `_player_stats.take_damage(_data.damage)`, reset `_damage_timer = _data.damage_cooldown`. File: `scenes/combat/enemies/Enemy.gd`

**Checkpoint**: User Stories 1 AND 2 both work — player defeats enemies AND takes contact damage with cooldown.

---

## Phase 5: User Story 3 — Enemies Pursue the Player (Priority: P3)

**Goal**: Enemies detect the player within `detection_range` and move toward
them; they stop when the player exits that range.

**Independent Test**: Place Slime far from player start. Run project and walk
toward the Slime. When within 200 px, the Slime begins moving toward the player.
Walk away; Slime stops.

### Implementation for User Story 3

- [x] T011 [US3] In `scenes/combat/enemies/Enemy.gd`, add pursuit AI: declare `enum EnemyState { IDLE, PURSUING }`; `var _state: EnemyState = EnemyState.IDLE`; `var _player_ref: Node2D = null`; `@onready var _detection_area: Area2D = $DetectionArea`; in `_ready()` connect `_detection_area.body_entered.connect(_on_detected)` and `_detection_area.body_exited.connect(_on_lost)`; implement `_on_detected(body: Node2D) -> void` — if `body.has_node("StatsComponent")`: set `_player_ref = body`, `_state = EnemyState.PURSUING`; implement `_on_lost(body: Node2D) -> void` — if `body == _player_ref`: set `_state = EnemyState.IDLE`, `_player_ref = null`; in `_physics_process(delta: float) -> void`, add pursuit block: if `_state == EnemyState.PURSUING` and `is_instance_valid(_player_ref)`: set `velocity = global_position.direction_to(_player_ref.global_position) * _data.move_speed`, call `move_and_slide()`; else if `_state == EnemyState.IDLE`: set `velocity = Vector2.ZERO`. File: `scenes/combat/enemies/Enemy.gd`

**Checkpoint**: User Stories 1, 2, AND 3 functional — enemies pursue player, deal damage, and die.

---

## Phase 6: User Story 4 — Enemy Variety via Configurable Stats (Priority: P4)

**Goal**: A second enemy type with different stats can be placed in the same
room and behaves according to its own data, validating the data-driven system.

**Independent Test**: Spawn Slime (max_health 3) and Skeleton (max_health 6)
in the same room. Confirm Slime dies after 3 hits and Skeleton after 6 hits.
Edit Skeleton's damage in enemies.json and confirm change without code edits.

### Implementation for User Story 4

- [x] T012 [P] [US4] Add a second enemy type to `data/enemies.json`: append to the `"enemies"` array `{"id":"skeleton","display_name":"Skeleton","max_health":6.0,"damage":2.0,"move_speed":80.0,"detection_range":250.0,"damage_cooldown":1.0}`. File: `data/enemies.json`
- [ ] T013 [Editor] [P] [US4] In Godot Editor, add a second `Enemy.tscn` instance to the test scene; in the Inspector set `enemy_type_id` to `"skeleton"`. File: `scenes/core/Main.tscn`

**Checkpoint**: All four user stories independently functional.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Collision layer correctness and end-to-end validation.

- [ ] T014 [P] In Godot Editor, set collision layers/masks for correct interaction: Player body → Layer 1; Enemy body → Layer 2; DetectionArea mask → Layer 1 (detects player); ContactArea mask → Layer 1 (detects player); AttackArea mask → Layer 2 (detects enemies). Verify no unintended collisions occur. Files: `scenes/combat/enemies/Enemy.tscn`, `scenes/player/Player.tscn`
- [ ] T015 Run quickstart.md validation: perform all 7 steps in `specs/002-enemy-combat/quickstart.md` and confirm all 7 acceptance checklist items pass. File: `specs/002-enemy-combat/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
  - T001 before T009 (Enemy.tscn must exist before instancing)
  - T002 before T008 (AttackArea must exist before CombatComponent references it)
- **Foundational (Phase 2)**: Depends on Setup completion.
  - T003, T004, T005 fully parallel (different files)
  - T006 after T005 (needs StatsComponent class_name declared)
- **User Stories (Phase 3+)**: All depend on Phase 2 completion.
  - T007 before T010 before T011 (same file, sequential additions)
  - T008 parallel with T007 (different file)
  - T009 after T007 (needs Enemy script attached)
  - T012, T013 parallel (different targets)
  - T014 after T001, T002 (scene nodes must exist)
  - T015 after all implementation tasks

### User Story Dependencies

- **US1 (P1)**: After Phase 2 — no dependency on US2, US3, US4.
- **US2 (P2)**: After US1 T007 (extends Enemy.gd); independent of US3, US4.
- **US3 (P3)**: After US2 T010 (extends same Enemy.gd); independent of US4.
- **US4 (P4)**: After Phase 2 — foundation already supports it; T012/T013 are additive.

### Within Each User Story

- Data model (EnemyData) before runtime implementation (Enemy)
- Scene structure (Editor tasks) before script attachment
- Health tracking before damage delivery

### Parallel Opportunities

```
# Phase 2 — three independent streams:
Stream A: T003 (EnemyData.gd)
Stream B: T004 (enemies.json)
Stream C: T005 (StatsComponent.gd)

# Wait for all, then:
T006 (Main.gd wiring)

# Phase 3 (US1) — two independent streams:
Stream A: T007 → T010 → T011 (Enemy.gd additions)
Stream B: T008 (CombatComponent.gd)

# Phase 6 (US4) — two independent streams:
Stream A: T012 (enemies.json second type)
Stream B: T013 (Editor instance)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001, T002)
2. Complete Phase 2: Foundational (T003–T006)
3. Complete Phase 3: User Story 1 (T007–T009)
4. **STOP and VALIDATE**: Enemy takes damage and dies when player overlaps
5. Demo / playtest MVP

### Incremental Delivery

1. Setup + Foundational → infrastructure ready (no visible feature yet)
2. US1 → enemy can be killed → **MVP**
3. US2 → enemy deals contact damage back → full combat loop
4. US3 → enemy pursues player → dynamic encounters
5. US4 → second enemy type verified → data-driven system confirmed
6. Polish → collision layers verified, quickstart checklist passed

---

## Notes

- All `[P]` tasks operate on different files and have no dependency on incomplete tasks in the same phase.
- `[Story]` labels map directly to user stories in `specs/002-enemy-combat/spec.md`.
- Editor tasks (T001, T002, T009, T013, T014) modify `.tscn` files via the Godot Editor — do not edit `.tscn` as raw text (Constitution Principle IV).
- `StatsComponent` is identified by checking `body.has_node("StatsComponent")` rather than by group — no group setup required.
- `move_and_slide()` requires Enemy root to be CharacterBody2D (ensured by T001).
- Commit after each phase checkpoint before proceeding.
