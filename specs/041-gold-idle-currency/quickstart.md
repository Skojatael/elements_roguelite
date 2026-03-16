# Quickstart: Gold Idle Currency

**Feature**: 041-gold-idle-currency
**Date**: 2026-03-13

A developer guide for implementing this feature end-to-end.

---

## Implementation order

Follow this order to avoid broken references at each step:

1. **JSON first** — Add `gold_rate_per_hour` to `data/meta_config.json`
2. **Data model** — Extend `MetaState` with the two new fields
3. **Persistence** — Extend `SaveManagerImpl` save/load to include the new fields
4. **Logic** — Add `tick_gold`, `apply_offline_gold`, `_save` helper to `MetaManagerImpl`
5. **Autoload wiring** — Add `gold_changed` signal, `total_gold` property, `_process`, and `_ready` additions to `MetaManager`
6. **Scene** — Create `GoldDisplay.tscn` + `GoldDisplay.gd` in the Godot Editor; place it in `HubRoom.tscn` near `ShardDisplay`
7. **Validate** — Manual smoke tests per acceptance scenarios

---

## Step 1 — `data/meta_config.json`

Add at the top level:
```json
"gold_rate_per_hour": 100
```

---

## Step 2 — `scripts/data_models/MetaState.gd`

Append two fields:
```gdscript
var total_gold: float = 0.0
var gold_last_saved_timestamp: int = 0
```

---

## Step 3 — `scripts/managers/SaveManager.gd` (SaveManagerImpl)

In `save_meta_state`, add to the data dictionary:
```gdscript
"total_gold": state.total_gold,
"gold_last_saved_timestamp": state.gold_last_saved_timestamp,
```

In `load_meta_state`, after existing field reads:
```gdscript
state.total_gold = float((parsed as Dictionary).get("total_gold", 0.0))
state.gold_last_saved_timestamp = int((parsed as Dictionary).get("gold_last_saved_timestamp", 0))
```

---

## Step 4 — `scripts/managers/MetaManager.gd` (MetaManagerImpl)

**Add `_save` helper** — refactor all existing `save_manager.save_meta_state(meta_state)` callsites to route through this:
```gdscript
func _save(save_manager: SaveManagerImpl) -> void:
	meta_state.gold_last_saved_timestamp = int(Time.get_unix_time_from_system())
	save_manager.save_meta_state(meta_state)
```

**Add `tick_gold`**:
```gdscript
func tick_gold(delta: float, rate_per_hour: float) -> int:
	meta_state.total_gold += delta * rate_per_hour / 3600.0
	return floori(meta_state.total_gold)
```

**Add `apply_offline_gold`**:
```gdscript
func apply_offline_gold(now_unix: int, rate_per_hour: float, save_manager: SaveManagerImpl) -> void:
	if meta_state.gold_last_saved_timestamp == 0:
		return
	var elapsed: int = now_unix - meta_state.gold_last_saved_timestamp
	if elapsed <= 0:
		return
	meta_state.total_gold += float(elapsed) * rate_per_hour / 3600.0
	_save(save_manager)
```

---

## Step 5 — `autoload/MetaManager.gd`

Add signal and property:
```gdscript
signal gold_changed(new_floor: int)

var total_gold: float:
	get: return _impl.meta_state.total_gold

var _last_gold_floor: int = 0
```

Extend `_ready()` (after `_impl.load(SaveManager)`):
```gdscript
var _gold_rate: float:
	get: return ResourceManager.get_meta_config().get("gold_rate_per_hour", 100.0)
```
Add to `_ready()` body:
```gdscript
_impl.apply_offline_gold(int(Time.get_unix_time_from_system()), _gold_rate, SaveManager._impl)
_last_gold_floor = floori(meta_state.total_gold)
gold_changed.emit(_last_gold_floor)
```

Add `_process`:
```gdscript
func _process(delta: float) -> void:
	var new_floor: int = _impl.tick_gold(delta, _gold_rate)
	if new_floor == _last_gold_floor:
		return
	_last_gold_floor = new_floor
	gold_changed.emit(new_floor)
```

---

## Step 6 — Editor tasks

1. Create `scenes/hub/GoldDisplay.tscn` — root node: `Control`. Attach `GoldDisplay.gd`.
2. Add a `Label` child node. Assign it to `_label` export in Inspector.
3. In `HubRoom.tscn`, add `GoldDisplay` as a sibling of `ShardDisplay` (position it directly above or below in the hub UI).
4. No signals need to be wired in the Editor — `GoldDisplay._ready()` connects programmatically.

---

## Validation checklist

- [ ] Launch fresh game (no save file): gold label shows "Gold: 0"
- [ ] Watch hub for 36 seconds: label increments by at least 1
- [ ] Set `gold_rate_per_hour` to 3600 in JSON (1 gold/sec), watch hub: label increments every second. Revert after test.
- [ ] Close game, wait 1 minute, reopen: gold increased by ~1.67 (at rate 100/hr)
- [ ] Manually edit save file: set `gold_last_saved_timestamp` to a past Unix time → verify credit on launch
- [ ] Manually set `gold_last_saved_timestamp` to a future time → verify 0 gold awarded (clock rollback guard)
- [ ] Verify `total_gold` and `gold_last_saved_timestamp` are both present in `user://meta_save.json` after any shard purchase
