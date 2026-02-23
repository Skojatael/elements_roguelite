# Tasks: Dev Panel

**Input**: Design documents from `specs/005-dev-panel/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story. Because DevPanel.gd and Main.gd each span all three user stories simultaneously (all four signals are declared and connected in a single pass per file), US1/US2/US3 are delivered together in Phase 2. Phase 1 is a hard prerequisite Editor task that must complete before any scripting begins.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths are included in all descriptions

---

## Phase 1: Setup (Foundational — Editor Task)

**Purpose**: The scene must exist before any script can reference or attach to it. This task has no scripting — it is pure Godot Editor work.

**⚠️ CRITICAL**: T002 and T003 cannot begin until T001 is complete. `Main.gd` preloads `DevPanel.tscn`; a missing scene causes a load error.

- [ ] T001 In the Godot Editor create folder `scenes/ui/dev/`, then build `DevPanel.tscn`: root node `CanvasLayer` named `DevPanel` (layer=128); add child `PanelContainer` anchored to top-left with offset 10px from each edge; inside it add `VBoxContainer`; inside that add four `Button` nodes named `StartRun`, `EndRun`, `CashOut`, `StartBoss` with matching text labels; set each button's Custom Minimum Size to 200×60 in the Inspector — `scenes/ui/dev/DevPanel.tscn`

**Checkpoint**: Scene opens in the Editor with no errors. All four buttons are visible in the 2D viewport at the top-left corner.

---

## Phase 2: User Story 1 — DEV_MODE Gating (Priority: P1) 🎯 MVP

**Goal**: Panel appears when `DEV_MODE = true`; zero nodes exist when `false`. Because DevPanel.gd declares all four signals and Main.gd connects all four, this phase also fully delivers US2 (Start Run / End Run) and US3 (Cash Out / Start Boss stubs) in the same implementation pass.

**Independent Test**: Set `DEV_MODE = true`, run the game — all four buttons are visible. Set `DEV_MODE = false`, run again — no panel, no errors.

### Implementation

- [x] T002 [P] [US1] Create `scenes/ui/dev/DevPanel.gd`: `class_name DevPanel extends CanvasLayer`; declare signals `start_run_pressed`, `end_run_pressed`, `cash_out_pressed`, `start_boss_pressed`; declare `@onready` vars `_btn_start_run`, `_btn_end_run`, `_btn_cash_out`, `_btn_start_boss` using paths `$PanelContainer/VBoxContainer/StartRun` etc.; in `_ready()` connect each button's `pressed` signal to emit its corresponding DevPanel signal — `scenes/ui/dev/DevPanel.gd`
- [x] T003 [P] [US1] Update `scenes/core/Main.gd`: add `const DEV_MODE: bool = true` at file top; add `const _DEV_PANEL_SCENE = preload("res://scenes/ui/dev/DevPanel.tscn")`; in `_ready()` add DEV_MODE guard: instantiate panel, call `add_child(panel)`, connect `start_run_pressed` → `func(): RunManager.start_run("endless")`, `end_run_pressed` → `func(): RunManager.end_run()`, `cash_out_pressed` → `func(): print("[DevPanel] cash_out pressed — stub")`, `start_boss_pressed` → `func(): print("[DevPanel] start_boss pressed — stub")`; fix existing bug `RunManager.end_run("dead")` → `RunManager.end_run()` — `scenes/core/Main.gd`

**Checkpoint**: US1, US2, and US3 are all complete. `DEV_MODE = true`: panel visible with 4 buttons, Start Run and End Run functional, Cash Out and Start Boss log stubs. `DEV_MODE = false`: no panel, no errors.

---

## Phase 3: Polish & Validation

**Purpose**: Confirm all quickstart scenarios pass and the implementation matches the specification.

- [ ] T004 Run all six quickstart.md validation scenarios (1–6): panel visible/hidden by DEV_MODE; Start Run creates a run; End Run ends active run and no-ops when inactive; Cash Out logs stub; Start Boss logs stub — `specs/005-dev-panel/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

```text
T001 (Editor: DevPanel.tscn)
        │
   ┌────┴────┐
   ▼         ▼
T002 [P]   T003 [P]
(DevPanel.gd) (Main.gd)
   └────┬────┘
        ▼
      T004 (validate)
```

- **T001**: No dependencies — start here.
- **T002 ‖ T003**: Both depend on T001. Different files — run in parallel.
- **T004**: Depends on T002 + T003 both complete.

### Parallel Opportunities

- T002 and T003 can run simultaneously once T001 is done (different files, zero shared state).

---

## Implementation Strategy

### MVP (All user stories delivered together)

Because all four signals live in the same two files, the feature is all-or-nothing at the code level:

1. Complete T001 in the Godot Editor (scene prerequisite)
2. Complete T002 and T003 in parallel (scripts + Main.gd wiring)
3. Complete T004 (validation)

**Total tasks**: 4
**Parallel opportunities**: T002 ‖ T003
**Editor-only tasks**: T001

---

## Notes

- T001 is an Editor task — it cannot be scripted and must be done by hand before any other work.
- The `_DEV_PANEL_SCENE` preload in `Main.gd` (T003) will produce a load error at game start if `DevPanel.tscn` does not exist — complete T001 first.
- The bug fix in T003 (`end_run("dead")` → `end_run()`) is required regardless of DEV_MODE — it would crash on player death.
- `Main.gd` already auto-starts a run in `_ready()` (`RunManager.start_run("endless")`). The Start Run button will restart it — this is correct per spec ("run resets").
- [P] tasks = different files, no shared-state dependencies.
- Mark tasks `[x]` after completion.
