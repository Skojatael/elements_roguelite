# Contract: Hub Scenes — Boss Run additions (034)

## BossRunShop (scenes/hub/BossRunShop.gd)

```gdscript
class_name BossRunShop extends Control

@export var _button: Button

# Visibility rule:
#   visible = (MetaManager.endless_boss_kill_count >= threshold) AND (NOT MetaManager.is_boss_run_unlocked)
#   threshold read from ResourceManager.get_meta_config().get("boss_run_kill_threshold", 3)

# Refresh triggers:
#   MetaManager.shards_changed  → _update_visibility()
#   GlobalSignals.hub_entered   → _update_visibility()

# On button press:
#   MetaManager.purchase_boss_run() → _update_visibility()
#   No-op if purchase returns false (insufficient shards or already unlocked)
```

---

## BossRunButton (scenes/hub/BossRunButton.gd)

```gdscript
class_name BossRunButton extends Control

signal boss_run_pressed

@export var _button: Button

# Visibility rule:
#   visible = MetaManager.is_boss_run_unlocked

# Refresh triggers:
#   MetaManager.shards_changed → _update_visibility()

# Guard on press:
#   if RunManager.is_run_active: return  (no double-run)
#   else: boss_run_pressed.emit()
```

---

## HubRoom (scenes/hub/HubRoom.gd) — additions

```gdscript
signal hub_boss_run_pressed
# Emitted when BossRunButton fires boss_run_pressed.
# HubRoom calls queue_free() after emitting — same pattern as hub_exited.

@export var _boss_run_button: BossRunButton
# Assigned in Inspector. Wired in _ready():
#   _boss_run_button.boss_run_pressed.connect(_on_boss_run_pressed)
```

---

## BossVictoryOverlay (scenes/ui/boss_victory/BossVictoryOverlay.gd) — addition

```gdscript
func setup(show_continue: bool) -> void:
    # Sets _continue_button.visible = show_continue.
    # Called immediately after instantiation, before connecting signals.
    # In boss mode: show_continue = false → Continue button hidden.
    # In endless mode: show_continue = true → Continue button visible (existing behaviour).
```

---

## Main.gd — additions

```gdscript
# New connection (both _ready() and _on_results_return(), after add_child(_hub_room)):
_hub_room.hub_boss_run_pressed.connect(_on_hub_boss_run_pressed)

func _on_hub_boss_run_pressed() -> void:
    # _hub_room already freed itself (queue_free in HubRoom._on_boss_run_pressed)
    _hub_room = null
    RunManager.start_run("boss")
    GlobalSignals.gameplay_started.emit()
    _on_boss_teleport_pressed()   # existing method, unchanged

# Modified _on_boss_room_cleared():
# Boss mode: skips essence reward and relic offer → goes straight to _show_boss_victory_overlay()
# Endless mode: existing behaviour unchanged
```
