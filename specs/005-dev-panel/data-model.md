# Data Model: Dev Panel

**Feature**: 005-dev-panel
**Date**: 2026-02-21

---

## DEV_MODE Flag

| Property | Value |
|---|---|
| Name | `DEV_MODE` |
| Type | `const bool` |
| Location | `scenes/core/Main.gd` |
| Default | `true` (dev builds) |
| Purpose | Gates all DevPanel instantiation. Change to `false` to remove panel entirely. |

---

## DevPanel Scene Structure

```
DevPanel (CanvasLayer)          [layer=128, always above game content]
└── PanelContainer              [styled background, top-left anchor]
    └── VBoxContainer           [stacks buttons vertically]
        ├── Button "StartRun"   [text: "Start Run"]
        ├── Button "EndRun"     [text: "End Run"]
        ├── Button "CashOut"    [text: "Cash Out"]
        └── Button "StartBoss"  [text: "Start Boss"]
```

---

## DevPanel Script Interface

**File**: `scenes/ui/dev/DevPanel.gd`
**Attached to**: DevPanel (CanvasLayer root)

### Signals

| Signal | Emitted when |
|---|---|
| `start_run_pressed` | Player clicks Start Run button |
| `end_run_pressed` | Player clicks End Run button |
| `cash_out_pressed` | Player clicks Cash Out button (stub) |
| `start_boss_pressed` | Player clicks Start Boss button (stub) |

### Nodes (onready)

| Var | Path | Type |
|---|---|---|
| `_btn_start_run` | `$PanelContainer/VBoxContainer/StartRun` | `Button` |
| `_btn_end_run` | `$PanelContainer/VBoxContainer/EndRun` | `Button` |
| `_btn_cash_out` | `$PanelContainer/VBoxContainer/CashOut` | `Button` |
| `_btn_start_boss` | `$PanelContainer/VBoxContainer/StartBoss` | `Button` |

---

## Main.gd Changes

| Change | Detail |
|---|---|
| Add constant | `const DEV_MODE: bool = true` |
| Add preload | `const _DEV_PANEL_SCENE = preload("res://scenes/ui/dev/DevPanel.tscn")` (inside DEV_MODE guard or at file level) |
| Add in `_ready()` | If DEV_MODE: instantiate panel, add_child, connect all 4 signals |
| Bug fix | Change `RunManager.end_run("dead")` → `RunManager.end_run()` |

### Signal → Action mapping (wired in Main.gd)

| Signal | Action |
|---|---|
| `start_run_pressed` | `RunManager.start_run("endless")` |
| `end_run_pressed` | `RunManager.end_run()` |
| `cash_out_pressed` | `print("[DevPanel] cash_out pressed — stub")` |
| `start_boss_pressed` | `print("[DevPanel] start_boss pressed — stub")` |
