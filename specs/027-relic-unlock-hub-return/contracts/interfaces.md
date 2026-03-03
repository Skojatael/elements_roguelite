# Contracts: Relic Offers Activate on Hub Return

**Feature**: 027-relic-unlock-hub-return
**Date**: 2026-03-03

---

## MetaState (scripts/data_models/MetaState.gd) — MODIFIED

```gdscript
class_name MetaState
extends RefCounted

var total_shards: int = 0
var damage_upgrade_level: int = 0
var adventurer_bag_unlocked: bool = false
var relic_offers_active: bool = false   # NEW
```

---

## SaveManagerImpl (scripts/managers/SaveManager.gd) — MODIFIED

```gdscript
func save_meta_state(state: MetaState) -> void:
    var data: Dictionary = {
        "total_shards": state.total_shards,
        "damage_upgrade_level": state.damage_upgrade_level,
        "adventurer_bag_unlocked": state.adventurer_bag_unlocked,
        "relic_offers_active": state.relic_offers_active,   # NEW
    }
    # ... rest unchanged

func load_meta_state() -> MetaState:
    # ... file read unchanged
    if parsed is Dictionary:
        state.total_shards = int((parsed as Dictionary).get("total_shards", 0))
        state.damage_upgrade_level = int((parsed as Dictionary).get("damage_upgrade_level", 0))
        state.adventurer_bag_unlocked = bool((parsed as Dictionary).get("adventurer_bag_unlocked", false))
        state.relic_offers_active = bool((parsed as Dictionary).get("relic_offers_active", false))   # NEW
    return state
```

---

## MetaManagerImpl (scripts/managers/MetaManager.gd) — MODIFIED

```gdscript
## Activates relic offers if the Adventurer Bag is unlocked and offers are not yet active.
## Returns true if this call changed the state (first activation), false otherwise.
func try_activate_relic_offers(save_manager: Node) -> bool:
    if not meta_state.adventurer_bag_unlocked:
        return false
    if meta_state.relic_offers_active:
        return false
    meta_state.relic_offers_active = true
    save_manager.save_meta_state(meta_state)
    return true
```

---

## GlobalSignals (autoload/GlobalSignals.gd) — MODIFIED

```gdscript
## Emitted by Main.gd whenever the HubRoom is instantiated and the player is in the hub.
## Fires at game start and each time the player returns from a run.
@warning_ignore("unused_signal")
signal hub_entered()
```

---

## MetaManager autoload (autoload/MetaManager.gd) — MODIFIED

```gdscript
var is_relic_offers_active: bool:
    get: return _impl.meta_state.relic_offers_active


func _ready() -> void:
    _impl.load(SaveManager)
    RunManager.run_ended.connect(func(r: RunManager.EndReason) -> void: _on_run_ended(r))
    RunManager.room_cleared.connect(_on_room_cleared)
    GlobalSignals.hub_entered.connect(_on_hub_entered)   # NEW


func _on_hub_entered() -> void:   # NEW
    var activated: bool = _impl.try_activate_relic_offers(SaveManager)
    if activated:
        print("[MetaManager] relic offers activated — first hub return after Adventurer Bag unlock")
```

---

## Main.gd (scenes/core/Main.gd) — MODIFIED

Emit `hub_entered` wherever HubRoom is instantiated:

```gdscript
func _ready() -> void:
    # ... existing setup ...
    _hub_room = _HUB_ROOM_SCENE.instantiate()
    add_child(_hub_room)
    _hub_room.hub_exited.connect(_on_hub_exited)
    GlobalSignals.hub_entered.emit()   # NEW — initial hub at game start
    # ...

func _on_results_return() -> void:
    # ... existing cleanup ...
    _hub_room = _HUB_ROOM_SCENE.instantiate()
    add_child(_hub_room)
    _hub_room.hub_exited.connect(_on_hub_exited)
    GlobalSignals.hub_entered.emit()   # NEW — return to hub after run
    # ... rest unchanged
```

---

## RelicManager autoload (autoload/RelicManager.gd) — MODIFIED

Gate changed from `is_adventurer_bag_unlocked` to `is_relic_offers_active`:

```gdscript
func _on_room_cleared(room_id: String) -> void:
    if not MetaManager.is_relic_offers_active:   # CHANGED (was is_adventurer_bag_unlocked)
        return
    # ... rest unchanged
```

---

## All other methods — UNCHANGED

`MetaManager._on_room_cleared()` (feature-026 elite detection), `MetaManagerImpl.unlock_adventurer_bag()` — no changes.
