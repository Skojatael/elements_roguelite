# Contracts: Meta Currency — Shards

## MetaState

```gdscript
class_name MetaState
extends RefCounted

var total_shards: int = 0
```

---

## MetaManager (autoload)

```gdscript
# autoload/MetaManager.gd

var meta_state: MetaState          # Non-null at all times; loaded in _ready()

func _ready() -> void
    # Loads MetaState from SaveManager.
    # Connects RunManager.run_ended to _on_run_ended.

func _on_run_ended(_reason: RunManager.EndReason) -> void
    # Reads RunManager.run_summary.essence_cashed_out.
    # Computes shards_earned = essence_cashed_out / shard_divisor (integer division).
    # Increments meta_state.total_shards.
    # Calls SaveManager.save_meta_state(meta_state).
    # Prints: "[MetaManager] N shards earned — total=M"
```

---

## SaveManager (autoload)

```gdscript
# autoload/SaveManager.gd
# Save path: user://meta_save.json
# Format: { "total_shards": <int> }

func save_meta_state(state: MetaState) -> void
    # Serializes MetaState to JSON and writes to user://meta_save.json.
    # push_error on file open failure; does not crash.

func load_meta_state() -> MetaState
    # Reads user://meta_save.json.
    # Returns MetaState.new() (total_shards = 0) if file missing or malformed.
    # Never returns null.
```

---

## ResourceManager additions

```gdscript
# autoload/ResourceManager.gd

func get_meta_config() -> Dictionary
    # Returns parsed contents of data/meta_config.json, cached after first load.
    # Guaranteed to contain "shard_divisor": int.
```

---

## Invariants

- `MetaManager.meta_state` is non-null at all times after `_ready()`.
- `total_shards` never decreases within this feature.
- `shards_earned` per run is always `>= 0`.
- `SaveManager.load_meta_state()` never returns null.
- `RunManager.run_summary` is non-null when `run_ended` fires (guaranteed by RunManager.end_run() order).
