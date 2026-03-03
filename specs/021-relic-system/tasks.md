# Tasks: Relic System

**Input**: Design documents from `specs/021-relic-system/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- **[EDITOR]**: Must be done in the Godot Editor (scene/node hierarchy, @export assignments, Project Settings)

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Data layer and typed models. All 4 tasks are parallel (different files). All user stories depend on this phase.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T001 [P] Create `data/relics.json` with the 5-relic initial pool: `sharp_edge` (attack_damage ×1.2 common), `rage_crystal` (attack_damage ×1.3 rare), `swift_strike` (attack_speed ×1.25 common), `iron_hide` (max_health ×1.3 common), `vital_core` (max_health ×1.5 rare) — each entry has `id`, `name`, `tier`, `tags`, `effect_stat`, `effect_mult`, `description` fields per data-model.md schema
- [X] T002 [P] Create `scripts/data_models/RelicData.gd` with `class_name RelicData extends RefCounted` — fields: `id: String`, `name: String`, `tier: String`, `tags: Array[String]`, `effect_stat: String`, `effect_mult: float = 1.0`, `description: String`; static factory `from_dict(data: Dictionary) -> RelicData` iterating `tags` array with typed `str()` conversion per contracts/interfaces.md
- [X] T003 [P] Modify `scripts/data_models/PlayerState.gd` — replace stub `var modifiers: Array = []` with `var active_modifiers: Array[String] = []` and update the comment to reflect it is populated by RelicManager.pick_relic()
- [X] T004 [P] Modify `scripts/managers/ResourceManager.gd` (ResourceManagerImpl) — add `_relics_cache: Dictionary`, `_relics_loaded: bool`, and `get_relics() -> Dictionary` method (same load/cache pattern as `get_meta_config()`; file path: `res://data/relics.json`); add `func get_relics() -> Dictionary: return _impl.get_relics()` delegation to `autoload/ResourceManager.gd`

**Checkpoint**: Data files exist, RelicData typed model available, PlayerState updated, ResourceManager can load relics — user story phases can begin.

---

## Phase 2: User Story 1 — Core Relic Pick Flow (Priority: P1) 🎯 MVP

**Goal**: After clearing any room, an offer screen appears with 2 distinct relics. Player picks one, screen closes, stat effect applies immediately and persists through rooms.

**Independent Test**: Start a run. Clear a combat room. Confirm offer screen appears with 2 relics (distinct names, descriptions). Tap one. Confirm screen closes and joystick is re-enabled. Check Output panel for `[RelicManager] relic picked — id=<id>`. Confirm attack_damage in CombatComponent equals `base × MetaManager.damage_multiplier × effect_mult` if an attack_damage relic was picked. Confirm max_health increased if a max_health relic was picked.

### Implementation

- [X] T005 [US1] Create `scripts/managers/RelicManagerImpl.gd` with `class_name RelicManagerImpl extends RefCounted` — implement: `const OFFER_INTERVAL: int = 2`; fields `active_relic_ids: Array[String]`, `standard_rooms_cleared: int`; `reset()` clears both; `should_offer_for_room(room_type_id: String) -> bool` — returns `true` if `room_type_id.contains("Elite")`, otherwise increments `standard_rooms_cleared` and returns `true` + resets counter to 0 when it reaches `OFFER_INTERVAL`; `draw_offer(relic_pool: Array[RelicData]) -> Array[RelicData]` — returns `[]` if empty, `[pool[0], pool[0]]` if size==1, else `pool.duplicate()` shuffled returning `[shuffled[0], shuffled[1]]`; `pick_relic(relic_id: String)` appends to `active_relic_ids`; `compute_stat_mult(stat: String, relic_pool: Array[RelicData]) -> float` — builds `data_by_id` Dictionary from pool, iterates `active_relic_ids`, multiplies `effect_mult` of all relics whose `effect_stat == stat`, returns result (1.0 if none match) per contracts/interfaces.md
- [X] T006 [US1] Create `autoload/RelicManager.gd` extending `Node` — signals: `relic_offer_ready(options: Array)`, `relic_applied(relic_id: String)`, `relics_cleared()`; field `active_relic_ids: Array[String]` (computed, delegates to `_impl`); private `_impl: RelicManagerImpl = RelicManagerImpl.new()` and `_relic_pool: Array[RelicData] = []`; in `_ready()` connect `RunManager.run_started → _on_run_started()` (lambda discard arg), `RunManager.run_ended → _on_run_ended()` (lambda discard arg), `RunManager.room_cleared → _on_room_cleared(room_id)`; `_on_run_started()`: calls `_impl.reset()`, builds `_relic_pool` via `_build_pool()`, emits `relics_cleared`, prints pool size; `_on_run_ended()`: calls `_impl.reset()`, clears `_relic_pool`, emits `relics_cleared`; `_on_room_cleared(room_id)`: guards `if not RunManager.is_run_active: return`, reads `room_type = (RunManager.current_room as RoomSpawner).room_type_id if RunManager.current_room != null else ""`, calls `_impl.should_offer_for_room(room_type)`, on true calls `_impl.draw_offer(_relic_pool)` and emits `relic_offer_ready`; `pick_relic(relic_id)`: calls `_impl.pick_relic(relic_id)`, appends to `RunManager.player_state.active_modifiers`, emits `relic_applied(relic_id)` with print log; `get_stat_mult(stat) -> float`: delegates to `_impl.compute_stat_mult(stat, _relic_pool)`; `_build_pool()`: calls `ResourceManager.get_relics()`, iterates `raw.get("relics", [])`, calls `RelicData.from_dict()` for each Dictionary entry, returns `Array[RelicData]` per contracts/interfaces.md (depends on T005)
- [X] T007 [P] [US1] Create `scenes/ui/relic_offer/RelicCard.gd` with `class_name RelicCard extends Panel` — signal `relic_selected(relic_id: String)`; exports: `@export var _name_label: Label`, `@export var _desc_label: Label`, `@export var _button: Button`; private `_relic_id: String = ""`; `_ready()`: asserts all exports non-null, connects `_button.pressed → _on_button_pressed`; `setup(relic: RelicData)`: sets `_relic_id = relic.id`, `_name_label.text = relic.name`, `_desc_label.text = relic.description`; `_on_button_pressed()`: emits `relic_selected(_relic_id)` per contracts/interfaces.md
- [X] T008 [P] [US1] Create `scenes/ui/relic_offer/RelicOfferScreen.gd` with `class_name RelicOfferScreen extends Control` — signal `relic_picked(relic_id: String)`; exports: `@export var _card_left: RelicCard`, `@export var _card_right: RelicCard`; `_ready()`: asserts both exports non-null; `setup(options: Array)`: if size >= 1 calls `_card_left.setup(options[0] as RelicData)` and connects `_card_left.relic_selected → func(id) → relic_picked.emit(id)`; if size >= 2 same for `_card_right` per contracts/interfaces.md
- [ ] T009 [US1] [EDITOR] Create `scenes/ui/relic_offer/RelicCard.tscn` in Godot Editor: root node `Panel` (class RelicCard), child `VBoxContainer`, children of VBoxContainer: `Label` (name it `NameLabel`), `Label` (name it `DescLabel`), `Button` (name it `Button`, text="Choose"); attach `RelicCard.gd` to root; assign `_name_label`, `_desc_label`, `_button` exports via Inspector (depends on T007)
- [ ] T010 [US1] [EDITOR] Create `scenes/ui/relic_offer/RelicOfferScreen.tscn` in Godot Editor: root node `Control` (anchor: full rect, name it `RelicOfferScreen`), children: `ColorRect` (name `Background`, anchor full rect, color semi-transparent black, **set mouse_filter to Stop in Inspector**), `CenterContainer` (anchor center), inside CenterContainer: `VBoxContainer`, children of VBox: `Label` (text="Choose a Relic"), `HBoxContainer`, inside HBox: instance of `RelicCard.tscn` (name `CardLeft`) and another instance (name `CardRight`); attach `RelicOfferScreen.gd` to root; assign `_card_left = CardLeft`, `_card_right = CardRight` via Inspector (depends on T008, T009)
- [ ] T011 [US1] [EDITOR] Register RelicManager autoload in Godot Editor: Project → Project Settings → Autoload → add `res://autoload/RelicManager.gd` with name `RelicManager`; position it after RunManager in the autoload list (depends on T006)
- [X] T012 [P] [US1] Modify `scenes/player/components/CombatComponent.gd` — add `var _base_attack_interval: float = 0.0`; in `_ready()` add `_base_attack_interval = attack_interval` after the existing `_base_attack_damage = attack_damage` line; rename existing `_apply_damage_multiplier()` to `_recompute_stats()`; extend its body: `attack_damage = _base_attack_damage * MetaManager.damage_multiplier * RelicManager.get_stat_mult("attack_damage")` and `attack_interval = _base_attack_interval / RelicManager.get_stat_mult("attack_speed")`; change the `run_started` connection lambda to call `_recompute_stats()`; add two new connections: `RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_stats())` and `RelicManager.relics_cleared.connect(func() -> void: _recompute_stats())` per contracts/interfaces.md (depends on T006)
- [X] T013 [P] [US1] Modify `scenes/player/components/StatsComponent.gd` — add `var _base_max_health: float = 0.0`; in `_ready()` add `_base_max_health = max_health` after the existing assert; add new method `_on_relic_applied(_relic_id: String) -> void`: computes `new_max = _base_max_health * RelicManager.get_stat_mult("max_health")`, early-returns if `is_equal_approx(new_max, max_health)`, otherwise computes `ratio = current_health / max_health`, sets `max_health = new_max`, sets `current_health = clampf(new_max * ratio, 1.0, new_max)`, emits `health_changed(current_health, max_health)`; in `_ready()` add: `RelicManager.relic_applied.connect(_on_relic_applied)` and `RelicManager.relics_cleared.connect(func() -> void: _on_relic_applied(""))` per contracts/interfaces.md (depends on T006)
- [X] T014 [US1] Modify `scenes/core/Main.gd` — add preload `const _RELIC_OFFER_SCENE = preload("res://scenes/ui/relic_offer/RelicOfferScreen.tscn")`; add fields `var _relic_offer_layer: CanvasLayer = null` and `var _relic_offer_screen: RelicOfferScreen = null`; in `_ready()` add `RelicManager.relic_offer_ready.connect(_on_relic_offer_ready)`; add handler `_on_relic_offer_ready(options: Array)`: sets `_exploration_hud.visible = false`, creates `_relic_offer_layer = CanvasLayer.new()`, calls `add_child(_relic_offer_layer)`, instantiates `_relic_offer_screen = _RELIC_OFFER_SCENE.instantiate() as RelicOfferScreen`, adds to layer, calls `_relic_offer_screen.setup(options)`, connects `_relic_offer_screen.relic_picked → _on_relic_picked`; add handler `_on_relic_picked(relic_id: String)`: calls `RelicManager.pick_relic(relic_id)`, calls `_relic_offer_layer.queue_free()`, nulls both fields, sets `_exploration_hud.visible = true` per contracts/interfaces.md (depends on T006, T008, T010, T011)

**Checkpoint**: US1 complete — clearing any room shows the offer screen; picking a relic applies its stat effect; joystick re-enabled after pick.

---

## Phase 3: User Story 2 — Correct Offer Frequency (Priority: P2)

**Goal**: Relic offers appear exactly every 2nd standard room cleared, and always after clearing an elite room regardless of the counter. No additional code changes required — frequency logic is fully implemented in `RelicManagerImpl.should_offer_for_room()` (T005) and room type detection in `RelicManager._on_room_cleared()` (T006). This phase validates the behavior.

**Independent Test**: Clear rooms in sequence. Confirm: no offer after room 1 (Output shows counter=1, no `relic_offer_ready` print). Offer after room 2 (counter resets to 0). No offer after room 3. Offer after room 4. Navigate to EliteRoom01 at any point — confirm offer always fires immediately after last enemy kill regardless of counter state. After elite offer, confirm counter continues from where it was (not reset).

- [ ] T015 [US2] Validate offer frequency by running quickstart scenarios 1, 2, 5, 6, 7, and 8 from `specs/021-relic-system/quickstart.md`; confirm each passes; if any scenario fails, diagnose by adding debug prints to `RelicManagerImpl.should_offer_for_room()` to trace `standard_rooms_cleared` and `room_type_id` values

**Checkpoint**: US2 complete — offer appears exactly every 2nd standard clear and always after elite; counter does not reset on elite offer.

---

## Phase 4: User Story 3 — Relics Persist and Stack Through the Run (Priority: P3)

**Goal**: Multiple relics stack multiplicatively on the same stat. All relics clear on run end. New runs start with no active relics. No additional code changes required — stacking is in `RelicManagerImpl.compute_stat_mult()` (T005); clearing is in `RelicManager._on_run_ended()` (T006) + `relics_cleared` signal connections in CombatComponent (T012) and StatsComponent (T013).

**Independent Test**: Pick `sharp_edge` (×1.2 attack_damage) — confirm damage = base × meta × 1.2. Clear 2 more rooms, pick `rage_crystal` (×1.3 attack_damage) — confirm damage = base × meta × 1.2 × 1.3 = base × meta × 1.56. End run. Start new run. Confirm damage = base × meta × 1.0 (no relic mults).

- [ ] T016 [US3] Validate relic stacking and run-reset by running quickstart scenarios 9, 10, 11, and 12 from `specs/021-relic-system/quickstart.md`; confirm each passes; if stacking is incorrect diagnose by printing `RelicManager.get_stat_mult("attack_damage")` after each pick; if reset fails check that `RelicManager.relics_cleared` fires on run end (add debug print to `_on_run_ended()` in autoload/RelicManager.gd)

**Checkpoint**: US3 complete — all user stories independently functional.

---

## Phase 5: Polish & Validation

- [ ] T017 Run all 14 manual validation scenarios from `specs/021-relic-system/quickstart.md` and confirm each passes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately. T001–T004 are all parallel (different files).
- **US1 (Phase 2)**: Requires T001–T004 complete.
  - T005, T007, T008 can start together after Foundational (different files, no interdependencies).
  - T006 requires T005 (`RelicManagerImpl` class_name must be defined).
  - T012 and T013 require T006 (`RelicManager` autoload must exist to connect signals).
  - T009 requires T007 (script must exist before scene can attach it).
  - T010 requires T008 + T009 (script and RelicCard scene must exist).
  - T011 requires T006 (autoload script must exist to register it).
  - T014 requires T006, T008, T010, T011 (RelicManager signals, RelicOfferScreen class and scene, autoload registered).
- **US2 (Phase 3)**: Requires all of US1 complete.
- **US3 (Phase 4)**: Requires all of US1 complete.
- **Polish (Phase 5)**: Requires US1, US2, US3 complete.

### User Story Dependencies

- **US1 (P1)**: Requires Foundational (Phase 1) — no dependencies on US2 or US3.
- **US2 (P2)**: Requires US1 complete (frequency behavior delivered in US1 implementation).
- **US3 (P3)**: Requires US1 complete (stacking and reset delivered in US1 implementation).

### Within US1 Parallel Opportunities

```
Foundational complete → start simultaneously:
  Task A: T005 — RelicManagerImpl.gd (logic)
  Task B: T007 — RelicCard.gd (UI script)
  Task C: T008 — RelicOfferScreen.gd (UI script)

T005 done → T006 — RelicManager autoload

T006 done → start simultaneously:
  Task D: T012 — CombatComponent.gd
  Task E: T013 — StatsComponent.gd

Editor work (sequential within Godot Editor):
  T009 — RelicCard.tscn (after T007)
  T010 — RelicOfferScreen.tscn (after T008 + T009)
  T011 — Register autoload (after T006)

All of T006, T008, T010, T011 done → T014 — Main.gd
```

---

## Implementation Strategy

### MVP (US1 Only)

1. Complete Phase 1 (Foundational — T001–T004 in parallel)
2. Complete Phase 2 (US1 — T005 → T006 → T012/T013 in parallel → T009 → T010 → T011 → T014)
3. **Validate**: Clear a room → offer screen appears → pick relic → stat effect applied

### Full Delivery

1. Phase 1 → Phase 2 (US1) → Phase 3 (US2 validation) → Phase 4 (US3 validation) → Phase 5 (all scenarios)
2. Each phase independently testable before moving on

---

## Notes

- T005 and T006 implement the FULL frequency logic (OFFER_INTERVAL counter + elite detection). US2 validates this rather than adding new code.
- T012 (CombatComponent) and T013 (StatsComponent) connect to BOTH `relic_applied` AND `relics_cleared` — this covers both US1 (stat application on pick) and US3 (stat reset on run end) in one pass.
- T009 and T010 are Godot Editor tasks — they cannot be automated. Must be done by opening the Editor and creating scenes manually.
- T014 (Main.gd) requires T010 (RelicOfferScreen.tscn) to exist so the `preload()` compiles correctly. Do T010 in the Editor before running T014.
- The `Background` ColorRect in RelicOfferScreen.tscn MUST have `mouse_filter = Stop` (not `Ignore` or `Pass`) to block touch input from reaching the joystick while the offer is showing.
- `RelicManager` autoload order in Project Settings matters: it connects to `RunManager.room_cleared`, so it must be loaded after RunManager.
