# Research: Dungeon Grid Layout (008)

**Date**: 2026-02-24
**Feature**: [spec.md](spec.md)

---

## Decision 1 — Grid Internal Representation

**Decision**: `Dictionary[Vector2i → String]` mapping grid coords to `room_id`.

**Rationale**: GDScript's `Dictionary` provides O(1) membership test (`occupied.has(cell)`) which is needed on every frontier expansion step. `Vector2i` is the idiomatic integer coordinate type in Godot 4 and hashes correctly as a Dictionary key. A flat 2D Array would require bounds indexing and carry 17 always-empty slots alongside 8 occupied ones; the Dictionary only stores what exists.

**Alternatives considered**:
- `Array[Array]` (2D): sequential access is simple but `has()` requires two index lookups and doesn't express "sparse occupied set" as cleanly.
- `Array[Vector2i]` (list): requires linear scan for membership; fine at 8 elements but less expressive.

---

## Decision 2 — Frontier Data Structure

**Decision**: `Array[Vector2i]` — pick a random index with `randi() % frontier.size()`, then remove it via `frontier.remove_at(idx)`.

**Rationale**: The frontier never grows beyond ~16 cells on a 5×5 grid with 8 rooms. A plain Array is the lowest-friction GDScript collection for this size. Random index selection is O(1); `remove_at` is O(n) but n ≤ 16, negligible.

**Alternatives considered**:
- `Dictionary[Vector2i → bool]`: O(1) remove but random selection requires converting keys to Array first — more code, no win at this scale.
- Shuffle + pop: shuffling the entire frontier on every step is wasteful; single random pick is cleaner.

---

## Decision 3 — Random Selection from Pool

**Decision**: `pool.pick_random()` (Godot 4 built-in) to pick a random type ID from `combat_room_pool`.

**Rationale**: Built-in GDScript method, readable and idiomatic. No seeding required for gameplay randomness. `randi() % pool.size()` is equivalent if `pick_random()` is unavailable but less expressive.

**Alternatives considered**:
- Weighted random: not required by spec (uniform distribution specified in FR-006).
- Pre-shuffle + sequential pick: adds statefulness with no user-visible benefit.

---

## Decision 4 — World Position Formula

**Decision**: `Vector2((col - 2) * SPACING_X, (row - 2) * SPACING_Y)` where `SPACING_X = 2000`, `SPACING_Y = 1200`.

**Rationale**: Center cell (2, 2) maps to (0, 0) per the spec Assumptions. Subtracting 2 from each axis offsets the grid so the center is at the origin. SPACING_X = 1920 (room width) + 80 (gap) = 2000. SPACING_Y = 1080 (room height) + 120 (gap) = 1200.

**Alternatives considered**:
- Computing origin as `Vector2(-2 * SPACING_X, -2 * SPACING_Y)` and adding `col * SPACING_X` etc.: mathematically equivalent, slightly less readable.

---

## Decision 5 — Re-Run Handling

**Decision**: `rooms_by_id`, `neighbours_by_id`, and `start_room_id` are cleared and rebuilt at the start of each `_generate()` call. No scene cleanup needed.

**Rationale**: Because generation produces only data (no scenes), there is nothing to free on re-run — the previous data is simply overwritten. This is simpler and more correct than the previous approach (tracking `_spawned_rooms: Array[Node]` and calling `free()`), which no longer applies.

**Alternatives considered**:
- Append-only with run-ID tagging: more complex, no benefit at 8 rooms.

---

## Decision 6 — Config Key: `combat_room_pool`

**Decision**: Replace `"room_sequence"` with `"combat_room_pool"` in `dungeon_config.json`. Value is an Array of CombatRoom* type IDs (e.g. `["CombatRoom01", "CombatRoom02"]`).

**Rationale**: `room_sequence` implied an ordered list; the new algorithm picks randomly from an unordered pool. Renaming the key makes the data structure's intent clear. EliteRoom and BossRoom are excluded from the pool per FR-012 and spec Assumptions.

**Alternatives considered**:
- Reuse `room_sequence` with a different interpretation: would confuse future readers and violate Data-Driven Content principle (schema should express intent).

---

## Decision 7 — Room ID Encoding

**Decision**: `"room_{col}_{row}"` (e.g. `"room_2_2"` for center). Unique per grid cell; encodes position for future map/minimap features.

**Rationale**: FR-008 mandates this format. Using col/row (0–4) in the ID makes it trivially reversible — a future system can decode position from the ID without additional metadata.

**Alternatives considered**:
- Sequential `"room_0"`, `"room_1"`: simpler but discards grid position; used in 007 — superseded here.

---

## Decision 8 — `DungeonGenerator` Responsibilities (SRP check)

**Decision**: `DungeonGenerator.gd` owns:
1. Reading `combat_room_pool` from config
2. Running the frontier expansion algorithm
3. Recording room data into `rooms_by_id` and `neighbours_by_id`
4. Placing the player at the center room world position

It does NOT own: scene loading, room factory logic, enemy spawning, run session state. All four stay in their respective owners.

**Rationale**: Constitution Principle I (Single Responsibility). All four responsibilities relate to "computing the dungeon layout at run start". Scene loading and enemy spawning are concerns of the scene-loading system; run state is RunManager's domain.

---

## Decision 9 — No New Data Model Script Required

**Decision**: No new GDScript class is needed to hold the output. `rooms_by_id` and `neighbours_by_id` are plain `Dictionary` properties on `DungeonGenerator`. A typed `DungeonLayout` resource would add a new file with no current second call site — YAGNI (Constitution Principle V).

**Rationale**: The output is consumed by one future scene-loading system. Until that system exists as a concrete second consumer, a typed wrapper is premature. If/when two independent systems need typed layout access, introduce `DungeonLayout` then.

**Alternatives considered**:
- `DungeonLayout` resource with `occupied_cells: Dictionary`: justified when a second consumer exists; premature here.

---

## Decision 10 — Room-at-a-Time Principle (No Scene Loading in Generator)

**Decision**: `DungeonGenerator._generate()` MUST NOT call `RunManager.spawn_room()`, `RoomFactory.spawn_room()`, or `load()` for any scene. The generator is a pure data computation step.

**Rationale**: Separating layout data from scene instantiation enables lazy loading — rooms can be created in the scene tree only when the player is about to enter them, keeping memory and initial load time minimal on mobile. It also makes the generator independently testable: its output can be verified by inspecting three Dictionary/String properties without any scene being loaded. Scene loading is a separate concern that reads `rooms_by_id` and is out of scope for this feature.

**Alternatives considered**:
- Spawn scenes during generation (previous plan): simpler for the first implementation but conflates data and presentation. Adding lazy loading later would require a larger refactor. Implementing the separation from the start costs nothing and keeps options open.
- Spawn only the start room during generation: partial coupling — generator would need to know about the scene-loading system. Rejected in favour of clean separation.
