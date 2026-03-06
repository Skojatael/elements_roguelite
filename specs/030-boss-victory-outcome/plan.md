# Implementation Plan: Boss Victory Outcome

**Branch**: `030-boss-victory-outcome` | **Date**: 2026-03-05 | **Spec**: specs/030-boss-victory-outcome/spec.md

## Summary

Add two behaviours to the boss room: (1) suppress all Door nodes so the encounter has no exits, and (2) display a "Cash Out / Continue Further" overlay immediately after the boss dies. Cash Out reuses the existing run-end flow; Continue Further is a visible stub. One latent bug in ExplorationHUD (boss button re-shows on boss room clear) is fixed as part of this feature.

## Technical Context

**Language/Version**: GDScript, Godot 4.6
**Primary Dependencies**: RunManager (end_run), RoomSpawner (room_cleared signal), existing CanvasLayer screen pattern (ResultsScreen, RelicOfferScreen)
**Storage**: N/A — no new data files or persistence
**Testing**: Manual (quickstart.md, 7 scenarios)
**Target Platform**: Android mobile (portrait 1080×1920); D3D12 Windows dev
**Project Type**: Single Godot project
**Performance Goals**: Overlay appears the same frame as boss death (no deferred)
**Constraints**: No new autoloads; no new JSON; no raw .tscn editing
**Scale/Scope**: 1 new scene, 3 modified scripts

## Constitution Check

- **I. Single Responsibility** ✅ BossVictoryOverlay owns only overlay presentation; Main.gd owns lifecycle wiring; ExplorationHUD owns HUD state. No responsibility mixing.
- **II. Data-Driven Content** ✅ No balance constants added to code; no new content values.
- **III. Mobile-First** ✅ Overlay is two buttons — negligible draw cost. No shaders.
- **IV. Editor-Centric** ✅ BossVictoryOverlay.tscn created in Editor; @export for button refs; no hardcoded $NodeName.
- **V. Simplicity & YAGNI** ✅ Continue Further is a single-method stub; no speculative infrastructure.
- **VI. Early Return** ✅ All new functions use guard clauses; `if room_id == BOSS_ROOM_ID: return` is the fix pattern.

## Project Structure

### Documentation (this feature)

```text
specs/030-boss-victory-outcome/
├── plan.md              ← this file
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    └── interfaces.md
```

### Source Code

```text
scenes/ui/boss_victory/
├── BossVictoryOverlay.tscn   (NEW — editor task)
└── BossVictoryOverlay.gd     (NEW)

scenes/ui/hud/
└── ExplorationHUD.gd         (MODIFIED — boss button re-show bug fix)

scenes/core/
└── Main.gd                   (MODIFIED — door disable, victory overlay lifecycle)
```

## Phase 1: Foundational

### US1 — No doors

**What**: After spawning the boss room, iterate its children and set `visible = false` + `monitoring = false` on every `Door` node. `Door` has `class_name Door`, so `child is Door` works.

**Where**: `scenes/core/Main.gd` — inside `_on_boss_teleport_pressed()`, immediately after `RunManager.spawn_room()` returns.

**Code**:
```gdscript
var room_node: Node = spawner.get_parent()
for child: Node in room_node.get_children():
    if child is Door:
        child.visible = false
        child.monitoring = false
```

### Bug fix — ExplorationHUD boss button re-show

**What**: Rename `_room_id` → `room_id` in `_on_room_cleared_for_boss()` and add early return when `room_id == BOSS_ROOM_ID`.

**Where**: `scenes/ui/hud/ExplorationHUD.gd`

**Full replacement**:
```gdscript
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

## Phase 2: BossVictoryOverlay scene + script (US2)

### BossVictoryOverlay.gd (new)

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

**Editor task**: Create `scenes/ui/boss_victory/BossVictoryOverlay.tscn`:
- Root: `Control`, attach `BossVictoryOverlay.gd`
- Child: `Button` named `CashOutButton`, text `"Cash Out"` → Inspector assigns to `_cash_out_button`
- Child: `Button` named `ContinueButton`, text `"Continue Further"` → Inspector assigns to `_continue_button`

## Phase 3: Main.gd wiring (US2)

### New declarations

```gdscript
const _BOSS_VICTORY_OVERLAY_SCENE = preload("res://scenes/ui/boss_victory/BossVictoryOverlay.tscn")

var _boss_room_spawner: RoomSpawner = null
var _boss_victory_layer: CanvasLayer = null
var _boss_victory_overlay: BossVictoryOverlay = null
```

### _on_boss_teleport_pressed() — extend existing

Add after existing `spawner.difficulty_mult = boss_mult` line:
```gdscript
    var room_node: Node = spawner.get_parent()
    for child: Node in room_node.get_children():
        if child is Door:
            child.visible = false
            child.monitoring = false
    _boss_room_spawner = spawner
    spawner.room_cleared.connect(_on_boss_room_cleared)
```
(Remove the existing `_player.global_position` and `_camera.global_position` lines from their current position — they move to after this block, or keep them where they are since spawner wiring doesn't depend on position order.)

### New methods

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


func _on_boss_cash_out_pressed() -> void:
    RunManager.end_run(RunManager.EndReason.CASH_OUT)


func _on_boss_continue_pressed() -> void:
    print("[Main] Continue Further — stub, no content yet")
```

### _on_run_ended() — prepend overlay cleanup

```gdscript
func _on_run_ended(_reason: RunManager.EndReason) -> void:
    if _boss_victory_layer != null:
        _boss_victory_layer.queue_free()
        _boss_victory_layer = null
        _boss_victory_overlay = null
    if _relic_offer_layer != null:
    # ... rest unchanged
```

### _on_run_started() — prepend overlay cleanup

```gdscript
func _on_run_started() -> void:
    if _boss_victory_layer != null:
        _boss_victory_layer.queue_free()
        _boss_victory_layer = null
        _boss_victory_overlay = null
    if is_instance_valid(_hub_room):
    # ... rest unchanged
```
