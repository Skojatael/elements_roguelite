# Contracts: Hub Shard Display

## ShardDisplay (`scenes/hub/ShardDisplay.gd`)

```gdscript
# Co-located component script — attached to Control node inside HubRoom.tscn.
# No class_name required (not referenced from outside HubRoom.tscn).
extends Control

@export var _label: Label   # Assigned in Inspector to the Label child node.

func _ready() -> void
    # Reads MetaManager.meta_state.total_shards.
    # Sets _label.text = "Shards: {n}".format({"n": total_shards}).
    # No other logic.
```

---

## Invariants

- `_label` is always non-null at runtime (assigned via Inspector; assertion acceptable in debug).
- Displayed value equals `MetaManager.meta_state.total_shards` at the moment `_ready()` fires.
- No methods exposed — display is entirely internal to the component.
- ShardDisplay is freed automatically when HubRoom is freed; no cleanup needed.
