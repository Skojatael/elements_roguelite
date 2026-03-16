# Gold Currency — Internal API Contract

**Feature**: 041-gold-idle-currency
**Date**: 2026-03-13

This is a GDScript internal API (no HTTP). Contracts describe the public surface of each modified/new script.

---

## MetaManager autoload — Gold API additions

```gdscript
# Emitted when the displayed (floor) gold value changes.
# Consumers: GoldDisplay
signal gold_changed(new_floor: int)

# Read-only access to raw float balance.
var total_gold: float  # get: _impl.meta_state.total_gold
```

**Guarantees**:
- `gold_changed` is emitted at most once per frame (when floor changes)
- `gold_changed` is emitted once during `_ready()` after offline credit is applied
- `total_gold` is always >= 0.0
- No write path exposed in this feature (display-only)

---

## MetaManagerImpl — Gold methods

```gdscript
# Called every _process() frame. Adds fractional gold. Returns new floor value.
# Caller compares return value to previous floor to decide whether to emit gold_changed.
func tick_gold(delta: float, rate_per_hour: float) -> int

# Called once at session start. Credits elapsed offline gold and saves.
# No-op if gold_last_saved_timestamp == 0 (new player) or elapsed <= 0 (clock rollback).
func apply_offline_gold(now_unix: int, rate_per_hour: float, save_manager: SaveManagerImpl) -> void
```

---

## SaveManagerImpl — Extended save/load contract

```gdscript
# save_meta_state writes all MetaState fields atomically, including:
#   "total_gold": float
#   "gold_last_saved_timestamp": int  ← always set to Time.get_unix_time_from_system() by MetaManagerImpl._save()
func save_meta_state(state: MetaState) -> void

# load_meta_state reads with backward-compatible defaults:
#   missing "total_gold" → 0.0
#   missing "gold_last_saved_timestamp" → 0
func load_meta_state() -> MetaState
```

---

## GoldDisplay — Scene interface

```gdscript
# Scene: scenes/hub/GoldDisplay.tscn
# Script: scenes/hub/GoldDisplay.gd

@export var _label: Label  # Assigned in Inspector

# _ready() behaviour:
#   - Sets label text to "Gold: {n}".format({"n": floori(MetaManager.total_gold)})
#   - Connects MetaManager.gold_changed -> updates label text
```

**Label format**: `"Gold: {n}"` where `{n}` is the integer floor of the internal balance.
