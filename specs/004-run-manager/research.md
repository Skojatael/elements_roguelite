# Research: Run Manager

**Feature**: 004-run-manager
**Date**: 2026-02-21
**Status**: Complete — no NEEDS CLARIFICATION markers in spec

---

## Decision 1: RoomSpawner ↔ RunManager Wiring

**Question**: How does RunManager receive room entry and room cleared events, given that RoomSpawner nodes are instantiated dynamically per scene?

**Decision**: Pull-registration pattern. RoomSpawner calls `RunManager.register_room(self)` in its `_ready()`. RunManager connects to the spawner's `room_entered` and `room_cleared` signals at that point.

**Rationale**: Avoids polling/group scanning. Works correctly with dynamic scene instantiation — the moment a room enters the scene tree, it self-registers. No scene-tree traversal needed on RunManager's side.

**Alternatives considered**:
- _Group scan_: RunManager scans the `"room_spawner"` group each frame — rejected, unnecessary per-frame work.
- _GlobalSignals bus_: Route room events through a central bus — rejected, adds indirection without benefit at this scale.
- _Main.gd wires them_: Main manually connects RunManager to each spawner — rejected, violates SRP (Main would absorb wiring responsibility).

---

## Decision 2: run_id Generation

**Question**: How to generate a unique temporary run identifier in GDScript without external libraries?

**Decision**: `str(Time.get_ticks_msec())` — millisecond engine tick counter as a string.

**Rationale**: Guaranteed unique within a single session (monotonically increasing). Fast, zero dependencies. Meets the spec requirement: "temporary in-memory identifier, not globally unique across devices."

**Alternatives considered**:
- `str(Time.get_unix_time_from_system())` — unix timestamp: rejected, second-level precision means two runs starting within the same second get the same ID.
- UUID library — rejected, external dependency, overkill for a temporary local ID.

---

## Decision 3: current_room Type

**Question**: What type should `current_room` use — room root (Node2D), RoomSpawner (Node), or String room_id?

**Decision**: `RoomSpawner` — store a direct reference to the RoomSpawner node.

**Rationale**: RunManager is already connected to the RoomSpawner instance via `register_room`. Storing the reference avoids a secondary lookup. Callers that need the room_id can read `current_room.room_id`. Type declared as `Node` to avoid a circular preload dependency; runtime type is always `RoomSpawner`.

**Alternatives considered**:
- `Node2D` room root — rejected, requires get_parent() traversal from RunManager to reach spawner.
- `String room_id` only — rejected, loses reference to the node itself, makes future room queries harder.

---

## Decision 4: DifficultyService and RewardsService Placement

**Question**: Where do the service stubs live — inner classes in RunManager, companion scripts, or autoloads?

**Decision**: Separate `.gd` files in `res://scripts/services/` with `class_name`. Instantiated once in `RunManager._ready()` and held as typed vars (`difficulty_service`, `rewards_service`). Callers access via `RunManager.difficulty_service.get_multiplier()`.

**Rationale**:
- Separate files satisfy SRP — each file has one responsibility.
- Not autoloads — services don't need global singleton lifecycle; they're owned by RunManager.
- Instance-based (not static functions) — future real implementations will need access to run state (`current_tier`, `current_room_index`), which requires an instance that can hold a reference to RunManager.
- `res://scripts/services/` qualifies under the constitution's shared-scripts rule: both services are used by RunManager (autoload) and may be queried by HUD or other systems via `RunManager.difficulty_service`.

**Alternatives considered**:
- Inner classes in RunManager.gd — rejected, bloats the file; reduces independent replaceability.
- Static functions — rejected, can't hold state for future real implementations.
- Separate autoloads — rejected, constitution prohibits new autoloads that duplicate an existing autoload's domain.

---

## Decision 5: room_entered Signal Addition to RoomSpawner

**Question**: When exactly should `room_entered` be emitted — on any body entry, or only after all guards pass?

**Decision**: Emit `room_entered` after all guard checks pass (player group confirmed, not already cleared, not already spawned). Emit immediately before calling `_spawn_enemies()`.

**Rationale**: RunManager only cares about the player entering — emitting on every body entry would fire on enemy-to-area collisions too. Guards ensure the signal is semantically meaningful.

---

## Decision 6: YAGNI Gate — Stubs

**Question**: Do DifficultyService and RewardsService stubs violate the constitution's prohibition on "stub scripts acting as future hooks"?

**Decision**: No violation — justified exception.

**Rationale**: The constitution prohibits placeholder nodes/scripts that exist only to be replaced. These stubs are different: they define a **callable interface** that other systems reference today. `DifficultyService.get_multiplier()` returns a real value (1.0) that callers use. The stub IS the implementation for this feature. Real game logic (tier-based scaling) is a future feature; the interface is a present deliverable explicitly requested in the spec.
