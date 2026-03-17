# Implementation Plan: Player HP Bar

**Branch**: `047-player-hp-bar` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)

## Summary

Add a horizontal HP bar to `ExplorationHUD` that fills proportionally to `current_hp / max_hp` and overlays a `current / max` integer label. Wired once in `Main._ready()` via `StatsComponent.health_changed`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Godot `Control`, `ColorRect`, `Label` nodes — no external libraries
**Storage**: N/A — pure UI, no persistence
**Testing**: Manual in-editor playtest; visual verification at 0%, 50%, 100% HP
**Target Platform**: Android mobile portrait 1080×1920 (developed on Windows)
**Performance Goals**: Single `health_changed` signal handler per damage event — no per-frame polling
**Constraints**: Mobile renderer compatible (ColorRect is GPU-accelerated, zero shader cost); must work at 60 fps on mid-range Android
**Scale/Scope**: 2 new files (HPBar.tscn + HPBar.gd), 2 modified files (ExplorationHUD.gd, Main.gd), 1 Editor scene change (ExplorationHUD.tscn)

## Constitution Check

*GATE: Must pass before implementation.*

- **I. Single Responsibility** ✅ — `HPBar.gd` has one responsibility: display health state. `ExplorationHUD.gd` gains only a delegation method. No logic mixed into UI.
- **II. Data-Driven Content** ✅ — No balance values; HP bar is pure display. No JSON required.
- **III. Mobile-First** ✅ — `ColorRect` and `Label` are trivially cheap on mobile. Single signal callback with no per-frame polling.
- **IV. Editor-Centric** ✅ — HPBar scene created in the Godot Editor. Node refs via `@export var`. No hardcoded `$NodeName` paths.
- **V. Simplicity & YAGNI** ✅ — Minimal: one scene, one script, two exported vars, one wiring call. No animation, no gradient, no abstraction layer.
- **VI. Early Return** ✅ — `_on_health_changed` guards against `max_hp <= 0.0` before computing ratio.

## Project Structure

### Documentation (this feature)

```text
specs/047-player-hp-bar/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code

```text
scenes/ui/hud/
├── HPBar.tscn           ← NEW: HP bar scene (Control root)
├── HPBar.gd             ← NEW: HP bar script
├── ExplorationHUD.tscn  ← MODIFIED: HPBar node added as child
└── ExplorationHUD.gd    ← MODIFIED: @export _hp_bar + setup_hp_bar()

scenes/core/
└── Main.gd              ← MODIFIED: wire _stats → hp bar in _ready()
```

## Design

### HPBar scene layout

```
HPBar (Control)
├── Background (ColorRect)   — full width, dark colour, z_index 0
├── Fill (ColorRect)         — same initial size, accent colour, z_index 1
└── Label (Label)            — anchored to full rect, centred text, z_index 2
```

All three nodes exported on `HPBar.gd` so the Editor can assign them.

### HPBar.gd API

```gdscript
class_name HPBar
extends Control

@export var _bg: ColorRect
@export var _fill: ColorRect
@export var _label: Label

func setup(stats: StatsComponent) -> void:
    stats.health_changed.connect(_on_health_changed)
    _on_health_changed(stats.current_health, stats.max_health)

func _on_health_changed(new_health: float, max_hp: float) -> void:
    if max_hp <= 0.0:
        return
    var ratio: float = clampf(new_health / max_hp, 0.0, 1.0)
    _fill.size.x = _bg.size.x * ratio
    _label.text = "{cur} / {max}".format({"cur": floori(new_health), "max": floori(max_hp)})
```

### ExplorationHUD.gd additions

```gdscript
@export var _hp_bar: HPBar

func setup_hp_bar(stats: StatsComponent) -> void:
    _hp_bar.setup(stats)
```

### Main.gd addition (in `_ready()`, after existing @onready wiring)

```gdscript
_exploration_hud.setup_hp_bar(_stats)
```

## Implementation Steps

1. **Editor — Create HPBar.tscn**
   - Root: `Control` (class HPBar, rename node to `HPBar`)
   - Child: `Background` (`ColorRect`, full bar width/height, dark grey)
   - Child: `Fill` (`ColorRect`, same initial size, green or red accent)
   - Child: `Label` (anchored full rect, centred, white text)
   - Attach `HPBar.gd`
   - Assign `_bg`, `_fill`, `_label` exports in Inspector

2. **Code — Write HPBar.gd** (as designed above)

3. **Editor — Update ExplorationHUD.tscn**
   - Add `HPBar` instance as child of ExplorationHUD
   - Position at top of screen (e.g., anchor top-left, fixed size ~600×40 px)
   - Assign `_hp_bar` export on `ExplorationHUD`

4. **Code — Update ExplorationHUD.gd** (add export + `setup_hp_bar` method)

5. **Code — Update Main.gd** (call `setup_hp_bar(_stats)` in `_ready()`)

6. **Validate** — Playtest: enter run, take damage, verify bar and label update correctly at various HP levels
