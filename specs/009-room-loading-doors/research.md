# Research: Room Loading & Doors (009)

**Date**: 2026-02-24
**Feature**: [spec.md](spec.md)

---

## Decision 1 — Orchestrator: New RoomLoader Node

**Decision**: A new `RoomLoader.gd` Node (child of Main.tscn, sibling of DungeonGenerator) owns all room loading/unloading, door configuration, and player placement.

**Rationale**: Constitution Principle I (SRP). DungeonGenerator already has a clear single responsibility — generating layout data. Loading scenes, configuring doors, and placing the player are distinct concerns that belong to a separate owner. Keeping them in DungeonGenerator would violate SRP. RunManager is not appropriate either — it owns run lifecycle, not scene management.

**Alternatives considered**:
- Extend DungeonGenerator: violates SRP — mixes data generation with scene management.
- Put in RunManager: RunManager owns run state, not scene instantiation.

---

## Decision 2 — Signal Ordering: `dungeon_layout_ready`

**Decision**: `DungeonGenerator` emits a new `dungeon_layout_ready` signal at the end of `_generate()`. `RoomLoader` connects to this signal (not to `run_started`).

**Rationale**: Both DungeonGenerator and RoomLoader connect to `run_started`. Godot fires connected handlers in connection order, which depends on scene tree node order — fragile. Using a dedicated `dungeon_layout_ready` signal guarantees RoomLoader runs only after DungeonGenerator has populated `rooms_by_id`, `neighbours_by_id`, and `start_room_id`. No ordering assumption needed.

**Alternatives considered**:
- Both connect to `run_started`, rely on tree order: fragile, breaks silently if tree order changes.
- RoomLoader polls DungeonGenerator: adds unnecessary complexity.

---

## Decision 3 — Room Unloading Strategy

**Decision**: When the player activates a door, `RoomLoader` calls `queue_free()` on the current room's root node before instantiating the next room. `RunManager.current_room` is set to `null` to avoid stale reference.

**Rationale**: `queue_free()` is the standard Godot way to remove a node at the end of the current frame. It automatically disconnects all signal connections on the freed node, so no manual disconnect is needed. Only one room exists in memory at any time (FR-011). The `current_room` null-out prevents RunManager from holding a dangling object reference.

**Alternatives considered**:
- `free()` (immediate): can cause crashes if called from within a signal chain on the node being freed. `queue_free()` is always safe.
- Keep rooms loaded, just hide them: violates FR-011 (one room in memory); wastes mobile RAM.

---

## Decision 4 — Door Architecture: Static Slots in RoomBase

**Decision**: Four named Door nodes (`DoorN`, `DoorS`, `DoorE`, `DoorW`) are added to `RoomBase.tscn` as children. Each is a `Door.tscn` instance positioned at the room's cardinal wall edges. `RoomLoader` shows/hides each door based on neighbour presence and sets its `target_room_id`.

**Rationale**: Constitution Principle IV (Editor-Centric Workflow). Having doors as static scene children keeps the scene self-contained and visible/editable in the Godot Editor. The alternative (dynamically adding Door nodes at runtime) is code-driven and invisible to the Editor, making scene inspection harder.

**Door local positions within room** (room is 1920×1080 centered at origin):
- `DoorN`: `Vector2(0, -540)` — top-center wall
- `DoorS`: `Vector2(0, 540)` — bottom-center wall
- `DoorE`: `Vector2(960, 0)` — right-center wall
- `DoorW`: `Vector2(-960, 0)` — left-center wall

**Alternatives considered**:
- Add doors dynamically in code: invisible in Editor, harder to inspect.
- One Door.tscn scene, 4 instances: same as chosen approach.

---

## Decision 5 — Door Collision Shape

**Decision**: Each `Door` is an `Area2D` with a `CollisionShape2D` of size `200×200`, centered at the wall edge. Half extends inside the room, half outside.

**Rationale**: Placing the collision shape centred on the wall edge means the player triggers it as they walk into the wall — natural feel. 200×200 is wide enough to be easy to hit, narrow enough to feel like a doorway. The Area2D approach (vs CharacterBody2D) is correct since doors are detectors, not physical obstacles.

**Alternatives considered**:
- Thin strip entirely inside room: player must reach the wall before triggering — less responsive.
- Large collision zone: triggers unintentionally from a distance.

---

## Decision 6 — Player Entry Placement

**Decision**: When entering a room through direction D, the player is placed at the D-side door position offset 150px inward from the wall.

Entry positions (relative to room `world_pos`):
- Entering from North (through north door): `world_pos + Vector2(0, -540 + 150)` = `Vector2(0, -390)` relative
- Entering from South: `Vector2(0, 390)` relative
- Entering from East: `Vector2(810, 0)` relative
- Entering from West: `Vector2(-810, 0)` relative
- Start room (no entry direction): placed at `world_pos` (room center)

**Rationale**: 150px is comfortably inside the room, past the door collision zone, so no immediate re-trigger. Directional placement gives spatial continuity — if the player exits east, they appear on the west side of the next room. ENTRY_OFFSET is a named constant for easy tuning.

**Alternatives considered**:
- Always place at room center: loses directional context.
- Place at exact door position: player may immediately re-trigger the door they just came through.

---

## Decision 7 — StartRoom Type Override

**Decision**: `RoomLoader` overrides the `room_type_id` for the `start_room_id` cell to `"StartRoom01"` at load time. `DungeonGenerator` continues to assign a random CombatRoom* type to that cell; the override happens only when the scene is loaded.

**Rationale**: `DungeonGenerator` is a pure data generator — it should not need to know about StartRoom. The override in RoomLoader keeps DungeonGenerator's output consistent (all 8 cells get a CombatRoom* type) while applying the safe-zone logic exactly where it matters: at scene instantiation time. This also makes it easy to change the start room type without touching the generator.

**Alternatives considered**:
- DungeonGenerator assigns StartRoom01 to the center cell: couples generator to room type names; generator should not know about gameplay-specific types.
- Add a `is_start: bool` field to rooms_by_id: possible but YAGNI — the override in RoomLoader is simpler.

---

## Decision 8 — RoomSpawner Interaction with Fresh Instantiation

**Decision**: No changes needed to `RoomSpawner.gd`. When a room scene is freed and re-instantiated, `_spawned = false` and `_living_count = 0` by default (GDScript default values). The existing `is_room_cleared(room_id)` check handles cleared-room suppression.

**Rationale**: The existing `RoomSpawner` logic already covers the Option B (enemy respawn) requirement:
- Fresh instantiation → `_spawned = false` → enemies will spawn when player enters
- `RunManager.is_room_cleared(room_id)` returns true for cleared rooms → spawning skipped
- No code change needed.

---

## Decision 9 — DungeonGenerator._place_player() Removal

**Decision**: Remove the `_place_player()` call from `DungeonGenerator._generate()`. `RoomLoader` takes over all player placement from this feature onward.

**Rationale**: With `RoomLoader` placing the player at the start room entry (room center), having `DungeonGenerator` also call `_place_player()` creates redundant placement (same position but double work). More importantly, it creates a confusing split of ownership: two systems independently managing player position. RoomLoader should be the single owner of "where the player is placed on room load".

---

## Decision 10 — RunManager Integration

**Decision**: `RoomLoader` calls `RunManager.spawn_room()` to instantiate each room. Before freeing the outgoing room, RoomLoader sets `RunManager.current_room = null` to avoid stale references. No new RunManager methods are needed.

**Rationale**: `RunManager.spawn_room()` connects room signals (`room_entered`, `room_cleared`) and updates `current_room`. Using it keeps RunManager informed of the active room without bypassing established patterns. Setting `current_room = null` before `queue_free()` is a one-liner that prevents stale reference issues; no dedicated method is worth the extra complexity.

**Alternatives considered**:
- RoomLoader calls RoomFactory directly: bypasses RunManager signal connections; RunManager would not track the active room.
- Add `RunManager.clear_current_room()` method: YAGNI — the direct assignment is sufficient.
