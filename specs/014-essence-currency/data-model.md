# Data Model: Essence Currency

**Feature**: 014-essence-currency
**Date**: 2026-02-28

---

## Modified Entities

### EnemyData (`scripts/data_models/EnemyData.gd`)

New field:

| Field | Type | Source | Default | Description |
|---|---|---|---|---|
| `base_essence` | `float` | `enemies.json` | `0.0` | Essence awarded for killing this enemy type at depth 0 |

`from_dict()` reads `base_essence` with `.get("base_essence", 0.0)` — missing key
silently defaults to 0.0 (no assert, FR-008).

---

### RoomSpawner (`scripts/dungeon/RoomSpawner.gd`)

New field:

| Field | Type | Set by | Default | Description |
|---|---|---|---|---|
| `depth` | `int` | RoomLoader | `0` | Grid depth of this room (Manhattan distance from start). Reported via `enemy_defeated` signal context. |

Set by RoomLoader immediately after `spawn_room()` returns, alongside `difficulty_mult`.

New signal: `enemy_defeated(enemy_type_id: String)` — emitted per kill. Carries only the type; no stats or currency data.

---

### RunManager (`scripts/managers/RunManager.gd`)

New session field:

| Field | Type | Reset in | Description |
|---|---|---|---|
| `current_room_depth` | `int` | `start_run()` | Depth of the currently active room. Cached from `(spawner as RoomSpawner).depth` in `_on_room_entered()`. |

---

## Data File Changes

### `data/enemies.json`

Each enemy entry gains a `base_essence` field:

```json
{
  "enemies": [
    {
      "id": "slime",
      "base_essence": 2,
      ...
    },
    {
      "id": "skeleton",
      "base_essence": 3,
      ...
    }
  ]
}
```

`base_essence` values chosen relative to combat difficulty:
- Slime (low health, slow): 2
- Skeleton (low health, faster, higher damage): 3

---

## Behaviour Changes

### RunManager (`scripts/managers/RunManager.gd`) — `end_run()`

Existing `run_currency: float` field is already in place. Cash-out logic added to
`end_run()`:

| End Reason | Cash-out Amount | Formula |
|---|---|---|
| `CASH_OUT` | Full amount | `floori(run_currency)` |
| `DIED` | 85% penalty | `floori(run_currency * 0.85)` |

Message printed: `"[Essence] {amount} essence cashed out"` in both cases.

`run_currency` is already reset to `0.0` by `start_run()` — no additional reset needed.

---

## No New Entities

No new GDScript classes, scenes, autoloads, or resources are required. All changes
are field additions to existing entities and logic additions to existing methods.
