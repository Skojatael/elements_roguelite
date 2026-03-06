# Tasks: Boss Victory Outcome

**Input**: Design documents from `specs/030-boss-victory-outcome/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: Foundational (Shared Prerequisites)

**Purpose**: Changes that both US1 and US2 depend on. MUST complete before user story phases.

- [X] T001 [P] Fix `_on_room_cleared_for_boss()` in scenes/ui/hud/ExplorationHUD.gd: add `const BOSS_ROOM_ID: String = "boss_room"`, rename the `_room_id` parameter to `room_id`, and add `if room_id == BOSS_ROOM_ID: return` as the first guard clause (prevents boss button reappearing after boss death — see contracts/interfaces.md)
- [X] T002 [P] Add new declarations to scenes/core/Main.gd: `const _BOSS_VICTORY_OVERLAY_SCENE = preload("res://scenes/ui/boss_victory/BossVictoryOverlay.tscn")`, `var _boss_room_spawner: RoomSpawner = null`, `var _boss_victory_layer: CanvasLayer = null`, `var _boss_victory_overlay: BossVictoryOverlay = null`

**Checkpoint**: ExplorationHUD no longer re-shows boss button after boss room clears. Main.gd compiles with new fields.

---

## Phase 2: User Story 1 — Boss Room Has No Doors (Priority: P1) 🎯 MVP

**Goal**: When the boss room loads, all inherited Door nodes are disabled (invisible, non-monitoring). Player hits walls with no door interaction.

**Independent Test**: Teleport to boss room → walk to all four walls → no door visual, no room transition, no `door_activated` signal fires.

- [X] T003 [US1] Extend `_on_boss_teleport_pressed()` in scenes/core/Main.gd: after `spawner.difficulty_mult = boss_mult`, add the Door-disabling loop (`for child in spawner.get_parent().get_children(): if child is Door: child.visible = false; child.monitoring = false`), then store `_boss_room_spawner = spawner` and connect `spawner.room_cleared.connect(_on_boss_room_cleared)` (depends T002 — uses `_boss_room_spawner`)

**Checkpoint**: Entering the boss room shows four solid walls. Player cannot accidentally leave via a door zone.

---

## Phase 3: User Story 2 — Victory Overlay After Boss Defeat (Priority: P2)

**Goal**: When the boss dies, an overlay with "Cash Out" and "Continue Further" appears. Cash Out ends the run identically to the DevPanel cash-out. Continue Further stubs with visible feedback.

**Independent Test**: Kill boss → overlay appears with both buttons → press Cash Out → Results Screen shows with correct essence → press Continue Further → button text changes to "Coming Soon..." and disables.

- [X] T004 [P] [US2] Create scenes/ui/boss_victory/BossVictoryOverlay.gd: `class_name BossVictoryOverlay extends Control`, signals `cash_out_pressed` and `continue_pressed`, `@export var _cash_out_button: Button` and `@export var _continue_button: Button`, `_ready()` connecting both button `pressed` signals, `_on_cash_out_pressed()` (disable button, emit signal), `_on_continue_pressed()` (disable button, set text "Coming Soon...", emit signal) — see contracts/interfaces.md for full code
- [X] T005 [US2] Add three new methods to scenes/core/Main.gd: `_on_boss_room_cleared(_room_id: String)` (nulls `_boss_room_spawner`, hides ExplorationHUD, creates `_boss_victory_layer` CanvasLayer, instantiates and adds overlay, connects both signals), `_on_boss_cash_out_pressed()` (`RunManager.end_run(RunManager.EndReason.CASH_OUT)`), `_on_boss_continue_pressed()` (print stub) — depends T002, T004
- [X] T006 [US2] Extend `_on_run_ended()` and `_on_run_started()` in scenes/core/Main.gd: prepend `if _boss_victory_layer != null: _boss_victory_layer.queue_free(); _boss_victory_layer = null; _boss_victory_overlay = null` to both methods — depends T005
- [ ] T007 [US2] In Godot Editor: create `scenes/ui/boss_victory/BossVictoryOverlay.tscn` with a `Control` root node (attach `BossVictoryOverlay.gd`), add `Button` child named `CashOutButton` with text `"Cash Out"` (assign to `_cash_out_button` export in Inspector), add `Button` child named `ContinueButton` with text `"Continue Further"` (assign to `_continue_button` export in Inspector) — depends T004

**Checkpoint**: Boss dies → overlay appears → Cash Out → Results Screen shows → Continue Further → button text "Coming Soon..." and disabled.

---

## Phase 4: Polish

- [ ] T008 Run all 7 quickstart scenarios from specs/030-boss-victory-outcome/quickstart.md

---

## Dependencies & Execution Order

- **T001, T002**: No cross-dependencies — different files; run in parallel
- **T003**: Depends T002 (uses `_boss_room_spawner` declared there); same file as T002, so run after T002
- **T004**: No dependencies — new file; can run in parallel with T001, T002, T003
- **T005**: Depends T002 (vars declared) and T004 (BossVictoryOverlay class needed for cast); run after both
- **T006**: Depends T005 (same file, extends existing methods); run after T005
- **T007**: Depends T004 (script must exist to attach in editor); run after T004
- **T008**: Depends all prior tasks

### Parallel Opportunities

```
Phase 1 (run together):
  T001  ExplorationHUD fix
  T002  Main.gd new declarations
  T004  BossVictoryOverlay.gd (can also start here — different file)

Phase 2 (after T002):
  T003  Main.gd — _on_boss_teleport_pressed() extension

Phase 3 (after T002 + T004):
  T005  Main.gd new methods
  T007  Editor — BossVictoryOverlay.tscn (after T004)

  Then T006 (after T005, same file)

Phase 4:
  T008  Manual validation (after all)
```

---

## Implementation Strategy

### MVP (US1 only — no doors)
1. Complete T001 + T002 (foundational)
2. Complete T003 (disable doors, wire room_cleared)
3. Validate: enter boss room, walk all walls, no door activation

### Full Feature
4. Complete T004 + T005 + T006 (overlay logic)
5. Complete T007 (editor scene)
6. Validate via all 7 quickstart scenarios (T008)

### Notes
- T001 and T003 can be coded before opening the Godot Editor; T007 requires the Editor
- T004 (BossVictoryOverlay.gd) can be written and reviewed before T007 (editor scene); they are a matched pair — don't test T005/T006 until T007 is also complete
- The ExplorationHUD fix (T001) is a bug that would cause the boss button to reappear even without this feature; it should land regardless of feature completion status
