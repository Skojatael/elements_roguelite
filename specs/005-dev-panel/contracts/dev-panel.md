# Contract: DevPanel

**Feature**: 005-dev-panel
**File**: `scenes/ui/dev/DevPanel.gd`
**Date**: 2026-02-21

---

## Signals

```gdscript
signal start_run_pressed
signal end_run_pressed
signal cash_out_pressed
signal start_boss_pressed
```

All signals carry no payload — the action semantics are fully described by the signal name.

---

## Lifecycle

DevPanel has no public methods. It is entirely signal-driven.

```gdscript
func _ready() -> void:
    # Connect each button's pressed signal to the corresponding emit
    _btn_start_run.pressed.connect(start_run_pressed.emit)
    _btn_end_run.pressed.connect(end_run_pressed.emit)
    _btn_cash_out.pressed.connect(cash_out_pressed.emit)
    _btn_start_boss.pressed.connect(start_boss_pressed.emit)
```

---

## Instantiation Contract (Main.gd side)

```gdscript
const DEV_MODE: bool = true
const _DEV_PANEL_SCENE = preload("res://scenes/ui/dev/DevPanel.tscn")

func _ready() -> void:
    if DEV_MODE:
        var panel := _DEV_PANEL_SCENE.instantiate()
        add_child(panel)
        panel.start_run_pressed.connect(func(): RunManager.start_run("endless"))
        panel.end_run_pressed.connect(func(): RunManager.end_run())
        panel.cash_out_pressed.connect(func(): print("[DevPanel] cash_out pressed — stub"))
        panel.start_boss_pressed.connect(func(): print("[DevPanel] start_boss pressed — stub"))
```

---

## Constraints

- DevPanel MUST NOT reference RunManager, GlobalSignals, or any autoload directly.
- All game logic is connected externally (by Main.gd) via signals.
- Stub signal handlers MUST NOT be implemented inside DevPanel — they are the caller's responsibility.
- The four signals MUST NOT be renamed or removed in future features — only connected to real implementations.
