# Tasks: Dodge Skill

**Input**: Design documents from `/specs/070-dodge-skill/`
**Prerequisites**: spec.md ✅, plan.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add dodge config to data layer — required before any script reads it.

- [x] T001 Add `"dodge"` entry to `data/skills.json` with fields `id`, `cooldown: 1.5`, `dash_distance: 300.0`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Low-level additions to existing components that all dodge logic depends on. Each task touches a different file and can be done in parallel.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 [P] Add `var last_direction: Vector2 = Vector2.DOWN` to `scenes/player/components/MovementComponent.gd`; update `_physics_process` to set `last_direction = _joystick.input_vector.normalized()` when input is non-zero
- [x] T003 [P] Add `var is_invulnerable: bool = false` to `scenes/player/components/StatsComponent.gd`; add early-return guard `if is_invulnerable: return` at the top of both `take_damage()` and `take_damage_raw()`

**Checkpoint**: Foundation ready — `MovementComponent` tracks last direction, `StatsComponent` respects invulnerability flag.

---

## Phase 3: User Story 1 — Activate Dodge (Priority: P1) 🎯 MVP

**Goal**: Player taps Dodge button and the character dashes 300 units in last movement direction with invulnerability for the dash duration.

**Independent Test**: In a combat room, tap Dodge — player moves ~300 units in last joystick direction; damage during dash does not land; button greys out afterward.

### Unit Test for DodgeComponent

- [x] T004 [US1] Create `tests/unit/test_dodge_component.gd` covering: `activate()` ignored when `_cooldown_remaining > 0`; `activate()` sets `is_invulnerable = true` on a stub StatsComponent; `_dash_remaining` decrements correctly in `_physics_process`; dash end clears `is_invulnerable`; `cooldown_changed` signal emits with correct values

### Implementation

- [x] T005 [US1] Implement `scenes/player/components/DodgeComponent.gd`: add `class_name DodgeComponent`, exports `_movement: MovementComponent` and `_stats: StatsComponent`; read `cooldown` and `dash_distance` from `ResourceManager.get_skills()` in `_ready()`; expose `signal cooldown_changed(remaining: float, total: float)` and `func activate() -> void`; manage `_is_dashing`, `_dash_remaining: float`, `_dash_direction: Vector2`, `_cooldown_remaining: float`, `_dash_speed: float` state; implement full `_physics_process` logic: advance cooldown, drive parent velocity while dashing, end dash when `_dash_remaining <= 0`

**Checkpoint**: DodgeComponent fully functional. Assign exports in Inspector (Player.tscn editor task) and verify dash + invulnerability work in play mode.

- [ ] T006 [US1] **[EDITOR]** Open `scenes/player/Player.tscn` in Godot Editor; on the `DodgeComponent` child node assign `_movement` → MovementComponent node and `_stats` → StatsComponent node via the Inspector

---

## Phase 4: User Story 2 — Cooldown Enforcement (Priority: P2)

**Goal**: Dodge button becomes visually unavailable after activation and re-enables after 1.5 seconds.

**Independent Test**: Tap Dodge; immediately tap again — second tap produces no movement; after 1.5 s button brightens and next tap dashes normally.

### Implementation

- [x] T007 [US2] Add `@export var _dodge_button: Button` and `signal dodge_button_pressed` to `scenes/ui/hud/ExplorationHUD.gd`; add `setup_dodge(dodge: DodgeComponent) -> void` method that connects `dodge.cooldown_changed` to a `_on_dodge_cooldown_changed(remaining, _total)` handler (modulates `_dodge_button` with `SKILL_COOLDOWN_MODULATE` / `SKILL_READY_MODULATE`); wire `_dodge_button.pressed` to emit `dodge_button_pressed`; show/hide `_dodge_button` in `_on_gameplay_started`, `_on_gameplay_ended`, and `_on_hub_entered` to match skill button visibility
- [x] T008 [US2] Add `@onready var _dodge_component: DodgeComponent` to `scenes/core/Main.gd`; call `_exploration_hud.setup_dodge(_dodge_component)` alongside the existing `setup_skill` call; connect `_exploration_hud.dodge_button_pressed` to `_dodge_component.activate`
- [ ] T009 [US2] **[EDITOR]** Open `scenes/ui/hud/ExplorationHUD.tscn` in Godot Editor; add a `Button` node named `DodgeButton` as a sibling of the existing skill button; assign it to the `_dodge_button` export on ExplorationHUD in the Inspector

**Checkpoint**: Dodge button appears during runs, greys out after use, re-enables after cooldown. Verify rapid double-tap has no effect.

---

## Phase 5: User Story 3 — Data-Driven Configuration (Priority: P3)

**Goal**: Changing `cooldown` or `dash_distance` in `skills.json` changes in-game behaviour without code edits.

**Independent Test**: Change `dash_distance` to `500.0` in `skills.json`, restart, tap Dodge — player visibly travels further. Change back to `300.0`, same result as before.

- [x] T010 [US3] Verify `DodgeComponent._ready()` reads both `cooldown` and `dash_distance` from the dodge skills entry via `ResourceManager.get_skills()` (no hardcoded fallback values other than the assert); add a `push_warning` if the dodge entry is not found and return early to prevent a null-reference crash

**Checkpoint**: Config changes reflected at next game start with no code changes.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T011 [P] Run existing GUT unit test suite (`tests/unit/`) and confirm no regressions from T002/T003 changes to `MovementComponent` and `StatsComponent`
- [ ] T012 Validate in play mode: dash stops at walls (Jolt collision halts velocity naturally); invulnerability ends correctly after dash regardless of wall collision


---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** (T001): No dependencies — start immediately
- **Phase 2** (T002, T003): Depends on Phase 1 — BLOCKS all user story phases
- **Phase 3** (T004–T006): Depends on Phase 2
- **Phase 4** (T007–T009): Depends on Phase 3 (DodgeComponent must exist for `setup_dodge`)
- **Phase 5** (T010): Depends on Phase 3
- **Phase 6** (T011–T012): Depends on Phases 3–5

### Parallel Opportunities

- T002 and T003 can run in parallel (different files)
- T004 (test) and T005 (implementation) are written in order: write test first, verify it fails, then implement
- T007 and T008 can run in parallel (different files); T009 (editor) after T007
- T010 can run in parallel with T007–T009

---

## Parallel Example: Phase 2

```
T002 — MovementComponent.gd   (last_direction cache)
T003 — StatsComponent.gd      (is_invulnerable flag)
← both touch different files, no shared state
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 minimum viable)

1. Complete Phase 1: Add JSON entry
2. Complete Phase 2: Foundation changes (parallel)
3. Complete Phase 3: DodgeComponent + editor wiring
4. Complete Phase 4: HUD button + Main.gd wiring + editor task
5. **STOP and VALIDATE**: dash works, cooldown enforced, button visual feedback correct

### Incremental Delivery

1. Phase 1 + 2 → data and component foundation ready
2. Phase 3 → dash works in code; wire in editor to test
3. Phase 4 → HUD button live; full player-facing feature complete
4. Phase 5 → config validation (quick, confirms data-driven requirement)
5. Phase 6 → regression safety net

---

## Notes

- Editor tasks (T006, T009) must be done in the Godot Editor — they cannot be scripted
- DodgeComponent reads skills array by iterating and matching `id == "dodge"` (same pattern as SkillComponent reads `"magic_missile"`)
- `_dash_speed` is computed at `_ready()` as `dash_distance / 0.1` — not a JSON field
- Invulnerability covers both damage paths (`take_damage` and `take_damage_raw`) to block burn DoT ticks during dash
