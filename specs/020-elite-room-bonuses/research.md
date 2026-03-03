# Research: Elite Room Bonuses

## Decision 1: Config location for multipliers — inside spawn_configs entry

**Decision**: Add `enemy_count_mult` and `essence_mult` directly to each room type's
entry in `dungeon_config.json → spawn_configs`. Both default to `1.0` when absent, so
all existing room types are backward compatible with no changes.

```json
"EliteRoom01": {
    "enemy_count_mult": 1.5,
    "essence_mult": 1.8,
    "spawn_points": [...]
}
```

**Rationale**: The multipliers are spawn-config-level properties — they govern the
behaviour of a specific room type's spawning context. Co-locating them with
`spawn_points` keeps all per-room-type balance in one place. A separate `room_bonuses`
section would require cross-referencing two config keys every time a room type is
tuned.

**Alternatives considered**:
- Separate top-level `room_bonuses` dict keyed by room_type_id: works but splits
  related config across two sections.
- Hardcode 1.5 and 1.8 as constants in GDScript: violates Principle II.

---

## Decision 2: Enemy count — cycle through base spawn_points for extras

**Decision**: In `RoomSpawner._spawn_enemies()`, compute total spawn count as
`floori(base_count * enemy_count_mult)` (capped at `MAX_ENEMIES = 10`). For indices
beyond the base list, cycle: `spawn_points[i % base_count]` to pick the enemy type and
radius. Position offset is still random within the radius.

**Rationale**: The spec requires extra enemies to be "of the same types already
configured for that elite room." Cycling via modulo is the simplest stateless approach —
no additional config needed. It naturally distributes extra enemies across the configured
types. With EliteRoom01 having 2 entries (slime at -80, skeleton at +80), index 2
reuses slime (i % 2 = 0), so the third enemy is another slime. This is deterministic
and testable.

**Alternatives considered**:
- Pick randomly from existing spawn_points: non-deterministic; harder to validate in
  quickstart scenarios.
- Add extra entries explicitly to spawn_points JSON: defeats the purpose of having a
  multiplier; redundant.

---

## Decision 3: Essence multiplier access — RoomSpawner exposes computed property

**Decision**: `RoomSpawnConfig` stores `essence_mult: float` (read from config).
`RoomSpawner` exposes a public computed property `essence_mult` that returns
`_config.essence_mult` (or `1.0` if config is null). `RunManager._on_enemy_defeated()`
reads `(current_room as RoomSpawner).essence_mult` and applies it after depth scaling.

**Rationale**: Consistent with how `difficulty_mult` is read by callers from the
spawner. RunManager already casts `current_room as RoomSpawner` in other methods. This
keeps RunManager decoupled from the config structure — it just reads a value from the
spawner that already owns the room type context. No new method is needed on RunManager.

**Alternatives considered**:
- RunManager looks up `spawn_configs → room_type_id → essence_mult` directly from
  dungeon_config: couples RunManager to the config schema; RunManager already has
  `current_room_depth` but not `room_type_id` as a direct field.
- Add `essence_mult` as `@export var` on RoomSpawner set by RoomLoader: RoomLoader
  doesn't know about essence; it only handles difficulty_mult (from DungeonGenerator
  data). Essence multiplier is spawn-config data, so RoomSpawner reads it from its
  own config (same pattern as spawn_points).

---

## Decision 4: MAX_ENEMIES cap applies to post-multiplier total

**Decision**: The existing `MAX_ENEMIES = 10` guard in `RoomSpawner._load_config()`
checks the base `spawn_points.size()`. In `_spawn_enemies()`, the computed `_living_count`
is additionally capped with `mini(_living_count, MAX_ENEMIES)` before spawning begins.

**Rationale**: Prevents a room configured with many base enemies from exceeding the cap
after multiplier application. For the current EliteRoom01 (2 base → 3 total), the cap
is never hit, but the invariant is maintained for future room configs.

**Alternatives considered**:
- Move the cap check entirely to `_spawn_enemies()`: loses early validation at config
  load time; preferable to keep both guards.
