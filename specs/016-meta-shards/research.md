# Research: Meta Currency — Shards

## Decision 1: MetaState save format

**Decision**: JSON file at `user://meta_save.json` via `FileAccess`.
**Rationale**: JSON is human-readable (debuggable), consistent with the project's existing data layer (all config files are JSON). Godot's `user://` path maps to a writable app-data directory on all target platforms (Android, Windows). The data is a single integer — no binary format overhead is justified.
**Alternatives considered**:
- `ConfigFile` (.ini-style): Works but adds unnecessary API surface for a single value.
- Binary file: Not debuggable; no performance advantage at this scale.
- `ResourceSaver` with `.tres`: Overkill; ties save data to the engine resource system unnecessarily.

---

## Decision 2: Conversion rate storage

**Decision**: `data/meta_config.json` with field `"shard_conversion_rate": 1.0`. Loaded via a new `ResourceManager.get_meta_config()` method following the existing `get_dungeon_config()` pattern.
**Rationale**: Constitution Principle II mandates that all game-balance values live in `res://data/` JSON files. The conversion rate is a balance parameter. ResourceManager already owns JSON loading; adding a method for `meta_config.json` is consistent with its existing `get_dungeon_config()` and enemy data loading.
**Alternatives considered**:
- Hardcode `1.0` as a GDScript constant: Violates Constitution Principle II.
- MetaManager reads JSON directly: Violates SRP — MetaManager should not own resource loading.

---

## Decision 3: SaveManager implementation scope

**Decision**: Implement only `save_meta_state(MetaState)` and `load_meta_state() -> MetaState` on SaveManager. No generic serialization layer.
**Rationale**: Constitution Principle V (YAGNI) prohibits speculative abstractions. Only MetaState needs persistence in this feature. A generic save system would be premature. SaveManager already exists as a stub autoload; this feature is the correct moment to give it its first real responsibility.
**Alternatives considered**:
- Generic `save(key, data)` API: No second concrete use case exists yet; deferred per YAGNI.
- A separate `MetaSaveManager` autoload: Would duplicate SaveManager's responsibility; violates Principle I.

---

## Decision 4: MetaManager connection timing

**Decision**: MetaManager connects to `RunManager.run_ended` in its own `_ready()`. It reads `RunManager.run_summary` (already populated before `run_ended` fires) to get `essence_cashed_out`.
**Rationale**: `RunManager.end_run()` populates `run_summary` before emitting `run_ended`, so the data is guaranteed available. No additional synchronization is needed. MetaManager remains passive — it reacts to RunManager's signal rather than being driven by RunManager directly, preserving separation of concerns.
**Alternatives considered**:
- RunManager calls MetaManager directly: Couples run management to meta-progression; violates SRP.
- MetaManager polls RunManager: Unnecessary complexity; Godot signals are the correct event mechanism.

---

## Decision 5: MetaState class placement

**Decision**: `scripts/data_models/MetaState.gd` — a `RefCounted` data class, parallel to `RunState.gd` in the same directory.
**Rationale**: Follows the established pattern for session/meta data classes (`RunState`, `PlayerState`, `RunSummary` are all `RefCounted` in `scripts/data_models/`). Not co-located with a scene (it has no scene); shared by MetaManager and SaveManager — qualifies for `scripts/`.
