# Tasks: Hub Room

**Input**: Design documents from `/specs/013-hub-room/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks grouped by user story. US1 and US2 are both P1 MVP. US1 (hub exists at startup) and US2 (button press starts run) require separate Main.gd changes but share the same scene scripts and Editor assets.

**⚠️ Editor note**: T003 and T004 MUST be completed in the **Godot Editor** (scene files cannot be created as raw text). All other tasks are code-editor tasks.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

No project initialization required. Pure GDScript additions and one modified script; no new dependencies.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create GDScript classes needed before Editor scenes can attach them.

**⚠️ CRITICAL**: T003 and T004 (Editor tasks) cannot attach scripts until these exist.

- [x] T001 Create `scenes/hub/TeleportDoor.gd` — `class_name TeleportDoor extends Node2D`, signal `teleport_activated`, `@export var button: Button`, `_ready()` connects `button.pressed` to `_on_button_pressed`, `_on_button_pressed()` checks `not RunManager.is_run_active` then emits `teleport_activated`
- [x] T002 [P] Create `scenes/hub/HubRoom.gd` — `class_name HubRoom extends Node2D`, signal `hub_exited`, `@export var teleport_door: TeleportDoor`, `_ready()` connects `teleport_door.teleport_activated` to `_on_teleport_activated`, `_on_teleport_activated()` emits `hub_exited` then calls `queue_free()`

**Checkpoint**: Both scripts exist and are syntactically valid. Ready for Editor scene creation.

---

## Phase 3: User Story 1 — Game Starts in the Hub (Priority: P1) 🎯 MVP

**Goal**: When the game launches, the player is in the hub room — not in a dungeon. The "Teleport" button is visible.

**Independent Test**: Launch the game. Confirm player is in the hub room (not a dungeon). Confirm `RunManager.is_run_active == false`. Confirm a "Teleport" button is visible. Confirm player can move via joystick.

### Implementation for User Story 1

- [ ] T003 [US1] **[Godot Editor]** Create `scenes/hub/TeleportDoor.tscn` — root `Node2D` named `TeleportDoor`; add child `ColorRect` (visual placeholder, ~120×180 px); add child `Button` (any name, e.g. `TeleportButton`) with `text = "Teleport"`, size/position over the ColorRect; attach script `TeleportDoor.gd`; in the Inspector for the root node, assign the Button child to the `button` export property
- [ ] T004 [US1] **[Godot Editor]** Create `scenes/hub/HubRoom.tscn` — root `Node2D` named `HubRoom`; add child `ColorRect` (1920×1080 background, dark colour); add instance of `TeleportDoor.tscn` as child (any name), position at approximately `(0, -200)`; attach script `HubRoom.gd`; in the Inspector for the root node, assign the TeleportDoor instance to the `teleport_door` export property
- [x] T005 [US1] Modify `scenes/core/Main.gd` — add `const _HUB_ROOM_SCENE = preload("res://scenes/hub/HubRoom.tscn")` at top; add field `var _hub_room: Node = null`; in `_ready()` REMOVE lines 21-22 (`GlobalSignals.gameplay_started.emit()` and `RunManager.start_run("endless")`); ADD in their place: `_hub_room = _HUB_ROOM_SCENE.instantiate()`, `add_child(_hub_room)`, `_hub_room.hub_exited.connect(_on_hub_exited)`

**Checkpoint**: US1 complete. Game starts in hub. HUD hidden. Player moves freely. `is_run_active == false`. DevPanel "Start Run" button still works for dev bypass.

---

## Phase 4: User Story 2 — Pressing the Teleport Button Starts the Run (Priority: P1) 🎯 MVP

**Goal**: Pressing the "Teleport" button starts the run and places the player in the dungeon's starting room. Proximity alone has no effect.

**Independent Test**: From the hub, press the "Teleport" button. Confirm `[RunManager] run started` appears in Output. Confirm player arrives in `StartRoom01`. Confirm HUD is now visible. Confirm hub node is gone from Remote scene tree.

### Implementation for User Story 2

- [x] T006 [US2] Add `_on_hub_exited()` method to `scenes/core/Main.gd`: body is `RunManager.start_run("endless")` then `GlobalSignals.gameplay_started.emit()`

**Checkpoint**: US2 complete. Full flow works: hub → press button → run starts → player in dungeon. Proximity alone has no effect (button press required).

---

## Phase 5: Polish & Validation

- [ ] T007 Run all 13 manual validation scenarios from `specs/013-hub-room/quickstart.md` — pay special attention to Scenario 5 (proximity alone does NOT start run) and Scenario 11 (double-press guard)

---

## Dependencies & Execution Order

### Task Dependencies

| Task | Depends On | Reason |
|---|---|---|
| T001 | — | No dependencies |
| T002 | — | No dependencies (references TeleportDoor class but file can be written independently) |
| T003 | T001 | Need TeleportDoor.gd to attach as script in Editor |
| T004 | T002, T003 | Need HubRoom.gd to attach; need TeleportDoor.tscn to instance |
| T005 | T004 | HubRoom.tscn must exist for `preload()` to succeed |
| T006 | T005 | `_on_hub_exited` must be added after the `connect()` call in T005 |
| T007 | T001–T006 | All implementation complete |

### Parallel Opportunities

- T001 and T002 can run in parallel (different files, no inter-dependencies at write time)
- T003 and T004 are Editor tasks — T003 must complete before T004 (TeleportDoor.tscn needed for instantiation in HubRoom.tscn)
- T005 and T006 both modify Main.gd — run sequentially

---

## Implementation Strategy

### MVP (all 6 code tasks required — US1 and US2 are both P1)

1. T001 + T002 (parallel) → Scripts created
2. T003 → TeleportDoor.tscn created (Editor)
3. T004 → HubRoom.tscn created (Editor)
4. T005 → Main.gd wired (hub loads at startup)
5. T006 → Main.gd run handler added (button press triggers run)
6. T007 → Validate 13 scenarios

### Incremental Checkpoints

- After T004: Open game — hub should appear (start_run still auto-fires until T005)
- After T005: Game starts in hub, no run, HUD hidden — US1 testable
- After T006: Press Teleport button, run starts, player in dungeon — US2 testable

---

## Notes

- T001 and T002 are [P] — write them to separate files simultaneously
- T003 and T004 are Godot Editor tasks — cannot be done via code editors or raw `.tscn` text
- `Button` node in TeleportDoor.tscn can have **any name** — `TeleportDoor.gd` uses `@export var button: Button`; assign it via the Inspector on the root node
- `TeleportDoor` instance in HubRoom.tscn can have **any name** — `HubRoom.gd` uses `@export var teleport_door: TeleportDoor`; assign it via the Inspector on the root node
- T005 REMOVES lines 21-22 from Main._ready() — do not leave both the old and new code present
- DevPanel `start_run_pressed` button (Main.gd line 15) is intentionally kept — dev bypass for testing
