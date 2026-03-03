# Contracts: Adventurer Bag

**Feature**: 026-adventurer-bag
**Date**: 2026-03-03

---

## MetaState (scripts/data_models/MetaState.gd) — MODIFIED

One field added:

```gdscript
class_name MetaState
extends RefCounted

var total_shards: int = 0
var damage_upgrade_level: int = 0
var adventurer_bag_unlocked: bool = false   # NEW
```

---

## SaveManagerImpl (scripts/managers/SaveManager.gd) — MODIFIED

`save_meta_state` and `load_meta_state` updated to include the new field.

```gdscript
func save_meta_state(state: MetaState) -> void:
    var data: Dictionary = {
        "total_shards": state.total_shards,
        "damage_upgrade_level": state.damage_upgrade_level,
        "adventurer_bag_unlocked": state.adventurer_bag_unlocked,   # NEW
    }
    # ... rest unchanged

func load_meta_state() -> MetaState:
    # ... file read unchanged
    if parsed is Dictionary:
        state.total_shards = int((parsed as Dictionary).get("total_shards", 0))
        state.damage_upgrade_level = int((parsed as Dictionary).get("damage_upgrade_level", 0))
        state.adventurer_bag_unlocked = bool((parsed as Dictionary).get("adventurer_bag_unlocked", false))   # NEW
    return state
```

---

## MetaManagerImpl (scripts/managers/MetaManager.gd) — MODIFIED

One method added:

```gdscript
## Sets adventurer_bag_unlocked if not already set. Returns true if this call
## changed the state (first unlock), false if already unlocked.
func unlock_adventurer_bag(save_manager: Node) -> bool:
    if meta_state.adventurer_bag_unlocked:
        return false
    meta_state.adventurer_bag_unlocked = true
    save_manager.save_meta_state(meta_state)
    return true
```

---

## MetaManager autoload (autoload/MetaManager.gd) — MODIFIED

Added computed property and room_cleared handler:

```gdscript
## True if Adventurer Bag has been permanently unlocked.
var is_adventurer_bag_unlocked: bool:
    get: return _impl.meta_state.adventurer_bag_unlocked


func _ready() -> void:
    _impl.load(SaveManager)
    RunManager.run_ended.connect(func(r: RunManager.EndReason) -> void: _on_run_ended(r))
    RunManager.room_cleared.connect(_on_room_cleared)   # NEW


func _on_room_cleared(room_id: String) -> void:   # NEW
    if RunManager.current_room == null:
        return
    var room_type: String = (RunManager.current_room as RoomSpawner).room_type_id
    if not room_type.contains("Elite"):
        return
    var unlocked: bool = _impl.unlock_adventurer_bag(SaveManager)
    if unlocked:
        print("[MetaManager] Adventurer Bag unlocked — room_id={id}".format({"id": room_id}))
```

---

## RelicManager autoload (autoload/RelicManager.gd) — MODIFIED

Gate added at the top of `_on_room_cleared`:

```gdscript
func _on_room_cleared(room_id: String) -> void:
    if not MetaManager.is_adventurer_bag_unlocked:   # NEW gate
        return
    if not RunManager.is_run_active:
        return
    # ... rest unchanged
```

---

## All other methods — UNCHANGED

`MetaManagerImpl.add_shards()`, `spend()`, `can_spend()`, `purchase_damage_upgrade()`, `get_damage_multiplier()` — no changes.

`RelicManager._on_run_started()`, `_on_run_ended()`, `pick_relic()`, `get_stat_mult()`, `get_hit_damage_mult()`, `trigger_offer()` — no changes.
