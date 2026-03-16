# Data Model: Gold Idle Currency

**Feature**: 041-gold-idle-currency
**Date**: 2026-03-13

---

## Modified: MetaState (`scripts/data_models/MetaState.gd`)

Two new fields appended to the existing class:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `total_gold` | `float` | `0.0` | Accumulated gold balance (authoritative internal value; display uses floor) |
| `gold_last_saved_timestamp` | `int` | `0` | Unix timestamp (seconds) of the last save. `0` = no prior session; skip offline credit. |

**Invariants**:
- `total_gold >= 0.0` always. No deduction path exists in this feature (display-only).
- `gold_last_saved_timestamp` is always written together with `total_gold` in the same `save_meta_state()` call (atomic pair guarantee).

---

## Modified: SaveManagerImpl (`scripts/managers/SaveManager.gd`)

`save_meta_state` gains two new JSON keys; `load_meta_state` reads them with safe defaults.

**Save format addition** (appended to existing JSON object in `user://meta_save.json`):
```json
{
  "total_gold": 0.0,
  "gold_last_saved_timestamp": 0
}
```

**Load defaults** (backward-compatible):
- `total_gold`: defaults to `0.0` if key missing
- `gold_last_saved_timestamp`: defaults to `0` if key missing → new player gets no offline credit on first launch post-update

---

## Modified: MetaManagerImpl (`scripts/managers/MetaManager.gd`)

New methods:

### `tick_gold(delta: float, rate_per_hour: float) -> int`
- Adds `delta * rate_per_hour / 3600.0` to `meta_state.total_gold`
- Returns `floori(meta_state.total_gold)` for the caller to compare against previous floor
- Does NOT save (called every frame; save cadence governed by existing triggers)

### `apply_offline_gold(now_unix: int, rate_per_hour: float) -> void`
- Guard: if `meta_state.gold_last_saved_timestamp == 0` → return (new player)
- `elapsed_seconds = now_unix - meta_state.gold_last_saved_timestamp`
- Guard: if `elapsed_seconds <= 0` → return (clock rollback or same-instant reopen)
- `meta_state.total_gold += elapsed_seconds * rate_per_hour / 3600.0`
- Updates timestamp and saves via `_save(save_manager)` (passed as parameter)

### `_save(save_manager)` (private helper, replaces direct calls to `save_manager.save_meta_state`)
- Sets `meta_state.gold_last_saved_timestamp = int(Time.get_unix_time_from_system())`
- Calls `save_manager.save_meta_state(meta_state)`
- All existing save callsites in MetaManagerImpl are refactored to call `_save()` instead of `save_manager.save_meta_state()` directly

---

## Modified: MetaManager autoload (`autoload/MetaManager.gd`)

New signal and properties:

```
signal gold_changed(new_floor: int)

var total_gold: float        # computed: _impl.meta_state.total_gold
var _last_gold_floor: int    # private; tracks last emitted floor for change detection
```

New lifecycle:

### `_ready()` (addition after `_impl.load(SaveManager)`)
```
var rate: float = ResourceManager.get_meta_config().get("gold_rate_per_hour", 100.0)
_impl.apply_offline_gold(int(Time.get_unix_time_from_system()), rate, SaveManager)
_last_gold_floor = floori(meta_state.total_gold)
gold_changed.emit(_last_gold_floor)
```

### `_process(delta: float)`
```
var rate: float = ResourceManager.get_meta_config().get("gold_rate_per_hour", 100.0)
var new_floor: int = _impl.tick_gold(delta, rate)
if new_floor != _last_gold_floor:
    _last_gold_floor = new_floor
    gold_changed.emit(new_floor)
```

---

## New: GoldDisplay (`scenes/hub/GoldDisplay.gd`)

| Field | Type | Description |
|-------|------|-------------|
| `_label` | `Label` (export) | The hub UI label showing "Gold: N" |

Lifecycle:
- `_ready()`: set initial text from `floori(MetaManager.total_gold)`; connect `MetaManager.gold_changed` → update label
- No `_process()` needed — driven entirely by signal

---

## Config: `data/meta_config.json`

New top-level key:
```json
"gold_rate_per_hour": 100
```
