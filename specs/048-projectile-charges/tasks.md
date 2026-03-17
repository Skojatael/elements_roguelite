# Tasks: Magic Missile Charges

**Input**: Design documents from `/specs/048-projectile-charges/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Data Schema)

**Purpose**: Update the data layer before any code is written (Constitution II — data-first).

- [x] T001 Update `data/skills.json` — rename `"id": "homing_projectile"` → `"id": "magic_missile"` and add `"max_charges": 3` to the same entry

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Charge state fields, signal declaration, and reset logic in `SkillComponent` — shared by all three user stories. Must complete before any user story phase begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Extend `scenes/player/components/SkillComponent.gd` — change `SKILL_ID` const to `"magic_missile"`; add `signal charges_changed(current: int, maximum: int)`; add `var _max_charges: int = 0` and `var _current_charges: int = 0`; in `_load_skill_data()` read and assert `max_charges` from the skill entry and assign `_max_charges`; add `func _reset_charges() -> void` that sets `_current_charges = _max_charges` and emits `charges_changed`; in `_ready()` connect `RunManager.run_started` to call `_reset_charges()` (lambda pattern: `func(_m: String) -> void: _reset_charges()`)

**Checkpoint**: Foundation ready — charge state exists and resets on run start. User story implementation can now begin.

---

## Phase 3: User Story 1 — Spend Charge on Skill Use (Priority: P1) 🎯 MVP

**Goal**: Pressing the skill button costs 1 charge; blocked at 0 charges; charge count decrements and `charges_changed` emits on every successful activation.

**Independent Test**: Start a run. Press the skill button 3 times — first 3 fire a missile; 4th press does nothing and charge count stays at 0.

### Implementation for User Story 1

- [x] T003 [US1] Add charge spend guard and decrement to `scenes/player/components/SkillComponent.gd` — in `_on_skill_button_pressed()` insert `if _current_charges <= 0: return` as the **first** guard (before the `is_run_active` guard); after the projectile is added to the scene tree, add `_current_charges -= 1` then `charges_changed.emit(_current_charges, _max_charges)`

**Checkpoint**: User Story 1 is fully functional. Start a run, fire 3 missiles, confirm 4th is blocked.

---

## Phase 4: User Story 2 — Restore Charge via Melee Attack (Priority: P2)

**Goal**: Each successful melee hit on an enemy restores 1 charge (capped at max). Misses and hits when already full do nothing.

**Independent Test**: Deplete charges to 0. Walk into an enemy so melee auto-attacks trigger. Confirm charge count increases by 1 on each hit, stops at 3.

### Implementation for User Story 2

- [x] T004 [US2] Add `signal melee_hit_landed` to `scenes/player/components/CombatComponent.gd` — declare the signal at the top of the file; in `_physics_process()` emit `melee_hit_landed.emit()` immediately after the `target.take_damage(dmg)` line

- [x] T005 [US2] Add restore logic to `scenes/player/components/SkillComponent.gd` — add `func _on_melee_hit_landed() -> void` that returns early if `_current_charges >= _max_charges`, otherwise increments `_current_charges` by 1 and emits `charges_changed`; in `_ready()` connect `_combat_component.melee_hit_landed` to `_on_melee_hit_landed` (direct connection, no lambda needed — signatures match)

**Checkpoint**: User Stories 1 and 2 both work. Deplete charges, land melee hits, confirm restore loop.

---

## Phase 5: User Story 3 — HUD Charge Display (Priority: P3)

**Goal**: The ExplorationHUD shows the current and maximum charge count, updating in real time on every change.

**Independent Test**: During a run, fire missiles and land melee hits — confirm the HUD label tracks the charge count exactly, including the depleted (`0/3`) and full (`3/3`) states.

### Implementation for User Story 3

- [x] T006 [US3] Add charge display API to `scenes/ui/hud/ExplorationHUD.gd` — add `@export var _charge_label: Label`; add `func setup_skill(skill: SkillComponent) -> void` that connects `skill.charges_changed` to `_on_charges_changed` and calls `_on_charges_changed(skill._current_charges, skill._max_charges)` immediately to set initial text; add `func _on_charges_changed(current: int, maximum: int) -> void` that sets `_charge_label.text = "{c}/{m}".format({"c": current, "m": maximum})`

- [ ] T007 [US3] EDITOR TASK — Open `scenes/ui/hud/ExplorationHUD.tscn` in the Godot Editor; add a plain `Control` node positioned below the HP bar; assign it to the `_charge_pips_container` export on the `ExplorationHUD` node via the Inspector (individual ColorRect pips are spawned and manually positioned by `_build_charge_pips` — no children needed in the editor)

- [x] T008 [US3] Wire skill component to HUD in `scenes/core/Main.gd` — find where `_exploration_hud.setup_hp_bar(...)` is called; immediately after it add `_exploration_hud.setup_skill(_player.get_node("SkillComponent") as SkillComponent)` (verify exact node name in Player.tscn)

**Checkpoint**: All three user stories are functional. HUD displays live charge count throughout a run.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T009 Update `repo_map.md` — in `SkillComponent` entry: update `SKILL_ID` value to `"magic_missile"`, add `signals: charges_changed(current: int, maximum: int)`, add `_on_melee_hit_landed()` method; in `CombatComponent` entry: add `signals: melee_hit_landed`; in `ExplorationHUD` entry: add `_charge_label: Label` export and `setup_skill(skill: SkillComponent)` method; in `data/skills.json` row: note `max_charges` field

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on T001 (skills.json must use `magic_missile` id before SkillComponent asserts on it)
- **User Stories (Phase 3–5)**: All depend on Phase 2 (T002)
  - US1 (Phase 3): no dependency on US2 or US3
  - US2 (Phase 4): T005 depends on T004; both depend only on Phase 2
  - US3 (Phase 5): T007 depends on T006; T008 depends on T006; T007 and T008 are parallel after T006
- **Polish (Phase 6)**: After all user stories complete

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 only — no dependency on US2 or US3
- **US2 (P2)**: Depends on Phase 2 only — no dependency on US1 or US3
- **US3 (P3)**: Depends on Phase 2 only — US1/US2 add no blocker, but the feature is only meaningful once charges can move

### Within Each User Story

- US2: T004 before T005 (signal must exist before connection)
- US3: T006 before T007 (export var must exist before Inspector assignment); T006 before T008 (method must exist before call)

### Parallel Opportunities

- T004 and T006 touch different files — can run in parallel after Phase 2
- T007 and T008 can run in parallel after T006

---

## Parallel Example: User Stories 2 and 3 (after US1 done)

```text
# T004 and T006 can run in parallel (different files):
Task T004: Add melee_hit_landed signal to CombatComponent.gd
Task T006: Add setup_skill() and _charge_label to ExplorationHUD.gd

# After T004 completes:
Task T005: Connect melee_hit_landed in SkillComponent.gd

# After T006 completes (T007 and T008 in parallel):
Task T007: EDITOR — add Label to ExplorationHUD.tscn
Task T008: Call setup_skill() in Main.gd
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: T001 (skills.json)
2. Complete Phase 2: T002 (charge state in SkillComponent)
3. Complete Phase 3: T003 (spend guard)
4. **STOP and VALIDATE**: Fire 3 missiles, confirm 4th is blocked
5. Proceed to US2 and US3

### Incremental Delivery

1. T001 → T002 → T003: Core charge gating works
2. T004 → T005: Melee restore loop works
3. T006 → T007 → T008: HUD display live
4. T009: Repo map updated

---

## Notes

- `[P]` tasks operate on different files with no incomplete dependencies
- `[Story]` label maps each task to its user story for traceability
- T007 is an Editor-only task — no GDScript changes, Inspector assignment only
- The `setup_skill` / `setup_hp_bar` pattern in Main.gd follows the established component wiring convention; verify the SkillComponent node name in Player.tscn before writing T008
- No unit tests are generated: SkillComponent is a scene component (not an `*Impl.gd`), no `static func` methods, no non-trivial data model computation — none of the mandatory test triggers apply
