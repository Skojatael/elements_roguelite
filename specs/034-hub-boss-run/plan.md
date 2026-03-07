# Implementation Plan: Hub Boss Run

**Branch**: `034-hub-boss-run` | **Date**: 2026-03-07 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/034-hub-boss-run/spec.md`

## Summary

Add a permanently unlockable "Boss Run" button to the hub. Gate: 3 endless-mode boss kills + 300 shards one-time purchase. When activated, starts a `"boss"` mode run that places the player directly in the boss room — no dungeon traversal. Boss kill in boss mode awards 35 flat shards on cash-out (no essence conversion, no relic offer) and does not affect any endless-mode progression flags (`first_boss_killed`, `endless_boss_kill_count`).

## Technical Context

**Language/Version**: GDScript 4.6 (static typing)
**Primary Dependencies**: Godot 4.6 autoloads — `RunManager`, `MetaManager`, `RelicManager`, `ResourceManager`, `SaveManager`; `GlobalSignals`
**Storage**: `user://meta_save.json` (existing) — 2 new fields appended
**Testing**: Manual in-editor play testing per quickstart.md validation checklist
**Target Platform**: Android mobile portrait 1080×1920; Windows dev
**Project Type**: Single Godot project
**Performance Goals**: No new per-frame logic; all changes are event-driven (signals, button presses)
**Constraints**: Mobile renderer, Jolt physics — no changes to rendering or physics in this feature
**Scale/Scope**: 2 new hub scene scripts, modifications to 6 existing scripts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Single Responsibility** ✅
  - `BossRunShop` — sole responsibility: present the unlock purchase UI
  - `BossRunButton` — sole responsibility: present and emit the boss run trigger
  - `MetaManagerImpl` gains 2 methods scoped to new state; existing methods unchanged
  - `autoload/MetaManager` remains a thin wrapper (no logic added to autoload layer)
  - `Main.gd` gains one handler (`_on_hub_boss_run_pressed`) delegating to existing `_on_boss_teleport_pressed()`

- **II. Data-Driven Content** ✅
  - `boss_run_kill_threshold: 3`, `boss_run_cost: 300`, `boss_run_shard_award: 35` all live in `data/meta_config.json`
  - No numeric constants in `.gd` files

- **III. Mobile-First Performance** ✅
  - No new per-frame work (`_process`/`_physics_process`)
  - Two new `Control` nodes in hub (static UI, no overdraw concern)

- **IV. Editor-Centric Workflow** ✅
  - `BossRunShop.tscn` and `BossRunButton.tscn` created in Editor
  - Added to `HubRoom.tscn` as children in Editor
  - All node refs via `@export var` (no `$NodeName` hardcoding)

- **V. Simplicity & YAGNI** ✅
  - No speculative abstractions; BossRunShop and BossRunButton are concrete, used immediately
  - No base class introduced (only 2 hub shop-type scenes total; existing AdventuringGearShop is not refactored)

- **VI. Early Return** ✅
  - `MetaManager._on_room_cleared`: mode guard is an early `return` at top of boss_room branch
  - `MetaManager._on_run_ended`: mode guard is an early `return` after boss-mode handling
  - `BossRunButton._on_pressed`: `if RunManager.is_run_active: return`

**Verdict**: All principles satisfied. No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/034-hub-boss-run/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/           ← Phase 1 output (GDScript API contracts)
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code

```text
data/
└── meta_config.json          [modified] — 3 new keys

scripts/
├── data_models/
│   └── MetaState.gd          [modified] — 2 new fields
└── managers/
    ├── MetaManager.gd        [modified] — 2 new methods
    └── SaveManager.gd        [modified] — 2 new JSON keys

autoload/
└── MetaManager.gd            [modified] — 2 properties, 1 method, 2 handlers updated

scenes/
├── core/
│   └── main.gd               [modified] — new hub handler, boss room cleared gating
└── hub/
    ├── HubRoom.gd             [modified] — new signal + export
    ├── BossRunShop.gd         [new]
    ├── BossRunShop.tscn       [new — Editor]
    ├── BossRunButton.gd       [new]
    ├── BossRunButton.tscn     [new — Editor]
    └── HubRoom.tscn           [modified — Editor] — add children, assign exports
```

**Structure Decision**: Single Godot project. Hub UI follows existing co-location convention (`scenes/hub/`). All new scripts co-located with their scenes.

## Detailed Design

### 1. `data/meta_config.json`

Add three keys at root level:
```json
"boss_run_kill_threshold": 3,
"boss_run_cost": 300,
"boss_run_shard_award": 35
```

### 2. `scripts/data_models/MetaState.gd`

Add two fields:
```gdscript
var endless_boss_kill_count: int = 0
var boss_run_unlocked: bool = false
```

### 3. `scripts/managers/SaveManager.gd`

In `save_meta_state()` — add two keys to the Dictionary:
```gdscript
"endless_boss_kill_count": state.endless_boss_kill_count,
"boss_run_unlocked": state.boss_run_unlocked,
```

In `load_meta_state()` — add two `.get()` calls (backward compatible, default 0/false):
```gdscript
state.endless_boss_kill_count = int(parsed.get("endless_boss_kill_count", 0))
state.boss_run_unlocked = bool(parsed.get("boss_run_unlocked", false))
```

### 4. `scripts/managers/MetaManager.gd` (MetaManagerImpl)

```gdscript
func increment_endless_boss_kills(save_manager: Node) -> void:
    meta_state.endless_boss_kill_count += 1
    save_manager.save_meta_state(meta_state)

func purchase_boss_run(cost: int, save_manager: Node) -> bool:
    if meta_state.boss_run_unlocked:
        return false
    if not can_spend(cost):
        return false
    meta_state.total_shards -= cost
    meta_state.boss_run_unlocked = true
    save_manager.save_meta_state(meta_state)
    return true
```

### 5. `autoload/MetaManager.gd`

**New properties:**
```gdscript
var is_boss_run_unlocked: bool:
    get: return _impl.meta_state.boss_run_unlocked

var endless_boss_kill_count: int:
    get: return _impl.meta_state.endless_boss_kill_count
```

**New method:**
```gdscript
func purchase_boss_run() -> bool:
    var cost: int = ResourceManager.get_meta_config().get("boss_run_cost", 300)
    var success: bool = _impl.purchase_boss_run(cost, SaveManager)
    if success:
        shards_changed.emit(meta_state.total_shards)
    return success
```

**Modified `_on_room_cleared()`** — add mode guard in boss_room branch:
```gdscript
func _on_room_cleared(room_id: String) -> void:
    if room_id == "boss_room":
        if RunManager.run_mode != "endless":
            return
        var recorded: bool = _impl.record_boss_kill(SaveManager)
        if recorded:
            print("[MetaManager] first boss kill recorded")
        _impl.increment_endless_boss_kills(SaveManager)
        print("[MetaManager] endless boss kills: {n}".format({"n": _impl.meta_state.endless_boss_kill_count}))
        return
    # existing elite room logic unchanged ...
```

**Modified `_on_run_ended()`** — handle boss mode before existing logic:
```gdscript
func _on_run_ended(reason: RunManager.EndReason) -> void:
    if RunManager.run_mode == "boss":
        if reason == RunManager.EndReason.CASH_OUT:
            var award: int = ResourceManager.get_meta_config().get("boss_run_shard_award", 35)
            add_shards(award)
            print("[MetaManager] boss run cash out — {n} shards awarded".format({"n": award}))
        else:
            print("[MetaManager] boss run ended — no shards (died)")
        return
    # existing essence→shard conversion ...
```

### 6. `scenes/hub/BossRunShop.gd`

```gdscript
class_name BossRunShop
extends Control

@export var _button: Button

func _ready() -> void:
    _button.pressed.connect(_on_buy_pressed)
    MetaManager.shards_changed.connect(func(_n: int) -> void: _update_visibility())
    GlobalSignals.hub_entered.connect(func() -> void: _update_visibility())
    _update_visibility()

func _update_visibility() -> void:
    var cfg: Dictionary = ResourceManager.get_meta_config()
    var threshold: int = cfg.get("boss_run_kill_threshold", 3)
    visible = MetaManager.endless_boss_kill_count >= threshold \
              and not MetaManager.is_boss_run_unlocked

func _on_buy_pressed() -> void:
    MetaManager.purchase_boss_run()
    _update_visibility()
```

### 7. `scenes/hub/BossRunButton.gd`

```gdscript
class_name BossRunButton
extends Control

signal boss_run_pressed

@export var _button: Button

func _ready() -> void:
    _button.pressed.connect(_on_pressed)
    MetaManager.shards_changed.connect(func(_n: int) -> void: _update_visibility())
    _update_visibility()

func _update_visibility() -> void:
    visible = MetaManager.is_boss_run_unlocked

func _on_pressed() -> void:
    if RunManager.is_run_active:
        return
    boss_run_pressed.emit()
```

### 8. `scenes/hub/HubRoom.gd`

```gdscript
signal hub_boss_run_pressed

@export var _boss_run_button: BossRunButton

# In _ready():
_boss_run_button.boss_run_pressed.connect(_on_boss_run_pressed)

func _on_boss_run_pressed() -> void:
    hub_boss_run_pressed.emit()
    queue_free()
```

### 9. `scenes/core/main.gd`

**In `_ready()` and `_on_results_return()`** — after hub_room add_child, connect new signal:
```gdscript
_hub_room.hub_boss_run_pressed.connect(_on_hub_boss_run_pressed)
```

**New handler:**
```gdscript
func _on_hub_boss_run_pressed() -> void:
    _hub_room = null
    RunManager.start_run("boss")
    GlobalSignals.gameplay_started.emit()
    _on_boss_teleport_pressed()
```

**Modified `_show_boss_victory_overlay()`** — pass run mode so overlay hides Continue in boss mode:
```gdscript
func _show_boss_victory_overlay() -> void:
    _boss_victory_layer = CanvasLayer.new()
    add_child(_boss_victory_layer)
    _boss_victory_overlay = _BOSS_VICTORY_OVERLAY_SCENE.instantiate() as BossVictoryOverlay
    _boss_victory_layer.add_child(_boss_victory_overlay)
    _boss_victory_overlay.setup(RunManager.run_mode == "endless")
    _boss_victory_overlay.cash_out_pressed.connect(_on_boss_cash_out_pressed)
    _boss_victory_overlay.continue_pressed.connect(_on_boss_continue_pressed)
```

**Modified `_on_boss_room_cleared()`** — gate essence + relic on endless mode:
```gdscript
func _on_boss_room_cleared(_room_id: String) -> void:
    _boss_room_spawner = null
    _exploration_hud.visible = false
    if RunManager.run_mode == "endless":
        var base: float = ResourceManager.get_enemy_base_essence("boss")
        var rooms_cleared: int = RunManager.cleared_rooms.size()
        var reward: int = floori(base * (1.0 + 0.06 * float(maxi(0, rooms_cleared - 6))))
        RunManager.add_currency(reward)
        print("[Main] boss reward — base={b} rooms_cleared={r} reward={w}".format({
            "b": base, "r": rooms_cleared, "w": reward,
        }))
        if RelicManager.trigger_boss_offer():
            _boss_relic_pending = true
            return
    _show_boss_victory_overlay()
```

### 10. `scenes/ui/boss_victory/BossVictoryOverlay.gd`

Add a `setup()` method that controls Continue button visibility:
```gdscript
func setup(show_continue: bool) -> void:
    _continue_button.visible = show_continue
```

Called from `Main._show_boss_victory_overlay()` with `RunManager.run_mode == "endless"`. No changes to the `.tscn` file — the button node remains in the scene; visibility is controlled at runtime.

### 11. Editor Tasks (HubRoom.tscn)

1. Open `HubRoom.tscn` in Godot Editor
2. Create `BossRunShop.tscn`: `Control` root → attach `BossRunShop.gd` → add `Button` child → assign `_button` export
3. Create `BossRunButton.tscn`: `Control` root → attach `BossRunButton.gd` → add `Button` child → assign `_button` export
4. Add both scenes as children of `HubRoom.tscn`
5. Assign `_boss_run_button` export on HubRoom to the BossRunButton instance

## repo_map.md Updates

After implementation, update:
- `MetaState` fields (add `endless_boss_kill_count`, `boss_run_unlocked`)
- `MetaManager` autoload properties (add `is_boss_run_unlocked`, `endless_boss_kill_count`, `purchase_boss_run`)
- `MetaManagerImpl` methods (add `increment_endless_boss_kills`, `purchase_boss_run`)
- `HubRoom` signals (add `hub_boss_run_pressed`), exports (add `_boss_run_button`)
- Add `BossRunShop` and `BossRunButton` entries under Scenes — Hub
