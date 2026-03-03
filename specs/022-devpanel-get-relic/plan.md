# Implementation Plan: DevPanel Get Relic Button

**Branch**: `022-devpanel-get-relic` | **Date**: 2026-03-03 | **Spec**: [spec.md](spec.md)

## Summary

Add a "Get Relic" button to the DevPanel that triggers the relic offer screen during an active run, bypassing the normal room-clear frequency requirement. Reuses the existing `relic_offer_ready` signal path — the offer screen is unaware of the trigger source.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: RelicManager (autoload), DevPanel, Main.gd
**Storage**: N/A
**Testing**: Manual — see quickstart.md
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: N/A (dev-only button)
**Constraints**: Button active only when `DEV_MODE = true`
**Scale/Scope**: 3 files modified, 1 editor task (Button node)

## Constitution Check

- **I. Single Responsibility**: DevPanel owns the button/signal. RelicManager.trigger_offer() is a thin delegating method. Main.gd owns the guard logic. ✅
- **II. Data-Driven Content**: No new data required. ✅
- **III. Mobile-First**: Dev-only UI, zero runtime performance impact. ✅
- **IV. Editor-Centric**: Button added via Godot Editor; `$` path matches existing DevPanel convention. ✅
- **V. YAGNI**: One signal, one method, one handler — nothing speculative. ✅

## Project Structure

```text
specs/022-devpanel-get-relic/
├── plan.md
├── research.md
├── contracts/interfaces.md
├── quickstart.md
└── tasks.md             ← /speckit.tasks output

Source changes:
autoload/RelicManager.gd                  [MODIFIED] trigger_offer()
scenes/ui/dev/DevPanel.gd                 [MODIFIED] signal + button ref
scenes/ui/dev/DevPanel.tscn               [MODIFIED — EDITOR] add GetRelic Button node
scenes/core/Main.gd                       [MODIFIED] connect + handler
```

## Implementation

### RelicManager.gd — add trigger_offer()

```gdscript
func trigger_offer() -> void:
    var options: Array[RelicData] = _impl.draw_offer()
    if options.is_empty():
        print("[RelicManager] trigger_offer — pool empty, no offer")
        return
    relic_offer_ready.emit(options)
```

### DevPanel.gd — add signal + button

```gdscript
signal get_relic_pressed

@onready var _btn_get_relic: Button = $PanelContainer/VBoxContainer/GetRelic

# in _ready():
_btn_get_relic.pressed.connect(get_relic_pressed.emit)
```

### Main.gd — connect + handler

```gdscript
# inside DEV_MODE block in _ready():
panel.get_relic_pressed.connect(_on_dev_get_relic)

func _on_dev_get_relic() -> void:
    if not RunManager.is_run_active:
        return
    if _relic_offer_screen != null:
        return
    RelicManager.trigger_offer()
```

### DevPanel.tscn — Editor task

Add a `Button` node named `GetRelic` inside `PanelContainer/VBoxContainer`, after the existing buttons. Text: `"Get Relic"`.
