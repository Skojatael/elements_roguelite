# Data Model: Hub Shard Display

## Data consumed (read-only)

| Source                             | Field                | Type  | Description                        |
|------------------------------------|----------------------|-------|------------------------------------|
| `MetaManager.meta_state`           | `total_shards`       | `int` | Cumulative shards earned to date.  |

No new data entities introduced. The display reads `MetaManager.meta_state.total_shards` directly
in `_ready()`. MetaManager is an autoload; no additional wiring is required.

---

## Display format

```
Shards: {total_shards}
```

Example: `"Shards: 42"` — formatted via `String.format()` with named key.

---

## New scene components

| Node path (inside HubRoom.tscn) | Type         | Script             |
|---------------------------------|--------------|--------------------|
| `ShardDisplayLayer`             | `CanvasLayer`| —                  |
| `ShardDisplayLayer/ShardDisplay`| `Control`    | `ShardDisplay.gd`  |
| `ShardDisplayLayer/ShardDisplay/Label` | `Label` | — (export target) |

`ShardDisplay.gd` is a co-located component script (used exclusively inside `HubRoom.tscn`).
No standalone `.tscn` file is created for it.
