# Research: Room Factory

**Feature**: 006-room-factory
**Date**: 2026-02-23
**Status**: Complete — no NEEDS CLARIFICATION markers in spec

---

## Decision 1: Room Type → Scene Mapping Location

**Question**: Should the room_type_id → scene file mapping live in a `const Dictionary` inside
RoomFactory, `dungeon_config.json`, or a Godot Resource (`.tres`) per room type?

**Decision**: `RoomData extends Resource` saved as `.tres` files in `res://data/rooms/`. Each
`.tres` asset carries a `scene: PackedScene` reference and a `room_type_id: String`. The factory
receives a `RoomData` instance and reads `room_data.scene` directly — no registry needed.

**Rationale**: Constitution Principle IV mandates editor-centric workflow; `.tres` files are
authored in the Godot Inspector, giving the editor first-class visibility into every room type.
Principle II requires game content to be data-driven; RoomData as a Resource moves the scene
mapping out of code entirely. The `const Dictionary` in code was still a hard-coded registry
(just in GDScript instead of JSON). `.tres` resources load efficiently via `preload()` or
`load()` at call sites, and adding a new room type requires only creating a new `.tres` asset
— no code changes.

**Alternatives considered**:
- `const Dictionary` in RoomFactory — rejected: code-level registry; adding a room type requires
  editing RoomFactory.gd; violates data-driven principle for content mapping.
- `dungeon_config.json` with a `room_scenes` section — rejected: scene paths in JSON couple the
  data layer to the file system; no editor tooling; breaks preload optimisation.

---

## Decision 2: Return Type — RoomController wrapper vs RoomSpawner directly

**Question**: Should the factory return a thin `RoomController` wrapper or the `RoomSpawner` itself?

**Decision**: Return `RoomSpawner` directly.

**Rationale**: RunManager already knows about RoomSpawner — `register_room(spawner: Node)` connects
to its signals today. A RoomController wrapper whose only job is forwarding those same signals adds
a layer of indirection with no present benefit. The concrete case for an abstraction (room scenes
with different internal structures, or multiple unrelated observers) does not exist yet. Constitution
Principle V (YAGNI): abstraction needs two concrete use sites. Returning the spawner directly keeps
both the factory path and the existing register_room path uniform.

**Alternatives considered**:
- `RoomController extends RefCounted` — rejected: premature abstraction; only forwards signals that
  callers could connect to directly; no current requirement justifies the indirection.

---

## Decision 3: SpawnContext — Data Class vs Inline Parameters

**Question**: Should SpawnContext be a named data class or should `spawn_room()` take `parent` and
`position` as separate parameters?

**Decision**: `SpawnContext extends RefCounted` — a named data class with `parent: Node` and
`position: Vector2` fields.

**Rationale**: A named bundle improves call-site readability and makes the contract explicit. When
the future dungeon generator calls the factory, it will construct a SpawnContext from its layout data
— a named type is more maintainable than relying on parameter order. The class has exactly two fields
(per spec Assumptions), so it is not premature abstraction (constitution Principle V threshold: used
by at least one concrete call site, and the bundle type documents its purpose). Placed in
`scripts/data_models/` following existing conventions.

**Alternatives considered**:
- Two inline parameters — rejected: positional parameters are harder to read at call sites; no named
  documentation of what the bundle means.

---

## Decision 4: Auto-Registration Conflict Resolution

**Question**: RoomSpawner currently calls `RunManager.register_room(self)` in `_ready()`. A
factory-created room would fire this automatically after `add_child()`, conflicting with RoomFactory
returning a RoomController that also forwards the same signals. How is this resolved?

**Decision**: Add `@export var auto_register: bool = true` to RoomSpawner. RoomFactory sets it to
`false` on the instantiated node before `add_child()`, preventing the auto-registration. RoomFactory
then creates and returns the RoomController. RunManager.register_room() is also updated to internally
create a RoomController wrapper (so `current_room` can be typed `RoomController` uniformly across
both code paths).

**Rationale**: This is the minimal change that preserves backward compatibility (pre-placed rooms
in Main.tscn continue to use auto_register=true) while enabling the factory path. A boolean flag
on RoomSpawner is the least invasive mechanism. Alternatives that modify the scene tree structure
or add intermediate nodes violate Principle V.

**Alternatives considered**:
- Remove auto-registration from RoomSpawner entirely — rejected: breaks existing pre-placed rooms in
  Main.tscn; larger refactor outside this feature's scope.
- Disconnect in RoomFactory post-add_child — rejected: signals already connected in _ready(); fragile.
- Factory-specific subclass of RoomSpawner — rejected: premature abstraction (Principle V).

---

## Decision 5: RoomData — Resource (.tres) vs Plain String vs RefCounted

**Question**: Should `RoomData` be a `Resource` (`.tres`), a plain `String`, or a `RefCounted`
data class?

**Decision**: `RoomData extends Resource` — a typed Godot Resource with `@export` fields, saved
as `.tres` files in `res://data/rooms/`.

**Rationale**: A Resource carries both `room_type_id: String` and `scene: PackedScene` as
`@export` fields, making it editable in the Godot Inspector. This satisfies Principle II
(data-driven) and Principle IV (editor-centric). The `scene` field eliminates the factory's need
for any internal registry — it reads `room_data.scene` directly. Adding a new room type is a
pure editor task: create a new `.tres`, fill in the two fields, done. No code changes required.

**Alternatives considered**:
- Plain `String` (room_type_id only) — rejected: requires a code-level scene registry in
  RoomFactory; adding room types requires editing GDScript.
- `RefCounted` data class — rejected: not editable in the Inspector; cannot be saved as an asset;
  provides no editor-centric benefit over a plain string.

---

## Decision 6: RoomFactory Ownership — Autoload vs Owned by Caller

**Question**: Should RoomFactory be an autoload or a plain object instantiated by the caller?

**Decision**: `RoomFactory extends RefCounted` — instantiated and owned by `RunManager` as an instance
variable. Not an autoload.

**Rationale**: RoomFactory has no state that needs to survive beyond RunManager's lifetime, and no
system other than RunManager currently needs it. Constitution Principle I requires new autoloads to
be explicitly justified and not duplicate existing responsibility. RunManager already orchestrates the
run lifecycle — owning the factory that spawns rooms during a run is within that domain. A new autoload
would be premature.

**Alternatives considered**:
- Autoload — rejected: no multi-consumer requirement; would violate constitution's autoload justification
  requirement.
