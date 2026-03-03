# Contracts: DevPanel Get Relic Button

**Feature**: 022-devpanel-get-relic
**Date**: 2026-03-03

---

## DevPanel (scenes/ui/dev/DevPanel.gd) — MODIFIED

```gdscript
## Emitted when the Get Relic button is pressed.
signal get_relic_pressed

@onready var _btn_get_relic: Button = $PanelContainer/VBoxContainer/GetRelic

# In _ready():
_btn_get_relic.pressed.connect(get_relic_pressed.emit)
```

---

## RelicManager (autoload/RelicManager.gd) — MODIFIED

```gdscript
## Draws an offer from the pool and emits relic_offer_ready.
## No-op if the pool is empty.
func trigger_offer() -> void
```

**Implementation** (thin wrapper — delegates to impl):
```gdscript
func trigger_offer() -> void:
    var options: Array[RelicData] = _impl.draw_offer()
    if options.is_empty():
        print("[RelicManager] trigger_offer — pool empty, no offer")
        return
    relic_offer_ready.emit(options)
```

---

## Main.gd (scenes/core/Main.gd) — MODIFIED

**New connection in `_ready()` (inside DEV_MODE block)**:
```gdscript
panel.get_relic_pressed.connect(_on_dev_get_relic)
```

**New handler**:
```gdscript
func _on_dev_get_relic() -> void:
    if not RunManager.is_run_active:
        return
    if _relic_offer_screen != null:
        return
    RelicManager.trigger_offer()
```
