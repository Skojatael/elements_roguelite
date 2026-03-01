# Tasks: Run End Screen

**Input**: Design documents from `/specs/015-run-end-screen/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks grouped by user story. US1 (view run summary) and US2 (return to hub) are both P1 MVP. US1 has more foundational prerequisites; US2 is a single task that builds directly on US1.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

No project initialization required. No new dependencies. The `scenes/ui/run_end/` directory is created by the Godot Editor when `ResultsScreen.tscn` is first saved there.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: `RunSummary` data class and RunManager session additions that both user stories depend on.

**⚠️ CRITICAL**: T003 cannot proceed until T001 and T002 exist. T008 cannot proceed until T003 exists.

- [x] T001 [P] Create `scripts/data_models/RunSummary.gd` — `class_name RunSummary extends RefCounted`; declare `var essence_cashed_out: int`, `var enemies_slain: int`, `var rooms_cleared: int`, `var end_reason: RunManager.EndReason`; add `static func create(essence: int, enemies: int, rooms: int, reason: RunManager.EndReason) -> RunSummary` that sets all fields and returns the instance
- [x] T002 [P] Modify `scripts/managers/RunManager.gd` — add session field `var enemies_slain: int = 0` alongside other session fields; add `enemies_slain = 0` to the reset block in `start_run()`; in `_on_enemy_defeated()` add `enemies_slain += 1` as the first line of the method body
- [x] T003 Modify `scripts/managers/RunManager.gd` — add field `var run_summary: RunSummary = null` below the session fields block; in `end_run()`, after the `cashed_out` variable is computed and before `run_ended.emit(reason)`, add `run_summary = RunSummary.create(cashed_out, enemies_slain, cleared_rooms.size(), reason)`

**Checkpoint**: RunSummary can be instantiated. RunManager tracks enemies_slain per run and creates a RunSummary snapshot at end_run(). Ready for US1 implementation.

---

## Phase 3: User Story 1 — View Run Summary on Run End (Priority: P1) 🎯 MVP

**Goal**: When a run ends, the dungeon is freed, ExplorationHUD hides, and a results screen appears showing essence cashed out, enemies slain, and rooms cleared.

**Independent Test**: Start a run. Kill some enemies (note `[RunManager] currency +N` output). End the run via DevPanel. Confirm: dungeon room is gone, ExplorationHUD hidden, results screen visible with correct stat values matching the output log.

- [ ] T004 [US1] ⚠️ MANUAL (Godot Editor) — Create `scenes/ui/run_end/ResultsScreen.tscn`: root node is a `CanvasLayer`; add three `Label` children named `EssenceLabel`, `EnemiesLabel`, `RoomsLabel`; add one `Button` child named `ReturnButton` with text `"Return"`; save the scene to `res://scenes/ui/run_end/ResultsScreen.tscn`
- [x] T005 [US1] Create `scenes/ui/run_end/ResultsScreen.gd` and attach to `ResultsScreen.tscn` via the Godot Editor — declare `signal return_pressed`; declare `@export var _essence_label: Label`, `@export var _enemies_label: Label`, `@export var _rooms_label: Label`, `@export var _return_button: Button`; assign each export to its corresponding node via the Inspector; add `var _return_activated: bool = false`; add `func _ready() -> void` that connects `_return_button.pressed.connect(_on_return_pressed)`; add `func setup(summary: RunSummary) -> void` that sets `_essence_label.text = "Essence Found: {n}".format({"n": summary.essence_cashed_out})`, `_enemies_label.text = "Enemies Slain: {n}".format({"n": summary.enemies_slain})`, `_rooms_label.text = "Rooms Cleared: {n}".format({"n": summary.rooms_cleared})`; add `func _on_return_pressed() -> void` that guards with `if _return_activated: return`, sets `_return_activated = true`, emits `return_pressed`
- [x] T006 [P] [US1] Modify `scripts/dungeon/RoomLoader.gd` — in `_ready()` add `RunManager.run_ended.connect(_on_run_ended)`; add `func _on_run_ended(_reason: RunManager.EndReason) -> void` that checks `if _current_room_node != null`, calls `_current_room_node.queue_free()`, sets `_current_room_node = null` and `RunManager.current_room = null`
- [x] T007 [P] [US1] Modify `scenes/ui/hud/ExplorationHUD.gd` — in `_ready()` add `RunManager.run_ended.connect(_on_gameplay_ended)` after the existing `RunManager.run_started.connect(_on_gameplay_started)` line
- [x] T008 [US1] Modify `scenes/core/Main.gd` — add `const _RESULTS_SCREEN_SCENE := preload("res://scenes/ui/run_end/ResultsScreen.tscn")` alongside existing preloads; add `var _results_screen: Node = null`; in `_ready()` add `RunManager.run_ended.connect(_on_run_ended)`; add `func _on_run_ended(_reason: RunManager.EndReason) -> void` that instantiates `_RESULTS_SCREEN_SCENE`, assigns it to `_results_screen`, calls `(_results_screen as ResultsScreen).setup(RunManager.run_summary)`, connects `(_results_screen as ResultsScreen).return_pressed.connect(_on_results_return)`, then calls `add_child(_results_screen)`

**Checkpoint**: US1 complete. Kill enemies → end run → dungeon gone → ExplorationHUD hidden → results screen shows correct essence, enemy, and room counts.

---

## Phase 4: User Story 2 — Return to Hub from Results Screen (Priority: P1)

**Goal**: Tapping "Return" on the results screen frees it and shows the hub, ready for a new run.

**Independent Test**: On the results screen, tap "Return". Confirm results screen disappears, hub room (TeleportDoor visible) is shown, no run is active. Then activate TeleportDoor and confirm a new run starts cleanly.

- [x] T009 [US2] Modify `scenes/core/Main.gd` — add `func _on_results_return() -> void` that calls `_results_screen.queue_free()`, sets `_results_screen = null`, then instantiates `_HUB_ROOM_SCENE`, assigns to `_hub_room`, calls `add_child(_hub_room)`, and connects `_hub_room.hub_exited.connect(_on_hub_exited)`

**Checkpoint**: US2 complete. Full loop works: kill enemies → end run → results screen → tap Return → hub → start new run → results screen shows fresh data.

---

## Phase 5: Polish & Validation

- [ ] T010 Run all 12 manual validation scenarios from `specs/015-run-end-screen/quickstart.md` — pay special attention to Scenario 7 (zero stats), Scenario 10 (double-tap guard), and Scenario 12 (no null-reference errors from freed dungeon nodes)

---

## Dependencies & Execution Order

### Task Dependencies

| Task | Depends On | Reason |
|---|---|---|
| T001 | — | No dependencies |
| T002 | — | No dependencies |
| T003 | T001, T002 | Needs RunSummary type and enemies_slain field |
| T004 | — | MANUAL editor task; no code dependencies |
| T005 | T001, T004 | Needs RunSummary type for setup() parameter; needs scene to attach to |
| T006 | — | Only connects existing RunManager.run_ended signal |
| T007 | — | Only connects existing RunManager.run_ended signal |
| T008 | T003, T005 | Needs run_summary on RunManager; needs ResultsScreen type and scene |
| T009 | T008 | Needs _results_screen var and _on_run_ended to exist in Main |
| T010 | T001–T009 | All implementation complete |

### Parallel Opportunities

- T001 and T002 are independent — run in parallel
- T004, T006, T007 are all independent — run in parallel alongside T001/T002
- T005 depends on T001 (RunSummary type) and T004 (scene exists); can proceed once both done
- T008 must wait for T003, T004, T005
- T009 must wait for T008

---

## Implementation Strategy

### MVP (all 9 code tasks — US1 and US2 are both P1)

1. T001 + T002 (parallel) → RunSummary and enemies_slain ready
2. T003 → RunManager creates snapshot at end_run()
3. T004 (MANUAL) + T006 + T007 (parallel) → Scene exists, RoomLoader and HUD wired
4. T005 → ResultsScreen script (after T001 + T004)
5. T008 → Main wires run_ended, shows ResultsScreen (after T003 + T005)
6. T009 → Main handles return to hub (after T008)
7. T010 → Validate 12 scenarios

### Incremental Checkpoints

- After T003: RunManager emits run_ended with full snapshot — data layer ready
- After T008: End a run → results screen appears with correct data — US1 testable independently
- After T009: Tap Return → hub shown — US2 testable; full loop complete

---

## Notes

- T004 is a MANUAL Godot Editor task — must be done before T005 can be attached. Flag clearly when implementing.
- T005 populates labels using `String.format()` with named keys per constitution (no `%` specifiers).
- T006 and T007 touch different files and have no inter-dependencies — run in parallel.
- T008 and T009 both modify `Main.gd` — do them sequentially in one pass to avoid conflicts.
- The `_return_activated` guard in ResultsScreen (T005) prevents double-tap hub duplication (Scenario 10).
- ResultsScreen must never call into RunManager or dungeon nodes after `setup()` — all data comes from the RunSummary snapshot passed in.
