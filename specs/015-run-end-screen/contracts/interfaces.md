# Contracts & Interfaces: Run End Screen

## New: RunSummary (`scripts/data_models/RunSummary.gd`)

```gdscript
class_name RunSummary
extends RefCounted

var essence_cashed_out: int
var enemies_slain: int
var rooms_cleared: int
var end_reason: RunManager.EndReason

static func create(
    essence: int,
    enemies: int,
    rooms: int,
    reason: RunManager.EndReason
) -> RunSummary
```

**Contract**: Immutable after `create()` returns. All fields are whole numbers. Never null after creation.

---

## New: ResultsScreen (`scenes/ui/run_end/ResultsScreen.gd`)

```gdscript
extends CanvasLayer

## Assigned via Inspector
@export var _essence_label: Label
@export var _enemies_label: Label
@export var _rooms_label: Label
@export var _return_button: Button

## Emitted when the player taps Return
signal return_pressed

## Populate all labels from the snapshot. Call immediately after add_child().
func setup(summary: RunSummary) -> void
```

**Contract**: `setup()` must be called before the node is visible. Never reads from RunManager or dungeon nodes directly — only from the `RunSummary` argument.

---

## Modified: RunManager (`scripts/managers/RunManager.gd`)

### New fields
```gdscript
var enemies_slain: int = 0        # reset in start_run()
var run_summary: RunSummary = null # written in end_run(), null until first run ends
```

### Modified: `start_run()`
Add to reset block:
```gdscript
enemies_slain = 0
```

### Modified: `end_run(reason)`
After computing `cashed_out`, before emitting `run_ended`:
```gdscript
run_summary = RunSummary.create(cashed_out, enemies_slain, cleared_rooms.size(), reason)
```

### Modified: `_on_enemy_defeated(enemy_type_id)`
Add after existing logic:
```gdscript
enemies_slain += 1
```

**Signal unchanged**: `run_ended(reason: EndReason)` — callers read `RunManager.run_summary` after the signal fires.

---

## Modified: RoomLoader (`scripts/dungeon/RoomLoader.gd`)

### New connection in `_ready()`
```gdscript
RunManager.run_ended.connect(_on_run_ended)
```

### New handler
```gdscript
func _on_run_ended(_reason: RunManager.EndReason) -> void:
    if _current_room_node != null:
        _current_room_node.queue_free()
        _current_room_node = null
        RunManager.current_room = null
```

**Contract**: Room is freed synchronously when the run ends. ResultsScreen is shown after this — it has no access to dungeon nodes.

---

## Modified: Main.gd (`scenes/core/Main.gd`)

### New connection in `_ready()`
```gdscript
RunManager.run_ended.connect(_on_run_ended)
```

### New handler
```gdscript
func _on_run_ended(_reason: RunManager.EndReason) -> void:
    var screen := _RESULTS_SCREEN_SCENE.instantiate() as ResultsScreen
    screen.setup(RunManager.run_summary)
    screen.return_pressed.connect(_on_results_return)
    add_child(screen)

func _on_results_return() -> void:
    # ResultsScreen frees itself or Main frees it
    _hub_room = _HUB_ROOM_SCENE.instantiate()
    add_child(_hub_room)
    _hub_room.hub_exited.connect(_on_hub_exited)
```

---

## Modified: ExplorationHUD (`scenes/ui/hud/ExplorationHUD.gd`)

### New connection in `_ready()`
```gdscript
RunManager.run_ended.connect(_on_gameplay_ended)
```

**Contract**: HUD hides on all run-end paths — player death (via `gameplay_ended`) and any other end reason (via `run_ended`). Connecting both signals is safe; showing a hidden node is a no-op.
