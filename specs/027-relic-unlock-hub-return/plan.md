# Implementation Plan: Relic Offers Activate on Hub Return

**Branch**: `027-relic-unlock-hub-return` | **Date**: 2026-03-03 | **Spec**: [spec.md](spec.md)

## Summary

Add `relic_offers_active` as a second persistent meta flag. It is set on the player's first hub visit after `adventurer_bag_unlocked` is `true`. `GlobalSignals.hub_entered` is the new cross-system signal emitted by `Main.gd` whenever the HubRoom is instantiated. `MetaManager` connects to it and calls `MetaManagerImpl.try_activate_relic_offers()`. `RelicManager` swaps its offer gate from `is_adventurer_bag_unlocked` to `is_relic_offers_active`. No new autoloads, no scene changes, seven files touched.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing
**Primary Dependencies**: MetaManagerImpl, SaveManagerImpl, GlobalSignals, RelicManager, MetaState, Main.gd (all existing)
**Storage**: `user://meta_save.json` (existing) — one new key `relic_offers_active`
**Testing**: Manual — see quickstart.md
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: One boolean field read per room clear, one signal emission per hub instantiation — negligible
**Constraints**: No new autoloads; no new scenes; no UI; 7 files modified; ~20 lines of new code total
**Scale/Scope**: 7 files modified; 1 field added to MetaState; 1 signal added to GlobalSignals; ~20 lines new code

## Constitution Check

- **I. Single Responsibility**: MetaManager owns meta-progression — hub activation belongs there. GlobalSignals owns cross-system events — `hub_entered` belongs there. Main.gd emits it as the sole owner of HubRoom instantiation. RelicManager just reads a boolean. MetaManagerImpl gets one method. Thin-wrapper rule maintained. ✅
- **II. Data-Driven Content**: `relic_offers_active` is runtime state, not content balance — correct in MetaState. ✅
- **III. Mobile-First**: One boolean check per room clear; one signal emit per hub enter (rare). Negligible cost. ✅
- **IV. Editor-Centric**: No scene structural changes. Two `emit()` calls added to `Main.gd` (a script). ✅
- **V. Simplicity & YAGNI**: Minimal surface — one new signal, one new flag, one new method. The `hub_entered` signal has an immediate concrete need and no speculative consumers. ✅

## Project Structure

```text
specs/027-relic-unlock-hub-return/
├── plan.md              ← this file
├── research.md          ✅
├── data-model.md        ✅
├── quickstart.md        ✅
├── contracts/
│   └── interfaces.md    ✅
└── tasks.md             ← /speckit.tasks output

Source changes:
scripts/data_models/MetaState.gd      [MODIFIED] add relic_offers_active field
scripts/managers/SaveManager.gd       [MODIFIED] serialize/deserialize new field
scripts/managers/MetaManager.gd       [MODIFIED] add try_activate_relic_offers()
autoload/MetaManager.gd               [MODIFIED] add property + hub_entered handler + connection
autoload/GlobalSignals.gd             [MODIFIED] add hub_entered signal
scenes/core/Main.gd                   [MODIFIED] emit hub_entered in _ready() + _on_results_return()
autoload/RelicManager.gd              [MODIFIED] swap gate to is_relic_offers_active
```

## Implementation

### State machine

```
adventurer_bag_unlocked=false, relic_offers_active=false  ← initial
    [first elite clear] → MetaManagerImpl.unlock_adventurer_bag()
adventurer_bag_unlocked=true, relic_offers_active=false
    [first hub visit while bag=true] → MetaManagerImpl.try_activate_relic_offers()
adventurer_bag_unlocked=true, relic_offers_active=true    ← permanent active state
```

### GlobalSignals — new signal

```gdscript
@warning_ignore("unused_signal")
signal hub_entered()
```

### Main.gd — two emission sites

In `_ready()`, after `add_child(_hub_room)`:
```gdscript
GlobalSignals.hub_entered.emit()
```

In `_on_results_return()`, after `add_child(_hub_room)`:
```gdscript
GlobalSignals.hub_entered.emit()
```

### MetaManagerImpl — try_activate_relic_offers()

```gdscript
func try_activate_relic_offers(save_manager: Node) -> bool:
    if not meta_state.adventurer_bag_unlocked:
        return false
    if meta_state.relic_offers_active:
        return false
    meta_state.relic_offers_active = true
    save_manager.save_meta_state(meta_state)
    return true
```

Idempotent. Returns `true` only on the first call that transitions the flag.

### MetaManager autoload — property + connection + handler

```gdscript
var is_relic_offers_active: bool:
    get: return _impl.meta_state.relic_offers_active
```

In `_ready()`:
```gdscript
GlobalSignals.hub_entered.connect(_on_hub_entered)
```

Handler:
```gdscript
func _on_hub_entered() -> void:
    var activated: bool = _impl.try_activate_relic_offers(SaveManager)
    if activated:
        print("[MetaManager] relic offers activated — first hub return after Adventurer Bag unlock")
```

### RelicManager — gate swap

```gdscript
func _on_room_cleared(room_id: String) -> void:
    if not MetaManager.is_relic_offers_active:   # was: is_adventurer_bag_unlocked
        return
    # ... rest unchanged
```

### Backward compatibility

If `meta_save.json` has `adventurer_bag_unlocked: true` but no `relic_offers_active` key: on game start, `Main._ready()` emits `hub_entered` → `MetaManager._on_hub_entered()` → `try_activate_relic_offers()` returns `true` → flag set and saved immediately. Player gets relic offers on their next run with no extra steps required.
