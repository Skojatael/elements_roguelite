# Research: Dungeon Generator

**Feature**: 007-dungeon-generator
**Date**: 2026-02-23

---

## Decision 1: Where DungeonGenerator lives in the scene tree

**Decision**: `DungeonGenerator` is a plain `Node` child of `Main.tscn`, added in the Godot Editor. Script lives at `scenes/dungeon/DungeonGenerator.gd`.

**Rationale**: The generator needs scene-tree access (to read `get_parent()` as the room container and `get_tree()` to find the player). An autoload cannot reliably access the scene tree during `_ready()` ordering. A scene-attached node with a co-located script satisfies constitution Principle IV (Editor-Centric) and Principle I (SRP — one node, one job).

**Alternatives considered**:
- Make it an autoload — rejected: autoloads own a singleton domain; dungeon generation is a per-scene concern. Would also have scene-tree timing issues.
- Add generation logic to Main.gd — rejected: violates SRP (Main.gd already manages joystick wiring, player stats, DevPanel).

---

## Decision 2: How DungeonGenerator reacts to run start

**Decision**: Add `signal run_started(mode: String)` to `RunManager`; emit it at the end of `start_run()`. `DungeonGenerator._ready()` connects to `RunManager.run_started`.

**Rationale**: RunManager already owns the `run_ended` signal — `run_started` is the symmetric counterpart and belongs in the same domain. DungeonGenerator then reacts to events rather than being called imperatively, keeping Main.gd ignorant of the generator. Connecting in `_ready()` is safe because RunManager is an autoload (always available).

**Alternatives considered**:
- Call `DungeonGenerator.generate()` directly from Main.gd — rejected: Main.gd would need to know about DungeonGenerator, coupling two unrelated nodes.
- Poll `is_run_active` each frame — rejected: wasteful; event-driven is correct here.

---

## Decision 3: Room sequence stored in dungeon_config.json

**Decision**: Add `"room_sequence": ["CombatRoom01", "CombatRoom02", "EliteRoom01"]` to `data/dungeon_config.json`. DungeonGenerator reads this array via `ResourceManager.get_dungeon_config()`.

**Rationale**: Constitution Principle II prohibits hard-coded dungeon parameters in GDScript. The room sequence is a dungeon parameter. Storing it in the existing `dungeon_config.json` (already consumed by `ResourceManager`) requires zero new infrastructure and makes the sequence tunable without touching code.

**Alternatives considered**:
- Hard-code the array in DungeonGenerator.gd — rejected: violates Constitution Principle II.
- A dedicated `rooms_sequence.json` — rejected: YAGNI; `dungeon_config.json` already exists for dungeon configuration.

---

## Decision 4: RoomData loading at runtime vs preload

**Decision**: Use `load("res://data/rooms/{id}.tres")` at runtime. If `load()` returns null, log an error and stop spawning.

**Rationale**: The room sequence is data-driven (read from JSON), so the paths are not known at parse time — `preload()` requires compile-time string literals. `load()` with null checking matches FR-007 (graceful error handling) and allows the generator to continue partially if one asset is missing.

**Alternatives considered**:
- `preload()` array — rejected: requires hard-coding paths in GDScript, contradicting the data-driven approach.
- `ResourceLoader.load_threaded_*` — rejected: overkill for 3 small .tres files.

---

## Decision 5: Room container parent

**Decision**: Rooms are added as children of `DungeonGenerator.get_parent()` (i.e., `Main`). `SpawnContext.create(get_parent(), pos)` is called with the computed position.

**Rationale**: Rooms must be siblings of the player (both under Main) so their coordinate spaces are consistent. Using `get_parent()` avoids a hard-coded node path and keeps the generator portable.

**Alternatives considered**:
- Dedicated `World` node under Main — rejected: not present in current scene; adding it is out of scope (YAGNI).
- `get_tree().root` — rejected: unnecessarily broad scope.

---

## Decision 6: Player placement

**Decision**: After spawning, call `get_tree().get_first_node_in_group("player")` to find the player, then set `player.global_position = first_room_pos`. Player.tscn confirms `groups=["player"]`.

**Rationale**: Group-based lookup is the correct Godot pattern for cross-scene node access without hard-coded paths. Player.tscn already belongs to the `"player"` group (confirmed in `Player.tscn` line 15).

**Alternatives considered**:
- Hard-coded path `$"../Player"` — rejected: fragile, couples generator to Main hierarchy.
- Signal from DungeonGenerator to Main — rejected: over-engineered; direct group lookup is simpler and has one clear failure mode (node not in group → log error).

---

## Decision 7: Room spacing constant

**Decision**: `ROOM_SPACING: int = 1200` as a constant in `DungeonGenerator.gd`. Not in JSON for now.

**Rationale**: Spacing is a layout constant, not a balance parameter (no gameplay effect). YAGNI: putting it in JSON would require a reader path for a single int. Rooms are 1080 px wide; 1200 px gives 120 px gap between edges. Can be promoted to JSON when layout becomes procedural.

**Alternatives considered**:
- In dungeon_config.json — deferred: reasonable future move but not required now.
