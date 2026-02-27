# Tasks: Room Loading & Doors

**Input**: Design documents from `specs/009-room-loading-doors/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/signals.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. All three stories are P1 and build sequentially: US1 (start room) → US2 (doors visible) → US3 (door transitions).

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths are included in every task description
- **Editor tasks**: must be performed in the Godot 4.6 Editor (cannot be done via text editing)

---

## Phase 1: Setup

**Purpose**: Add the new room type's spawn config before any script or scene work begins.

- [x] T001 Add `"StartRoom01": { "spawn_points": [] }` as an entry inside the `"spawn_configs"` object in `data/dungeon_config.json` (keep all existing entries; just add this new key alongside `CombatRoom01` and `CombatRoom02`)

---

## Phase 2: Foundational

**Purpose**: Add the `dungeon_layout_ready` signal to `DungeonGenerator` — the sequencing mechanism that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Modify `scenes/dungeon/DungeonGenerator.gd`: (1) add `signal dungeon_layout_ready` on the line immediately after `extends Node`; (2) at the end of `_generate()` replace the line `_place_player(rooms_by_id[start_room_id]["world_pos"])` with `dungeon_layout_ready.emit()`; (3) delete the entire `_place_player()` function (lines 102–108)

**Checkpoint**: Foundational complete — `DungeonGenerator` emits `dungeon_layout_ready` at the end of every `_generate()` call, and no longer places the player itself.

---

## Phase 3: User Story 1 — Start Room Loads at Run Start (Priority: P1) 🎯 MVP

**Goal**: When `run_started` fires, the start room scene (`StartRoom01`) is instantiated and the player is placed at the room center with no enemies.

**Independent Test**: Start a run. In the Godot Remote scene tree, confirm a `StartRoom01` node is present under Main. Confirm the Player's `global_position` is `(0, 0)`. Confirm no enemy nodes are children of the room.

- [ ] T003 [P] [US1] **(Editor)** Create `scenes/dungeon/rooms/StartRoom01.tscn` as an inherited scene from `scenes/dungeon/RoomBase.tscn`; in the inherited scene select the `RoomSpawner` node and set `room_type_id = "StartRoom01"` in the Inspector; save

- [ ] T004 [P] [US1] **(Editor)** Create `data/rooms/StartRoom01.tres` as a new `RoomData` resource in the Godot Inspector: set `room_type_id = "StartRoom01"` and `scene` to `scenes/dungeon/rooms/StartRoom01.tscn`; save

- [x] T005 [P] [US1] Write `scenes/dungeon/RoomLoader.gd` with the following complete implementation:

  ```
  class_name RoomLoader
  extends Node

  const ENTRY_OFFSET: float = 150.0
  const OPPOSITE: Dictionary = {"N": "S", "S": "N", "E": "W", "W": "E"}
  const ENTRY_LOCAL: Dictionary = {
      "N": Vector2(0.0, -540.0 + ENTRY_OFFSET),
      "S": Vector2(0.0, 540.0 - ENTRY_OFFSET),
      "E": Vector2(960.0 - ENTRY_OFFSET, 0.0),
      "W": Vector2(-960.0 + ENTRY_OFFSET, 0.0)
  }

  var _loading: bool = false
  var _current_room_node: Node = null
  var _dungeon_gen: DungeonGenerator = null

  _ready():
    _dungeon_gen = get_parent().get_node("DungeonGenerator")
    _dungeon_gen.dungeon_layout_ready.connect(_on_layout_ready)

  _on_layout_ready():
    _load_room(_dungeon_gen.start_room_id, "")

  _load_room(room_id: String, entry_direction: String) -> void:
    if _loading: return
    _loading = true
    # NOTE: room unloading (queue_free) added in T011
    var room_data: Dictionary = _dungeon_gen.rooms_by_id.get(room_id, {})
    if room_data.is_empty():
      push_error("RoomLoader: room_id={id} not found in rooms_by_id".format({"id": room_id}))
      _loading = false
      return
    var type_id: String = room_data["room_type_id"]
    if room_id == _dungeon_gen.start_room_id:
      type_id = "StartRoom01"
    var res_path: String = "res://data/rooms/{type}.tres".format({"type": type_id})
    var room_resource: RoomData = load(res_path)
    if room_resource == null:
      push_error("RoomLoader: RoomData not found at {path}".format({"path": res_path}))
      _loading = false
      return
    var context: SpawnContext = SpawnContext.create(get_parent(), room_data["world_pos"])
    var spawner: RoomSpawner = RunManager.spawn_room(room_resource, room_id, context)
    if spawner == null:
      _loading = false
      return
    _current_room_node = spawner.get_parent()
    _configure_doors(_current_room_node, room_id)
    _place_player(entry_direction, room_data["world_pos"])
    _loading = false

  _configure_doors(_room_node: Node, _room_id: String) -> void:
    pass  # Implemented in T010

  _place_player(entry_direction: String, world_pos: Vector2) -> void:
    var player: Node = get_tree().get_first_node_in_group("player")
    if player == null:
      push_error("RoomLoader: player not found in group 'player'")
      return
    if entry_direction.is_empty():
      player.global_position = world_pos
    else:
      player.global_position = world_pos + ENTRY_LOCAL[entry_direction]

  _on_door_activated(_direction: String, _target_room_id: String) -> void:
    pass  # Implemented in T011
  ```

  All static typing (`var x: Type`) and `String.format()` with named keys MUST be used throughout.

- [ ] T006 [US1] **(Editor)** Add `RoomLoader` node to `scenes/core/Main.tscn`: open Main.tscn in the Godot Editor, add a `Node` child of the Main node, name it `"RoomLoader"`, attach `scenes/dungeon/RoomLoader.gd` as its script; position it as a sibling of `DungeonGenerator`; save

**Checkpoint**: US1 independently testable — start a run; `StartRoom01` appears in the Remote scene tree; Player `global_position = (0, 0)`; no enemy nodes present.

---

## Phase 4: User Story 2 — Doors Appear Where Neighbours Exist (Priority: P1) 🎯 MVP

**Goal**: Each loaded room shows door nodes only on sides that have a neighbour in the dungeon layout; sides with no neighbour have their door node hidden and monitoring disabled.

**Independent Test**: Start a run. Inspect `DungeonGenerator.neighbours_by_id["room_2_2"]` in the Remote inspector — note the count. Inspect the start room's `DoorN`, `DoorS`, `DoorE`, `DoorW` child nodes — exactly that many should have `visible = true`; the rest `visible = false`.

- [x] T007 [P] [US2] Write `scenes/dungeon/doors/Door.gd`:

  ```
  class_name Door
  extends Area2D

  @export var direction: String = ""
  @export var target_room_id: String = ""

  signal door_activated(direction: String, target_room_id: String)

  func _ready() -> void:
    body_entered.connect(_on_body_entered)

  func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
      door_activated.emit(direction, target_room_id)
  ```

  Use static typing and `String.format()` throughout.

- [ ] T008 [US2] **(Editor)** Create `scenes/dungeon/doors/Door.tscn`: in the Godot Editor, create a new scene with root node type `Area2D`; rename the root to `Door`; attach `scenes/dungeon/doors/Door.gd` as its script; add a `CollisionShape2D` child; in the CollisionShape2D Inspector, create a new `RectangleShape2D` with `size = Vector2(200, 200)`; set the Area2D's `collision_layer` and `collision_mask` to include the player's physics layer; save as `scenes/dungeon/doors/Door.tscn` (depends on T007)

- [ ] T009 [US2] **(Editor)** Add four `Door.tscn` instances to `scenes/dungeon/RoomBase.tscn`: open RoomBase.tscn in the Godot Editor; instance `Door.tscn` four times as children of the root node; set names and Inspector properties as follows:
  - `DoorN`: position `Vector2(0, -540)`, `direction = "N"`
  - `DoorS`: position `Vector2(0, 540)`, `direction = "S"`
  - `DoorE`: position `Vector2(960, 0)`, `direction = "E"`
  - `DoorW`: position `Vector2(-960, 0)`, `direction = "W"`

  Save `RoomBase.tscn` (depends on T008)

- [x] T010 [US2] Implement `_configure_doors(room_node: Node, room_id: String) -> void` in `scenes/dungeon/RoomLoader.gd` — replace the `pass` stub with:

  ```
  var neighbours: Array = _dungeon_gen.neighbours_by_id.get(room_id, [])
  if neighbours.is_empty() and room_id != _dungeon_gen.start_room_id:
    push_warning("RoomLoader: no neighbours for room_id={id}".format({"id": room_id}))

  # Build direction → neighbour_id map from grid_pos deltas
  var delta_to_dir: Dictionary = {
    Vector2i(1, 0): "E", Vector2i(-1, 0): "W",
    Vector2i(0, 1): "S", Vector2i(0, -1): "N"
  }
  var dir_to_neighbour: Dictionary = {}
  var current_grid: Vector2i = _dungeon_gen.rooms_by_id[room_id]["grid_pos"]
  for neighbour_id: String in neighbours:
    var neighbour_grid: Vector2i = _dungeon_gen.rooms_by_id[neighbour_id]["grid_pos"]
    var delta: Vector2i = neighbour_grid - current_grid
    if delta_to_dir.has(delta):
      dir_to_neighbour[delta_to_dir[delta]] = neighbour_id

  # Show/hide each door slot
  for direction: String in ["N", "S", "E", "W"]:
    var door: Door = room_node.get_node_or_null("Door{dir}".format({"dir": direction}))
    if door == null:
      continue
    if dir_to_neighbour.has(direction):
      door.visible = true
      door.monitoring = true
      door.target_room_id = dir_to_neighbour[direction]
      door.direction = direction
      if not door.door_activated.is_connected(_on_door_activated):
        door.door_activated.connect(_on_door_activated)
    else:
      door.visible = false
      door.monitoring = false
  ```

  This edit replaces only the `_configure_doors` function body (depends on T009).

**Checkpoint**: US2 independently testable — start a run; the start room's visible door count matches `DungeonGenerator.neighbours_by_id["room_2_2"].size()`; hidden doors have `monitoring = false`.

---

## Phase 5: User Story 3 — Touching a Door Loads the Adjacent Room (Priority: P1) 🎯 MVP

**Goal**: When the player walks into a visible door, the current room is freed, the adjacent room is instantiated fresh, and the player is placed near the matching entrance. Cleared rooms spawn no enemies; non-cleared rooms spawn fresh enemies.

**Independent Test**: Start a run. Touch a door. Confirm: the start room node is gone from the Remote scene tree; a new combat room node is present; the player is at the correct entry position (e.g., east door → player near west wall of new room). Enter and clear a combat room, return, re-enter — confirm no enemies. Enter a non-cleared room, retreat, re-enter — confirm enemies respawn.

- [x] T011 [US3] Make two edits to `scenes/dungeon/RoomLoader.gd`:

  **Edit 1** — In `_load_room()`, insert room unloading immediately after the `_loading = true` line and before the `rooms_by_id.get()` call:

  ```
  if _current_room_node != null:
    RunManager.current_room = null
    _current_room_node.queue_free()
    _current_room_node = null
  ```

  **Edit 2** — Replace the `_on_door_activated` stub `pass` body with:

  ```
  var entry_direction: String = OPPOSITE[direction]
  _load_room(target_room_id, entry_direction)
  ```

**Checkpoint**: US3 independently testable — door touch triggers a room transition; only one room exists in the scene tree at all times; player appears at the correct entry offset; cleared/non-cleared enemy behaviour works correctly.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Manual validation of all scenarios and logging review.

- [ ] T012 Run all 13 validation scenarios from `specs/009-room-loading-doors/quickstart.md` — confirm: start room loads (S1–S3), doors match neighbours (S4), transitions work (S5–S6), one room in memory (S7), cleared room suppression (S8), non-cleared respawn (S9), directional continuity (S10), duplicate touch guard (S11), missing asset error handling (S12), missing neighbours warning (S13)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on T001 (config in place before testing)
- **US1 (Phase 3)**: Depends on T002 (DungeonGenerator signal must exist)
- **US2 (Phase 4)**: Depends on US1 complete (T003–T006) — RoomLoader must exist to call `_configure_doors`
- **US3 (Phase 5)**: Depends on US2 complete (T007–T010) — doors must be present and `_configure_doors` must connect signals
- **Polish (Phase 6)**: Depends on US3 complete (T011)

### User Story Dependencies

- **US1**: Requires foundational T002 only
- **US2**: Requires US1 complete — `_configure_doors` is called from `_load_room` (which exists after T005); Door.tscn must exist in RoomBase.tscn (T009)
- **US3**: Requires US2 complete — `door_activated` signal connections (set up in T010) must exist before `_on_door_activated` receives calls

### Within Each Phase

- T003, T004, T005 are [P] — different files, no intra-US1 dependencies
- T006 after T005 — needs RoomLoader.gd to exist to attach as script
- T007 [P] — Door.gd is independent within its phase
- T008 after T007 — scene references Door.gd
- T009 after T008 — RoomBase.tscn instances Door.tscn
- T010 after T009 — `_configure_doors` logic references Door node names set in T009
- T011 after T010 — `door_activated` connections (T010) must exist for `_on_door_activated` to receive calls

---

## Parallel Example: US1 Phase

```text
# T003, T004, T005 can all run in parallel (different files):
Task: "Create StartRoom01.tscn in Godot Editor"        ← T003 (Editor)
Task: "Create StartRoom01.tres in Godot Inspector"     ← T004 (Editor)
Task: "Write RoomLoader.gd initial implementation"     ← T005 (code)

# T006 must wait for T005 (needs .gd file to attach):
Task: "Add RoomLoader node to Main.tscn"               ← T006 (Editor, after T005)
```

---

## Implementation Strategy

### MVP First (All three stories — delivered together)

All three user stories are P1 and form a single end-to-end feature. Complete them in order:

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational signal (T002)
3. Complete Phase 3: US1 — start room loads (T003–T006)
4. **STOP and VALIDATE**: Start run → StartRoom01 loads → player at (0,0) → no enemies
5. Complete Phase 4: US2 — doors visible (T007–T010)
6. **STOP and VALIDATE**: Start run → correct number of visible doors
7. Complete Phase 5: US3 — door transitions (T011)
8. **STOP and VALIDATE**: Touch door → room transitions correctly; only one room in memory
9. Complete Phase 6: Polish (T012)

### Incremental Checkpoints

After T006: Start room loads and player is placed — US1 is fully verifiable without doors.
After T010: Doors appear correctly — US2 verifiable; touching a door calls `_on_door_activated` stub (no-op, no crash).
After T011: Full room cycling works — all three stories verifiable end-to-end.

---

## Notes

- All script edits use static typing and `String.format()` with named keys — no `%` specifiers
- `scenes/dungeon/doors/` is a new subdirectory — create it via Editor when saving `Door.tscn`
- T005 writes the complete `RoomLoader.gd` with stubs; T010 and T011 replace stubs with implementations — edit the same file sequentially
- Editor tasks (T003, T004, T006, T008, T009) cannot be done via code; they require the Godot Editor open
- `CombatRoom01.tscn` and `CombatRoom02.tscn` inherit from `RoomBase.tscn` — they automatically get the four door slots once T009 is complete
- Commit after each phase completes
