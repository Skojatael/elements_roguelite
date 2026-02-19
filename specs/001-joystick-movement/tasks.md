---
description: "Task list for Player Movement Joystick Controls"
---

# Tasks: Player Movement Joystick Controls

**Input**: Design documents from `specs/001-joystick-movement/`
**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅

**Tests**: Not requested — no test tasks generated.

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths are included in every description

## Path Conventions

Godot project — all paths are `res://`-relative from repository root:
- Scenes: `scenes/ui/hud/`, `scenes/player/`, `scenes/core/`
- Scripts: co-located with their scenes (Principle V)

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Scaffold scene hierarchies in the Godot Editor before any
scripting begins. These tasks produce `.tscn` changes, not `.gd` changes.

- [ ] T001 In Godot Editor, open `scenes/ui/hud/Joystick.tscn` and build the node hierarchy: add `Base` (TextureRect) and `Knob` (TextureRect) as children of the root Control node; set the Control's anchor preset to Bottom-Left corner with a 160×160 px rect; centre `Base` and `Knob` within the rect. File: `scenes/ui/hud/Joystick.tscn`
- [ ] T002 In Godot Editor, open `scenes/ui/hud/ExplorationHUD.tscn` and drag-instance `Joystick.tscn` as a child of the CanvasLayer root. File: `scenes/ui/hud/ExplorationHUD.tscn`
- [ ] T003 [P] In Godot Editor, open `scenes/player/Player.tscn`, change the root node type from Node2D to CharacterBody2D, then add a child node of type Node named `MovementComponent`. File: `scenes/player/Player.tscn`
- [ ] T004 In Godot Editor, open `scenes/core/Main.tscn` and add `scenes/player/Player.tscn` and `scenes/ui/hud/ExplorationHUD.tscn` as instanced children of the Main Node2D. Create `scenes/core/Main.gd`, set `extends Node2D`, and attach it to the Main node. Files: `scenes/core/Main.tscn`, `scenes/core/Main.gd`

**Checkpoint**: All scene hierarchies exist; Editor shows no errors on scene load.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement the class skeletons and wiring that every user story
depends on. No story implementation can begin until this phase is complete.

**⚠️ CRITICAL**: User story work cannot begin until all Phase 2 tasks are done.

- [x] T005 [P] Implement `scenes/ui/hud/Joystick.gd`: declare `class_name JoystickControl extends Control`; add `@export var max_radius: float = 80.0` and `@export var dead_zone_percentage: float = 0.1`; declare `var input_vector: Vector2 = Vector2.ZERO`; add `@onready var _base: TextureRect = $Base` and `@onready var _knob: TextureRect = $Knob`; implement `_ready()` with assertions (`assert(max_radius > 0)`, `assert(dead_zone_percentage >= 0.0 and dead_zone_percentage <= 0.5)`); set `mouse_filter = Control.MOUSE_FILTER_STOP`. Attach the script to the Joystick node in the Editor. File: `scenes/ui/hud/Joystick.gd`
- [x] T006 [P] Implement `scenes/player/components/MovementComponent.gd`: declare `class_name MovementComponent extends Node`; add `@export var move_speed: float = 200.0`; declare `var _joystick: Node = null`; implement `func set_joystick(node: Node) -> void` that sets `_joystick = node`; implement `_ready()` with `assert(move_speed > 0)`. Attach the script to the MovementComponent node in Player.tscn via the Editor. File: `scenes/player/components/MovementComponent.gd`
- [x] T007 Implement `scenes/core/Main.gd` `_ready()`: declare `@onready var _joystick: JoystickControl = $ExplorationHUD/Joystick` and `@onready var _movement: MovementComponent = $Player/MovementComponent`; in `_ready()` call `_movement.set_joystick(_joystick)`. File: `scenes/core/Main.gd`

**Checkpoint**: Foundation ready — project launches without script errors. No movement yet.

---

## Phase 3: User Story 1 — Navigate the Dungeon (Priority: P1) 🎯 MVP

**Goal**: Player can touch and drag the joystick to move the character in any
direction; releasing the finger stops the character.

**Independent Test**: Launch the game; press and drag the joystick toward any
wall of the room. Character must move continuously in that direction and stop
within one frame of releasing.

### Implementation for User Story 1

- [x] T008 [US1] In `Joystick.gd`, implement `_gui_input(event: InputEvent) -> void`: handle `InputEventScreenTouch` — if `event.pressed` and `_touch_index == -1`, record `_touch_index = event.index`; if `not event.pressed` and `event.index == _touch_index`, reset `_touch_index = -1` and `input_vector = Vector2.ZERO`; call `accept_event()` in both branches. Declare `var _touch_index: int = -1` at class level. File: `scenes/ui/hud/Joystick.gd`
- [x] T009 [US1] In `Joystick.gd _gui_input()`, add an `InputEventScreenDrag` branch: only process if `event.index == _touch_index`; compute `var offset: Vector2 = event.position - _base.get_rect().get_center()`; clamp `offset` so `offset.length() <= max_radius`; apply radial dead zone — if `offset.length() < max_radius * dead_zone_percentage` then `input_vector = Vector2.ZERO` else `input_vector = offset.normalized()`; call `accept_event()`. File: `scenes/ui/hud/Joystick.gd`
- [x] T010 [P] [US1] In `MovementComponent.gd`, implement `_physics_process(_delta: float) -> void`: if `_joystick == null` return; compute `var vel: Vector2 = _joystick.input_vector * move_speed`; set `get_parent().velocity = vel` and call `get_parent().move_and_slide()`. File: `scenes/player/components/MovementComponent.gd`

**Checkpoint**: User Story 1 is fully functional — player character navigates the dungeon by dragging the joystick.

---

## Phase 4: User Story 2 — Analog Speed Control (Priority: P2)

**Goal**: Drag distance proportionally controls movement speed — short drag =
slow, full drag = full speed.

**Independent Test**: In an empty room with US1 working, drag the joystick to
25%, 50%, and 100% of max radius. Character speed must visibly differ at each
position; midway drag ≈ half max speed.

### Implementation for User Story 2

- [x] T011 [US2] In `Joystick.gd _gui_input()` drag branch, replace `input_vector = offset.normalized()` with `input_vector = offset.normalized() * clampf(offset.length() / max_radius, 0.0, 1.0)` so magnitude encodes the 0.0–1.0 speed ratio. The dead zone branch (`input_vector = Vector2.ZERO`) remains unchanged. File: `scenes/ui/hud/Joystick.gd`

**Checkpoint**: User Stories 1 AND 2 both work independently — direction + proportional speed.

---

## Phase 5: User Story 3 — Visual Joystick Feedback (Priority: P3)

**Goal**: The on-screen knob visually tracks the finger during drag and snaps
back to centre on release.

**Independent Test**: With US1 and US2 working, watch the knob while dragging.
Knob must offset in the drag direction and animate back to centre within 0.1 s
of releasing — without looking at the character.

### Implementation for User Story 3

- [x] T012 [US3] In `Joystick.gd _gui_input()` drag branch, after computing `offset`, add `_knob.position = offset` so the Knob TextureRect tracks the finger. This line runs inside the drag branch, after the dead zone check. File: `scenes/ui/hud/Joystick.gd`
- [x] T013 [US3] In `Joystick.gd _gui_input()` touch-release branch (finger up), add `_knob.position = Vector2.ZERO` after resetting `input_vector` so the knob snaps back to centre instantly. File: `scenes/ui/hud/Joystick.gd`

**Checkpoint**: All three user stories independently functional and visually complete.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that apply across all stories or complete production readiness.

- [x] T014 Add gameplay-screen visibility control to ExplorationHUD: in `scenes/shared/GlobalSignals.gd` declare `signal gameplay_started()` and `signal gameplay_ended()`; in `scenes/ui/hud/ExplorationHUD.tscn` attach a script that connects to these signals and calls `show()` / `hide()` respectively; emit `gameplay_started` from `scenes/core/Main.gd` `_ready()`. Files: `scenes/shared/GlobalSignals.gd`, `scenes/ui/hud/ExplorationHUD.tscn`
- [ ] T015 [P] In Godot Editor, verify `Joystick.tscn` uses `anchor_left = 0`, `anchor_right = 0`, `anchor_top = 1`, `anchor_bottom = 1` (ANCHOR_BOTTOM_LEFT preset) with fixed pixel offsets so the joystick stays within the safe area on all target screen sizes. File: `scenes/ui/hud/Joystick.tscn`
- [ ] T016 [P] Run quickstart.md validation: open project in Godot Editor, enable touch emulation (Project → Project Settings → Input Devices → Pointing → Emulate Touch From Mouse), then verify all 7 steps and confirm the 5-item acceptance checklist in `specs/001-joystick-movement/quickstart.md` passes.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
  - T001 before T002 (Joystick.tscn must exist before instancing)
  - T003 parallel with T001 (different scene)
  - T004 after T002 and T003 (Main needs both scenes instantiated)
- **Foundational (Phase 2)**: Depends on Setup completion.
  - T005 and T006 fully parallel (different files)
  - T007 after T004, T005, T006 (needs scene structure + both APIs)
- **User Stories (Phase 3+)**: All depend on Phase 2 completion.
  - T008 before T009 (same function, sequential branches)
  - T010 parallel with T008–T009 (different file)
  - T011 after T009 (modifies same drag branch)
  - T012 after T009 (adds to drag branch)
  - T013 after T008 (adds to touch-release branch); parallel with T012

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — no dependency on US2 or US3.
- **US2 (P2)**: Can start after US1 T009 (modifies the same drag branch); no dependency on US3.
- **US3 (P3)**: Can start after US1 T008–T009 (extends same handlers); no dependency on US2.

### Within Each User Story

- Models/properties before handlers
- Touch press/release before drag (same function, logical order)
- Physics consumer (MovementComponent) parallel with input producer (Joystick)

### Parallel Opportunities

```bash
# Phase 1 — two independent streams:
Stream A: T001 → T002
Stream B: T003

# Wait for both, then:
T004

# Phase 2 — two independent streams:
Stream A: T005
Stream B: T006

# Wait for both, then:
T007

# Phase 3 (US1) — two independent streams:
Stream A: T008 → T009
Stream B: T010

# Phase 5 (US3) — two branches of same function:
Stream A: T012 (drag branch)
Stream B: T013 (release branch)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T004)
2. Complete Phase 2: Foundational (T005–T007)
3. Complete Phase 3: User Story 1 (T008–T010)
4. **STOP and VALIDATE**: Drag joystick → character moves → release → stops
5. Demo / playtest MVP

### Incremental Delivery

1. Setup + Foundational → infrastructure ready (no visible feature yet)
2. US1 → character steers with joystick at full speed → **MVP**
3. US2 → analog speed — gentle nudge = slow, full drag = fast
4. US3 → knob visually tracks finger, snaps back on release
5. Polish → HUD visibility, anchor verification, quickstart sign-off

---

## Notes

- All `[P]` tasks operate on different files and have no dependency on incomplete tasks.
- `[Story]` labels map directly to user stories in `specs/001-joystick-movement/spec.md`.
- Editor tasks (T001–T004, T015) modify `.tscn` files via the Godot Editor — do not edit `.tscn` as raw text (Constitution Principle IV).
- Verify dead zone behaviour manually: tiny accidental press must produce zero movement.
- `move_and_slide()` requires the parent of MovementComponent to be a CharacterBody2D (enforced by T003).
- Commit after each phase checkpoint before proceeding.
