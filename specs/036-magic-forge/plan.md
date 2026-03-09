# Implementation Plan: Magic Forge

**Branch**: `036-magic-forge` | **Date**: 2026-03-07 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/036-magic-forge/spec.md`

## Summary

Add a "Magic Forge" hub building that gates access to run upgrades behind a one-time 120-shard unlock. Locked state shows a Ruined Forge (black ColorRect); tapping opens a small restore overlay. After unlocking, shows a Magic Forge (grey ColorRect); tapping opens an upgrade screen exposing the existing damage % upgrade. The existing bare-bones `UpgradeShop` node is removed from the hub — the forge becomes the single upgrade entry point.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing
**Primary Dependencies**: MetaManager autoload, SaveManager autoload, ResourceManager autoload
**Storage**: `user://meta_save.json` — one new boolean field `magic_forge_unlocked`
**Testing**: Manual in-editor playtesting
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Project Type**: Godot 4.6 mobile game
**Performance Goals**: 60 fps — all new nodes are simple Control/ColorRect; no performance concern
**Constraints**: Forge cost and upgrade costs must remain in `data/meta_config.json`. No hardcoded balance values in scripts.
**Scale/Scope**: 3 new scenes, 1 new MetaState field, 4 modified files, 1 editor task

## Constitution Check

*GATE: Must pass before implementation.*

- **I. Single Responsibility** ✅ — `MagicForge.gd` owns forge-zone interactions and overlay lifecycle; `RestoreForgeOverlay.gd` owns the restore prompt; `ForgeUpgradeScreen.gd` owns upgrade purchase UI; `MetaManagerImpl` owns forge unlock logic. `HubRoom.gd` unchanged. Each script has one reason to change.
- **II. Data-Driven Content** ✅ — `magic_forge_cost: 120` lives in `data/meta_config.json`. No balance constants in scripts.
- **III. Mobile-First Performance** ✅ — Only `Control`, `ColorRect`, `Button`, `Label`, `CanvasLayer` nodes. No shaders, no physics.
- **IV. Editor-Centric Workflow** ✅ — All scenes built in Godot Editor. All child-node references use `@export var`. `HubRoom.tscn` modified in Editor only. No raw `.tscn` text edits.
- **V. Simplicity & YAGNI** ✅ — Only damage % upgrade in scope. No speculative upgrade slots. No base class or abstraction for "hub buildings" (only two concrete new scripts; the threshold for abstraction is not reached). Restore overlay is purpose-built.
- **VI. Early Return** ✅ — `_on_forge_pressed()` guards on unlock state; overlay-open guard prevents double-spawn. All methods use early return at first unmet precondition.

**Gate result: PASS — proceed to implementation.**

## Project Structure

### Documentation (this feature)

```text
specs/036-magic-forge/
├── plan.md           ← this file
├── research.md       ← Phase 0 output
├── data-model.md     ← Phase 1 output
└── tasks.md          ← /speckit.tasks output (not yet created)
```

### Source Code (files changed)

```text
# New scripts and scenes
scenes/hub/MagicForge.gd
scenes/hub/magicforge.tscn
scenes/hub/RestoreForgeOverlay.gd
scenes/hub/restoreforgeoverlay.tscn
scenes/hub/ForgeUpgradeScreen.gd
scenes/hub/forgeupgradescreen.tscn

# Modified — data layer
data/meta_config.json
scripts/data_models/MetaState.gd
scripts/managers/SaveManager.gd     (SaveManagerImpl)
autoload/MetaManager.gd
scripts/managers/MetaManager.gd     (MetaManagerImpl)

# Editor task (Godot Editor only)
scenes/hub/HubRoom.tscn             — add MagicForge instance, remove UpgradeShop node
```

---

## Implementation Design

### Layer 1 — Data (implement first)

**`data/meta_config.json`** — add forge cost:
```json
"magic_forge_cost": 120
```

**`scripts/data_models/MetaState.gd`** — add field:
```gdscript
var magic_forge_unlocked: bool = false
```

**`scripts/managers/SaveManager.gd`** (SaveManagerImpl) — add to both save and load:
```gdscript
# save_meta_state — add to data dict:
"magic_forge_unlocked": state.magic_forge_unlocked,

# load_meta_state — add assignment:
state.magic_forge_unlocked = bool((parsed as Dictionary).get("magic_forge_unlocked", false))
```

---

### Layer 2 — MetaManagerImpl (purchase logic)

**`scripts/managers/MetaManager.gd`** — add method:
```gdscript
func purchase_magic_forge(cost: int, save_manager: Node) -> bool:
    if meta_state.magic_forge_unlocked:
        return false
    if not can_spend(cost):
        return false
    meta_state.total_shards -= cost
    meta_state.magic_forge_unlocked = true
    save_manager.save_meta_state(meta_state)
    return true
```

---

### Layer 3 — MetaManager autoload (thin wrapper)

**`autoload/MetaManager.gd`** — add property and delegate method:
```gdscript
var is_magic_forge_unlocked: bool:
    get: return _impl.meta_state.magic_forge_unlocked

func purchase_magic_forge() -> bool:
    var cost: int = ResourceManager.get_meta_config().get("magic_forge_cost", 120)
    var success: bool = _impl.purchase_magic_forge(cost, SaveManager)
    if success:
        shards_changed.emit(meta_state.total_shards)
    return success
```

---

### Layer 4 — MagicForge hub building

**`scenes/hub/MagicForge.gd`**:
```gdscript
class_name MagicForge
extends Control

@export var _ruined_visual: ColorRect
@export var _magic_visual: ColorRect
@export var _label: Label
@export var _button: Button
@export var _restore_overlay_scene: PackedScene
@export var _upgrade_screen_scene: PackedScene

var _overlay_layer: CanvasLayer = null


func _ready() -> void:
    _button.pressed.connect(_on_forge_pressed)
    MetaManager.shards_changed.connect(func(_n: int) -> void: _update_visuals())
    GlobalSignals.hub_entered.connect(func() -> void: _update_visuals())
    _update_visuals()


func _update_visuals() -> void:
    var unlocked: bool = MetaManager.is_magic_forge_unlocked
    _ruined_visual.visible = not unlocked
    _magic_visual.visible = unlocked
    _label.text = "Magic Forge" if unlocked else "Ruined Forge"


func _on_forge_pressed() -> void:
    if _overlay_layer != null:
        return
    if MetaManager.is_magic_forge_unlocked:
        _show_upgrade_screen()
    else:
        _show_restore_overlay()


func _show_restore_overlay() -> void:
    _overlay_layer = CanvasLayer.new()
    add_child(_overlay_layer)
    var overlay: RestoreForgeOverlay = _restore_overlay_scene.instantiate() as RestoreForgeOverlay
    _overlay_layer.add_child(overlay)
    overlay.restore_pressed.connect(_on_restore_pressed)
    overlay.maybe_later_pressed.connect(_close_overlay)


func _show_upgrade_screen() -> void:
    _overlay_layer = CanvasLayer.new()
    add_child(_overlay_layer)
    var screen: ForgeUpgradeScreen = _upgrade_screen_scene.instantiate() as ForgeUpgradeScreen
    _overlay_layer.add_child(screen)
    screen.close_pressed.connect(_close_overlay)


func _close_overlay() -> void:
    if _overlay_layer == null:
        return
    _overlay_layer.queue_free()
    _overlay_layer = null


func _on_restore_pressed() -> void:
    var success: bool = MetaManager.purchase_magic_forge()
    if not success:
        return
    _close_overlay()
    _update_visuals()
```

**`scenes/hub/magicforge.tscn`** (Editor task — structure):
```
MagicForge (Control, script=MagicForge.gd)
├── RuinedVisual (ColorRect, color=black, size=120×60)
├── MagicVisual  (ColorRect, color=grey,  size=120×60)
├── Label        (text set by script)
└── Button       (transparent, covers zone, size=120×60)
```
Exports assigned in Inspector: `_ruined_visual`, `_magic_visual`, `_label`, `_button`, `_restore_overlay_scene`, `_upgrade_screen_scene`.

---

### Layer 5 — RestoreForgeOverlay

**`scenes/hub/RestoreForgeOverlay.gd`**:
```gdscript
class_name RestoreForgeOverlay
extends Control

signal restore_pressed
signal maybe_later_pressed

@export var _restore_button: Button
@export var _later_button: Button


func _ready() -> void:
    var cost: int = ResourceManager.get_meta_config().get("magic_forge_cost", 120)
    _restore_button.text = "Restore the Forge ({c} shards)".format({"c": cost})
    _restore_button.disabled = not MetaManager.can_spend(cost)
    _restore_button.pressed.connect(func() -> void: restore_pressed.emit())
    _later_button.text = "Maybe Later"
    _later_button.pressed.connect(func() -> void: maybe_later_pressed.emit())
```

**`scenes/hub/restoreforgeoverlay.tscn`** (Editor task — structure):
```
RestoreForgeOverlay (Control, anchors=full screen, mouse_filter=Stop, script=RestoreForgeOverlay.gd)
├── Background (ColorRect, semi-transparent dark, anchors=full screen)
├── Panel (Control, centered, ~300×120)
│   ├── RestoreButton (Button)
│   └── LaterButton   (Button)
```
Exports assigned in Inspector: `_restore_button`, `_later_button`.

---

### Layer 6 — ForgeUpgradeScreen

**`scenes/hub/ForgeUpgradeScreen.gd`**:
```gdscript
class_name ForgeUpgradeScreen
extends Control

signal close_pressed

@export var _damage_button: Button
@export var _close_button: Button


func _ready() -> void:
    _close_button.pressed.connect(func() -> void: close_pressed.emit())
    _damage_button.pressed.connect(_on_damage_buy)
    MetaManager.shards_changed.connect(func(_n: int) -> void: _update_buttons())
    _update_buttons()


func _update_buttons() -> void:
    var cfg: Dictionary = ResourceManager.get_meta_config().get("damage_upgrade", {})
    var max_levels: int = cfg.get("max_levels", 10)
    if MetaManager.meta_state.damage_upgrade_level >= max_levels:
        _damage_button.text = "Damage Multiplier — MAX"
        _damage_button.disabled = true
        return
    var cost: int = MetaManager.get_next_upgrade_cost()
    var level: int = MetaManager.meta_state.damage_upgrade_level
    _damage_button.text = "Damage +{pct}% (Lv{lv}) — {cost} shards".format({
        "pct": int(float(level + 1) * cfg.get("damage_per_level", 0.1) * 100.0),
        "lv": level + 1,
        "cost": cost,
    })
    _damage_button.disabled = not MetaManager.can_spend(cost)


func _on_damage_buy() -> void:
    MetaManager.purchase_damage_upgrade()
    _update_buttons()
```

**`scenes/hub/forgeupgradescreen.tscn`** (Editor task — structure):
```
ForgeUpgradeScreen (Control, anchors=full screen, mouse_filter=Stop, script=ForgeUpgradeScreen.gd)
├── Background (ColorRect, semi-transparent dark, anchors=full screen)
├── Panel (Control, centered, ~400×200)
│   ├── TitleLabel   (Label, text="Magic Forge")
│   ├── DamageButton (Button)
│   └── CloseButton  (Button, text="Close")
```
Exports assigned in Inspector: `_damage_button`, `_close_button`.

---

### Layer 7 — Editor task: HubRoom.tscn

In the Godot Editor, open `scenes/hub/HubRoom.tscn`:

1. **Remove** the inline `UpgradeShop` node (and its children `ColorRect`, `Button`). This removes the ungated damage upgrade button from the hub.
2. **Instance** `scenes/hub/magicforge.tscn` as a child of `HubRoom`.
3. **Position** MagicForge at approximately `(0, -350)` local position — top-center of the hub floor (above the TeleportDoor).
4. **Assign exports** on MagicForge in the Inspector:
   - `_ruined_visual` → `RuinedVisual`
   - `_magic_visual` → `MagicVisual`
   - `_label` → `Label`
   - `_button` → `Button`
   - `_restore_overlay_scene` → `res://scenes/hub/restoreforgeoverlay.tscn`
   - `_upgrade_screen_scene` → `res://scenes/hub/forgeupgradescreen.tscn`

**Note**: `HubRoom.gd` requires **no code changes** — MagicForge is fully self-contained.

---

## Removal note: UpgradeShop.gd

`scenes/hub/UpgradeShop.gd` becomes orphaned when the `UpgradeShop` node is removed from `HubRoom.tscn`. Delete the file after the editor task is complete (it is not referenced by any other scene).
