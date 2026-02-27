# Implementation Plan: Room Loading & Doors

**Branch**: `009-room-loading-doors` | **Date**: 2026-02-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/009-room-loading-doors/spec.md`

---

## Summary

Implement lazy room loading: load only the start room at run start (as `StartRoom01`, a safe-zone room type with no enemies), then load adjacent rooms on demand when the player walks into a door. Doors are static `Area2D` slots in `RoomBase.tscn`; a new `RoomLoader` node orchestrates all scene instantiation, door configuration, player placement, and room teardown. Only one room is ever in memory at a time.

---

## Technical Context

**Language/Version**: GDScript, Godot 4.6
**Primary Dependencies**: `DungeonGenerator` (008) output (`rooms_by_id`, `neighbours_by_id`, `start_room_id`); `RunManager.spawn_room()`; `RoomSpawner` (003); `SpawnContext` (006)
**Storage**: JSON (`data/dungeon_config.json` — new `StartRoom01` spawn config); `.tres` (`data/rooms/StartRoom01.tres`)
**Testing**: Manual playtest via Godot Remote Inspector (see `quickstart.md`)
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Project Type**: Godot 4.6 mobile game
**Performance Goals**: Room transition completes within one frame; at all times ≤1 room scene in memory (FR-011)
**Constraints**: Mobile renderer; Jolt physics; one room in memory at a time; no raw `.tscn` editing

---

## Constitution Check

### Principle I — Single Responsibility ✅

- `RoomLoader.gd`: owns room lifecycle (load, unload, door configure, player placement). Single concern.
- `Door.gd`: owns self-detection (body entered → emit signal). Single concern.
- `DungeonGenerator.gd`: unchanged except emitting `dungeon_layout_ready`. Still a pure data generator.
- No existing script absorbs a second responsibility.

### Principle II — Data-Driven Content ✅

- `StartRoom01.tres` + `data/dungeon_config.json` entry define the new room type through the data layer.
- `ENTRY_OFFSET = 150.0` is a geometric layout constant, not a game-balance value. Acceptable as a named GDScript constant.
- Door slot positions (`±540`, `±960`) are structural room geometry, not balance values. Acceptable as named constants.

### Principle III — Mobile-First Performance ✅

- FR-011 (one room in memory) directly minimises RAM usage for mobile.
- `queue_free()` is the correct Godot teardown; no manual resource releasing needed.
- `Door` uses `Area2D` (detector) not `CharacterBody2D` (physics body) — minimal overhead.

### Principle IV — Editor-Centric Workflow ✅

- `Door.tscn`, `StartRoom01.tscn` created via the Godot Editor.
- `RoomBase.tscn` modifications (adding door slot instances) done in Editor.
- `Main.tscn` modification (adding `RoomLoader` node) done in Editor.
- No raw `.tscn` text editing.

### Principle V — Simplicity & YAGNI ✅

- `OPPOSITE` dictionary replaces a direction-inversion function — no abstraction needed.
- No new autoloads introduced; `RoomLoader` is a plain `Node`.
- `RoomSpawner` is unchanged — fresh instantiation already handles enemy respawn for free.
- No stub scripts or placeholder hooks.

---

## Project Structure

### Documentation (this feature)

```text
specs/009-room-loading-doors/
├── plan.md              ← This file
├── research.md          ← Phase 0 (10 decisions)
├── data-model.md        ← Phase 1
├── quickstart.md        ← Phase 1
├── contracts/
│   └── signals.md       ← Phase 1
└── tasks.md             ← Phase 2 (/speckit.tasks)
```

### Source Code

**New GDScript files** (write via code editor):

```text
scenes/dungeon/RoomLoader.gd
scenes/dungeon/doors/Door.gd
```

**New scene files** (create in Godot Editor):

```text
scenes/dungeon/doors/Door.tscn
scenes/dungeon/rooms/StartRoom01.tscn
```

**New data files** (create in Godot Editor / Inspector):

```text
data/rooms/StartRoom01.tres
```

**Modified GDScript files**:

```text
scenes/dungeon/DungeonGenerator.gd    ← add signal + emit; remove _place_player() call and function
```

**Modified scene files** (Godot Editor):

```text
scenes/dungeon/RoomBase.tscn          ← add DoorN, DoorS, DoorE, DoorW as Door.tscn instances
scenes/core/Main.tscn                 ← add RoomLoader node as child (sibling of DungeonGenerator)
```

**Modified data files**:

```text
data/dungeon_config.json              ← add StartRoom01 entry in spawn_configs
```

---

## Implementation Phases

### Phase 1 — Data & Config

1. Add `"StartRoom01": { "spawn_points": [] }` to `spawn_configs` in `data/dungeon_config.json`.

### Phase 2 — GDScript: `Door.gd`

Write `scenes/dungeon/doors/Door.gd`:

- `class_name Door extends Area2D`
- `@export var direction: String = ""`
- `@export var target_room_id: String = ""`
- `signal door_activated(direction: String, target_room_id: String)`
- `_ready()`: connect `body_entered` to `_on_body_entered`
- `_on_body_entered(body)`: if `body.is_in_group("player")`: emit `door_activated(direction, target_room_id)`

### Phase 3 — Editor: `Door.tscn`

In the Godot Editor:

1. Create new scene: root node `Area2D`, attach `Door.gd`.
2. Add child `CollisionShape2D` with `RectangleShape2D` size `Vector2(200, 200)`.
3. Set `CollisionLayer` and `CollisionMask` appropriately (must detect player body).
4. Save as `scenes/dungeon/doors/Door.tscn`.

### Phase 4 — Editor: `RoomBase.tscn` door slots

In the Godot Editor:

1. Open `scenes/dungeon/RoomBase.tscn`.
2. Add four `Door.tscn` instances as children:
   - `DoorN` at position `Vector2(0, -540)`, `direction = "N"`
   - `DoorS` at position `Vector2(0, 540)`, `direction = "S"`
   - `DoorE` at position `Vector2(960, 0)`, `direction = "E"`
   - `DoorW` at position `Vector2(-960, 0)`, `direction = "W"`
3. Save `RoomBase.tscn`.

### Phase 5 — Editor: `StartRoom01.tscn` and `StartRoom01.tres`

In the Godot Editor:

1. Create `StartRoom01.tscn` as an inherited scene from `RoomBase.tscn`.
2. On the `RoomSpawner` node, set `room_type_id = "StartRoom01"`.
3. Save as `scenes/dungeon/rooms/StartRoom01.tscn`.
4. In the Inspector, create a new `RoomData` resource. Set `room_type_id = "StartRoom01"`, `scene = StartRoom01.tscn`. Save as `data/rooms/StartRoom01.tres`.

### Phase 6 — GDScript: `DungeonGenerator.gd` changes

Edit `scenes/dungeon/DungeonGenerator.gd`:

1. Add `signal dungeon_layout_ready` at the top (below class_name).
2. At the end of `_generate()`, replace `_place_player(rooms_by_id[start_room_id]["world_pos"])` with `dungeon_layout_ready.emit()`.
3. Remove the `_place_player()` function entirely.

### Phase 7 — GDScript: `RoomLoader.gd`

Write `scenes/dungeon/RoomLoader.gd`:

```
class_name RoomLoader
extends Node

signal: none (consumer only)

constants:
  ENTRY_OFFSET: float = 150.0
  OPPOSITE: Dictionary = {"N": "S", "S": "N", "E": "W", "W": "E"}
  ENTRY_LOCAL: Dictionary = {
    "N": Vector2(0.0, -540.0 + 150.0),
    "S": Vector2(0.0, 540.0 - 150.0),
    "E": Vector2(960.0 - 150.0, 0.0),
    "W": Vector2(-960.0 + 150.0, 0.0)
  }

state:
  _loading: bool = false
  _current_room_node: Node = null
  _dungeon_gen: DungeonGenerator = null

_ready():
  get sibling DungeonGenerator node
  connect dungeon_layout_ready → _on_layout_ready

_on_layout_ready():
  _load_room(dungeon_gen.start_room_id, "")

_load_room(room_id: String, entry_direction: String):
  if _loading: return
  _loading = true
  if _current_room_node != null:
    RunManager.current_room = null
    _current_room_node.queue_free()
    _current_room_node = null
  get room_data from rooms_by_id[room_id]
  type_id = room_data["room_type_id"]
  if room_id == start_room_id: type_id = "StartRoom01"
  load RoomData resource from "res://data/rooms/{type_id}.tres"
  if null: push_error, _loading = false, return
  context = SpawnContext.create(get_parent(), room_data["world_pos"])
  spawner = RunManager.spawn_room(room_resource, room_id, context)
  _current_room_node = spawner.get_parent()
  _configure_doors(_current_room_node, room_id)
  _place_player(entry_direction, room_data["world_pos"])
  _loading = false

_configure_doors(room_node: Node, room_id: String):
  build dir_to_neighbour: Dictionary by comparing grid_pos deltas
  for direction in ["N", "S", "E", "W"]:
    door = room_node.get_node_or_null("Door" + direction)
    if door == null: continue
    if dir_to_neighbour.has(direction):
      door.visible = true
      door.monitoring = true
      door.target_room_id = dir_to_neighbour[direction]
      door.direction = direction
      connect door.door_activated → _on_door_activated (if not already connected)
    else:
      door.visible = false
      door.monitoring = false

_place_player(entry_direction: String, world_pos: Vector2):
  player = get_tree().get_first_node_in_group("player")
  if null: push_error, return
  if entry_direction.is_empty():
    player.global_position = world_pos
  else:
    player.global_position = world_pos + ENTRY_LOCAL[entry_direction]

_on_door_activated(direction: String, target_room_id: String):
  entry_direction = OPPOSITE[direction]
  _load_room(target_room_id, entry_direction)
```

### Phase 8 — Editor: `Main.tscn` — add `RoomLoader` node

In the Godot Editor:

1. Open `scenes/core/Main.tscn`.
2. Add a `Node` child named `RoomLoader`, attach `RoomLoader.gd`.
3. Position it as a sibling of `DungeonGenerator` (order does not matter — sequencing is via signals).
4. Save `Main.tscn`.

### Phase 9 — Validate

Run all 13 scenarios from `specs/009-room-loading-doors/quickstart.md`.

---

## Key Design Decisions

| Decision | Summary |
|---|---|
| Orchestrator | New `RoomLoader.gd` Node (SRP — DungeonGenerator stays pure data) |
| Signal ordering | `dungeon_layout_ready` signal guarantees RoomLoader runs after layout is ready |
| Room unloading | `queue_free()` — safe from within signal chain; auto-disconnects signals |
| Door architecture | 4 static slots in RoomBase.tscn — editor-visible, inherited by all combat rooms |
| Player entry | ENTRY_OFFSET = 150px inward from wall; directional matching for spatial continuity |
| StartRoom override | RoomLoader overrides type to "StartRoom01" at load time — DungeonGenerator stays generic |
| Enemy respawn | RoomSpawner unchanged — fresh instantiation + is_room_cleared() handles Option B |

*(See `research.md` for full rationale on each decision.)*
