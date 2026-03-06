# Interfaces: Boss Victory Outcome (030)

---

## 1. BossVictoryOverlay.gd (new)

```gdscript
class_name BossVictoryOverlay
extends Control

signal cash_out_pressed
signal continue_pressed

@export var _cash_out_button: Button
@export var _continue_button: Button


func _ready() -> void:
    _cash_out_button.pressed.connect(_on_cash_out_pressed)
    _continue_button.pressed.connect(_on_continue_pressed)


func _on_cash_out_pressed() -> void:
    _cash_out_button.disabled = true
    cash_out_pressed.emit()


func _on_continue_pressed() -> void:
    _continue_button.disabled = true
    _continue_button.text = "Coming Soon..."
    continue_pressed.emit()
```

**Scene**: `scenes/ui/boss_victory/BossVictoryOverlay.tscn`
- Root: `Control` with script attached
- Child: `Button` named `CashOutButton`, text `"Cash Out"` → assigned to `_cash_out_button`
- Child: `Button` named `ContinueButton`, text `"Continue Further"` → assigned to `_continue_button`

---

## 2. ExplorationHUD.gd — fix _on_room_cleared_for_boss (rename + guard)

```gdscript
# Before (broken — _room_id unused, boss room re-shows button):
func _on_room_cleared_for_boss(_room_id: String) -> void:
    if _boss_button.visible:
        return
    var threshold: int = ResourceManager.get_enemy_rooms_required(BOSS_ENEMY_ID)
    if RunManager.cleared_rooms.size() < threshold:
        return
    _boss_button.visible = true

# After:
const BOSS_ROOM_ID: String = "boss_room"

func _on_room_cleared_for_boss(room_id: String) -> void:
    if room_id == BOSS_ROOM_ID:
        return
    if _boss_button.visible:
        return
    var threshold: int = ResourceManager.get_enemy_rooms_required(BOSS_ENEMY_ID)
    if RunManager.cleared_rooms.size() < threshold:
        return
    _boss_button.visible = true
```

---

## 3. Main.gd — additions

### New constants and fields

```gdscript
const _BOSS_VICTORY_OVERLAY_SCENE = preload("res://scenes/ui/boss_victory/BossVictoryOverlay.tscn")

var _boss_room_spawner: RoomSpawner = null
var _boss_victory_layer: CanvasLayer = null
var _boss_victory_overlay: BossVictoryOverlay = null
```

### _on_boss_teleport_pressed() — extended

```gdscript
func _on_boss_teleport_pressed() -> void:
    _room_loader.free_current_room()
    var rooms_cleared: int = RunManager.cleared_rooms.size()
    var boss_mult: float = 1.0 + 0.06 * float(rooms_cleared)
    var context: SpawnContext = SpawnContext.create(self, BOSS_ROOM_WORLD_POS)
    var spawner: RoomSpawner = RunManager.spawn_room(_BOSS_ROOM_DATA, "boss_room", context)
    spawner.difficulty_mult = boss_mult
    # Disable inherited Door nodes — boss room has no exits.
    var room_node: Node = spawner.get_parent()
    for child: Node in room_node.get_children():
        if child is Door:
            child.visible = false
            child.monitoring = false
    # Store spawner and wire victory trigger.
    _boss_room_spawner = spawner
    spawner.room_cleared.connect(_on_boss_room_cleared)
    _player.global_position = BOSS_ROOM_WORLD_POS
    _camera.global_position = BOSS_ROOM_WORLD_POS
    print("[Main] boss teleport — rooms_cleared={r} boss_mult={m}".format({"r": rooms_cleared, "m": boss_mult}))
```

### _on_boss_room_cleared() (new)

```gdscript
func _on_boss_room_cleared(_room_id: String) -> void:
    _boss_room_spawner = null
    _exploration_hud.visible = false
    _boss_victory_layer = CanvasLayer.new()
    add_child(_boss_victory_layer)
    _boss_victory_overlay = _BOSS_VICTORY_OVERLAY_SCENE.instantiate() as BossVictoryOverlay
    _boss_victory_layer.add_child(_boss_victory_overlay)
    _boss_victory_overlay.cash_out_pressed.connect(_on_boss_cash_out_pressed)
    _boss_victory_overlay.continue_pressed.connect(_on_boss_continue_pressed)
```

### _on_boss_cash_out_pressed() (new)

```gdscript
func _on_boss_cash_out_pressed() -> void:
    RunManager.end_run(RunManager.EndReason.CASH_OUT)
    # _on_run_ended fires automatically and frees the overlay layer.
```

### _on_boss_continue_pressed() (new)

```gdscript
func _on_boss_continue_pressed() -> void:
    print("[Main] Continue Further — stub, no content yet")
```

### _on_run_ended() — extended (add overlay cleanup)

```gdscript
func _on_run_ended(_reason: RunManager.EndReason) -> void:
    if _boss_victory_layer != null:          # NEW
        _boss_victory_layer.queue_free()     # NEW
        _boss_victory_layer = null           # NEW
        _boss_victory_overlay = null         # NEW
    if _relic_offer_layer != null:
        # ... rest unchanged
```

### _on_run_started() — extended (add overlay cleanup)

```gdscript
func _on_run_started() -> void:
    if _boss_victory_layer != null:          # NEW
        _boss_victory_layer.queue_free()     # NEW
        _boss_victory_layer = null           # NEW
        _boss_victory_overlay = null         # NEW
    if is_instance_valid(_hub_room):
        # ... rest unchanged
```

---

## Signal Flow

```
Boss dies
  → RoomSpawner._on_enemy_defeated()
  → RunManager.mark_room_cleared("boss_room")
  → RoomSpawner.room_cleared.emit("boss_room")
      → Main._on_boss_room_cleared()      [new — shows overlay]
      → RunManager re-emits room_cleared  [existing]
          → ExplorationHUD._on_room_cleared_for_boss("boss_room")
              → early return (room_id == BOSS_ROOM_ID)  [fixed]

Player presses "Cash Out"
  → BossVictoryOverlay.cash_out_pressed.emit()
  → Main._on_boss_cash_out_pressed()
  → RunManager.end_run(CASH_OUT)
  → RunManager.run_ended.emit()
  → Main._on_run_ended()
      → frees _boss_victory_layer
      → shows ResultsScreen
```
