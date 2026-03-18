# Research: Room Wave System

## Overview

All decisions are resolved from reading the live codebase. No external research needed.

---

## Decision 1: Where does wave logic live?

**Decision**: Extend `RoomSpawner.gd` directly. Replace `_spawn_enemies()` with a wave-aware `_spawn_wave(wave_idx)` and add wave state fields (`_wave_index`, `_living_count`, `_total_killed`, `_total_enemies`).

**Rationale**: `RoomSpawner` already owns the full spawn lifecycle — `_on_player_entered`, `_spawn_enemies`, `_on_enemy_defeated`, room-clear signal. Wave progression is a natural extension of that responsibility. Creating a separate `WaveControllerImpl` for 3 waves of a small fixed sequence would be premature abstraction (Constitution V). The logic is simple enough to live in the spawner itself.

**Alternatives considered**:
- Separate `WaveController.gd` attached to room scene — rejected; requires scene changes (editor work) and adds indirection for logic that naturally belongs to the spawner.
- `WaveControllerImpl` (Impl pattern) — rejected; the wave logic involves Node calls (scene tree traversal for player position) and scene-lifecycle coupling that makes it non-extractable as pure logic without autoload dependencies anyway.

---

## Decision 2: Where does wave config live in the data layer?

**Decision**: Add a top-level `"wave_config"` key to `dungeon_config.json`. Wrap it in a new `WaveConfig` data model at `scripts/data_models/WaveConfig.gd`. Add a `wave_config: WaveConfig` field to `RoomSpawnConfig`. `RoomSpawner._load_config()` reads the global wave config from the dungeon config and injects it into the `RoomSpawnConfig` after calling `from_dict()`.

**Rationale**: Wave config is global (same for all combat rooms per spec). Embedding it per-room in `spawn_configs` would require duplicating it across CombatRoom01, CombatRoom02, EliteRoom01 entries. Top-level placement is DRY and correctly models the "global default" semantic. Constitution II requires a typed data model wrapper.

**JSON shape**:
```json
"wave_config": {
  "waves": [3, 2, 1],
  "trigger_threshold": 1,
  "alive_cap": 4,
  "min_spawn_distance": 200.0
}
```

**Alternatives considered**:
- Per-room wave config override — deferred (out of scope per spec; can be added later by overriding the global default in individual spawn_configs entries).
- Hardcoded constants in `RoomSpawner` — rejected; violates Constitution II.

---

## Decision 3: How to select spawn positions with player distance filtering?

**Decision**: At `_spawn_wave()` time, sort `_config.spawn_points` by descending distance from the player (using base position, before radius randomisation). Pick the first N entries for the wave. Apply the normal radius offset after selection.

**Rationale**: Simple, zero-overhead for small arrays (combat rooms have 4 spawn points). Farthest-first guarantees enemies start away from the player. Radius randomisation (≤30px) is negligible relative to the 200px safe distance. No complex fallback needed — if all points are within safe distance (player is at a corner), farthest-first still picks the least-bad option.

**Alternatives considered**:
- Filter out all unsafe points and only spawn if safe — rejected; if player covers all points, spawning is suppressed entirely, breaking the wave count (SC-001 would fail).
- Re-roll position until safe — rejected; could infinite-loop if room is small or player covers all positions.

---

## Decision 4: Spawn point counts in dungeon_config.json

**Current problem**: `CombatRoom01` has 2 spawn points; `CombatRoom02` has 1. Wave 1 requires spawning 3 enemies simultaneously.

**Decision**: Expand to 4 spawn points per combat room, spread across the room quadrants. 4 points supports wave 1 (3 enemies, picks 3 of 4 farthest from player) and provides variety. EliteRoom01 keeps its 2 points — the wave system cycles `i % pool_size` for pools smaller than the wave size.

**New CombatRoom01 spawn points** (positions relative to room center, within ±800 horizontal, ±400 vertical):
- `(-350, -250)`, `(350, -250)`, `(-350, 250)`, `(350, 250)` — four corners, radius 40

**New CombatRoom02 spawn points**:
- `(-300, 0)`, `(300, 0)`, `(0, -250)`, `(0, 250)` — cardinal positions, radius 30

---

## Decision 5: Room-clear condition change

**Current**: `_living_count` starts at total spawn count; room clears when `_living_count == 0`.
**New**: `_living_count` tracks only currently alive enemies (incremented on spawn, decremented on defeat). `_total_killed` tracks cumulative deaths. Room clears when `_total_killed == _total_enemies` (where `_total_enemies = sum(waves) = 6`).

This is a direct replacement — the signal path (`room_cleared.emit`, `RunManager.mark_room_cleared`) is unchanged.
