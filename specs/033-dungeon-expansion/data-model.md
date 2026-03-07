# Data Model: Dungeon Expansion (033)

---

## MetaState.gd — new fields

| Field | Type | Default | Description |
|---|---|---|---|
| `first_boss_killed` | `bool` | `false` | Set permanently on first boss room clear. Triggers AdventuringGear availability. |
| `adventuring_gear_owned` | `bool` | `false` | Set permanently on purchase. Enables dungeon expansion in all subsequent runs. |

Persisted in `user://meta_save.json` alongside existing fields. Missing keys default to `false` (backward-compatible).

---

## data/meta_config.json — new key

```json
{
  "shard_divisor": 3,
  "adventuring_gear_cost": 300,
  "damage_upgrade": { ... }
}
```

`adventuring_gear_cost` is the only tuning parameter for this upgrade.

---

## data/dungeon_config.json — new key

```json
{
  "combat_room_pool": [ ... ],
  "spawn_configs": { ... },
  "difficulty_scale": 0.12,
  "base_room_count": 9,
  "expansion_room_count": 4
}
```

`base_room_count` is the total rooms generated in a base run (1 start room + 8 combat rooms with enemies). Replaces the hard-coded `TARGET_ROOM_COUNT` const in `DungeonGenerator.gd`. `expansion_room_count` controls how many rooms are added when Adventuring Gear is owned. Both are tunable without code changes.

---

## DungeonGenerator.gd — constants changed

| Constant | Old | New | Reason |
|---|---|---|---|
| `GRID_SIZE` | `5` | `13` | Must guarantee 4 expansion rooms from any depth-8 Room A |
| `CENTER` | `Vector2i(2, 2)` | `Vector2i(6, 6)` | Center of 13×13 grid |

Room IDs and world positions are computed from CENTER dynamically — no other code changes needed.

**Grid sizing rationale** (see research.md): With 9 base rooms (1 start + 8 combat), the maximum achievable depth of Room A is 8 (all rooms in a straight line). All depth-8 positions reachable in a 13×13 grid have at least 4 valid expansion cells via chaining, even when Room A is near the grid edge. An 11×11 grid is insufficient — the worst-case Room A at depth-8 boundary position (e.g. (0,2) in 11×11) yields only 3 reachable expansion cells.

Note: GRID_SIZE is a structural constant (determines room ID namespace and coordinate system) rather than a balance value. It is kept as a code constant rather than in JSON — changing it would invalidate all room IDs. Justified as an architectural decision.

---

## State Transitions

```
first_boss_killed: false → true   (on first boss room clear; never resets)
adventuring_gear_owned: false → true   (on purchase; never resets)
```

Both transitions are one-way and permanent. The `adventuring_gear_owned` transition only becomes possible after `first_boss_killed` is true.

---

## No changes to

- `relics.json`, `enemies.json`, `upgrades.json`, `skills.json` — unaffected
- `RunState`, `RunSummary`, `PlayerState` — unaffected
- `RelicManagerImpl`, `ResourceManagerImpl` — unaffected
