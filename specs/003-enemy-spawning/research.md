# Research: Enemy Spawning

**Feature**: 003-enemy-spawning
**Date**: 2026-02-20
**Status**: Complete — all decisions resolved

---

## Decision 1: Spawn configuration storage location

**Decision**: Extend `data/dungeon_config.json` with a `spawn_configs` section keyed by room type ID.

**Rationale**: `dungeon_config.json` already owns dungeon/room parameters; placing spawn data there keeps all room-related config co-located and avoids creating a separate file for a small schema. `enemies.json` is intentionally enemy-stat-only (Constitution Principle II: each JSON file owns one domain).

**Alternatives considered**:
- Separate `spawn_configs.json` — adds a file with no clear separation benefit at this scope.
- Inline in `.tscn` as exported arrays — violates Principle II (content in code, not data).

---

## Decision 2: Room entry detection mechanism

**Decision**: Each room scene contains a child `Area2D` named `EntryArea` sized to fill the walkable floor. Its `body_entered` signal fires when the player's `CharacterBody2D` enters, triggering spawn.

**Rationale**: `Area2D` entry detection is zero-cost at idle (no polling). The player already uses `CharacterBody2D` (Layer 1), so the trigger requires only an Area2D with Mask 1 — no new collision layers needed.

**Alternatives considered**:
- Signal from `RoomManager` on room transition — `RoomManager` is a stub and out of scope; coupling spawn to it adds a hard dependency on unimplemented infrastructure.
- `_process` distance check — polling every frame is wasteful on mobile (Principle III).

---

## Decision 3: Spawning logic location

**Decision**: A `RoomSpawner.gd` script is attached as a child node of each room scene (co-located under `scenes/dungeon/`). It owns: reading spawn config, instantiating enemies, tracking living count, and signalling cleared.

**Rationale**: Single Responsibility — one node, one job (Constitution Principle I). The room scene itself remains a passive container; `RoomSpawner` is the sole moving part. Scripts co-located with their scene family belong in `scenes/dungeon/`.

**Alternatives considered**:
- Logic in `RoomBase.gd` — merges entry detection, spawn, and tracking into one script, violating SRP.
- Global SpawnManager autoload — an autoload owning per-room state creates lifetime and ownership ambiguity; SRP assigns this to the room itself.

---

## Decision 4: Cleared state persistence across scene transitions

**Decision**: `RoomSpawner` calls `RunManager.mark_room_cleared(room_id)` when the living count reaches zero. `RunManager` owns the `cleared_rooms` dictionary for the current run (already the run-state singleton per CLAUDE.md). `is_room_cleared(room_id)` is queried on entry to skip spawning in cleared rooms.

**Rationale**: The spec assumption explicitly states "run-level persistence of cleared rooms is handled by an existing RunManager". `RunManager` already owns run-scoped state; adding cleared rooms is a natural extension of its existing domain, not a new domain (Principle I).

**Alternatives considered**:
- Store cleared flag on the room scene node — lost on scene reload/transition, breaking re-entry behaviour.
- New `ClearedRoomsManager` autoload — violates YAGNI (Principle V); one dictionary in `RunManager` is sufficient.

---

## Decision 5: Spawn position randomisation

**Decision**: At spawn time, offset the configured centre position by `Vector2(randf_range(-r, r), randf_range(-r, r))` where `r` is the `radius` field. No boundary clamping — designer responsibility per spec assumption.

**Rationale**: Simplest correct implementation (Principle V). The spec explicitly states boundary enforcement is a designer responsibility via data. A full navmesh query would be disproportionate overhead for radius values expected to be 0–100 units.

**Alternatives considered**:
- Random angle + distance (polar) — more uniform distribution but more complex; the spec acceptance scenario only requires positions to differ by ≥1 unit, which the simple approach satisfies.
- NavigationServer point clamping — out of scope; navmesh is not yet set up in the dungeon scenes.

---

## Decision 6: Enemy count enforcement

**Decision**: `RoomSpawner._ready()` asserts `spawn_points.size() <= 10` and pushes an error if the data violates FR-009. No enemies spawn if the config is invalid.

**Rationale**: Data validation at load time (as FR-009 requires) with a clear error message. `assert()` is intentionally development-only in Godot; `push_error()` + `return` is the correct production-safe approach.

**Alternatives considered**:
- Silent cap at 10 — hides designer data errors; spec requires "clear error".
- Validate in the data model constructor — equally valid, but `RoomSpawner` is the single consumer and owns the enforcement context.

---

## Decision 7: Enemy scene reference

**Decision**: `RoomSpawner` preloads `res://scenes/combat/enemies/Enemy.tscn` as a constant. Each enemy instance has `enemy_type_id` set from the spawn config before `_ready()` runs (set before `add_child`).

**Rationale**: `Enemy.tscn` is the single enemy scene established in `002-enemy-combat`; preloading avoids repeated disk hits for up to 10 instances. Setting `enemy_type_id` before `add_child` ensures `Enemy._ready()` has the correct ID when it runs.

**Alternatives considered**:
- Load per spawn — redundant IO on multi-enemy rooms.
- Separate scene per enemy type — violates YAGNI; `enemy_type_id` already parameterises the single scene.
