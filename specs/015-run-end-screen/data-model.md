# Data Model: Run End Screen

## RunSummary

**File**: `scripts/data_models/RunSummary.gd`
**Type**: `RefCounted`
**Lifecycle**: Created once in `RunManager.end_run()` before scene teardown. Stored on `RunManager.run_summary`. Immutable after creation. Replaced on the next `end_run()` call.

### Fields

| Field | Type | Description |
|---|---|---|
| `essence_cashed_out` | `int` | Final essence awarded (post-penalty). `floori(run_currency)` on CASH_OUT; `floori(run_currency * 0.85)` on DIED. |
| `enemies_slain` | `int` | Total enemies defeated during the run. Copied from `RunManager.enemies_slain`. |
| `rooms_cleared` | `int` | Number of distinct rooms cleared. Copied from `RunManager.cleared_rooms.size()`. |
| `end_reason` | `RunManager.EndReason` | The reason the run ended. Determines penalty display. |

### Factory method

```
static func create(
    essence: int,
    enemies: int,
    rooms: int,
    reason: RunManager.EndReason
) -> RunSummary
```

---

## RunManager — new / modified fields

| Field | Type | Change | Description |
|---|---|---|---|
| `enemies_slain` | `int` | **New** | Count of enemies defeated this run. Reset in `start_run()`. Incremented in `_on_enemy_defeated()`. |
| `run_summary` | `RunSummary` | **New** | Last completed run's summary snapshot. `null` before first run ends. Written in `end_run()`; readable until next `end_run()`. |

---

## ResultsScreen — no persistent data

ResultsScreen holds no state beyond what it receives via `setup()`. It reads from the `RunSummary` snapshot and displays it. It emits one signal (`return_pressed`) and is freed when the player returns.

---

## Existing fields used (read-only by this feature)

| Source | Field | Used for |
|---|---|---|
| `RunManager` | `cleared_rooms: Dictionary` | `cleared_rooms.size()` → `RunSummary.rooms_cleared` |
| `RunManager` | `run_currency: float` | Cash-out computation → `RunSummary.essence_cashed_out` |
| `RunManager` | `enemies_slain: int` | Copied into `RunSummary.enemies_slain` |
