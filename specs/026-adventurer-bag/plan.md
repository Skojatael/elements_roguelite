# Implementation Plan: Adventurer Bag

**Branch**: `026-adventurer-bag` | **Date**: 2026-03-03 | **Spec**: [spec.md](spec.md)

## Summary

Add a permanent meta-unlock called "Adventurer Bag" that gates the relic offer system. The unlock fires once — when the player clears an elite room for the first time across all runs. It is stored in `MetaState` and persisted by `SaveManagerImpl`. `MetaManager` detects the elite clear via the existing `RunManager.room_cleared` signal. `RelicManager` checks the unlock flag before emitting any offer. No new autoloads, no new scenes, no UI in this feature.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing
**Primary Dependencies**: MetaManagerImpl, SaveManagerImpl, RelicManager, MetaState (all existing)
**Storage**: `user://meta_save.json` (existing) — one new key `adventurer_bag_unlocked`
**Testing**: Manual — see quickstart.md
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: One boolean field read per room clear — negligible
**Constraints**: No new autoloads; no new scenes; no UI; four files modified, one field added to one data class
**Scale/Scope**: 4 files modified; 1 field added to MetaState; ~15 lines of new code total

## Constitution Check

- **I. Single Responsibility**: MetaManager owns meta-progression — detecting the first elite clear and persisting the unlock belongs squarely in its domain. RelicManager only reads a boolean from MetaManager — no logic added there. MetaManagerImpl gets one method. Thin-wrapper rule maintained throughout. ✅
- **II. Data-Driven Content**: The unlock flag is runtime state, not content balance — correct to store in MetaState rather than JSON. No hardcoded balance values introduced. ✅
- **III. Mobile-First**: One boolean check per room clear. No new allocations, no new nodes. Negligible cost. ✅
- **IV. Editor-Centric**: No scene changes. No `.tscn` files touched. ✅
- **V. Simplicity & YAGNI**: No new abstractions, no new signal, no new autoload. Four surgical edits covering the minimum surface to meet all six FRs. ✅

## Project Structure

```text
specs/026-adventurer-bag/
├── plan.md              ← this file
├── research.md          ✅
├── data-model.md        ✅
├── quickstart.md        ✅
├── contracts/
│   └── interfaces.md    ✅
└── tasks.md             ← /speckit.tasks output

Source changes:
scripts/data_models/MetaState.gd      [MODIFIED] add adventurer_bag_unlocked field
scripts/managers/SaveManager.gd       [MODIFIED] serialize/deserialize new field
scripts/managers/MetaManager.gd       [MODIFIED] add unlock_adventurer_bag()
autoload/MetaManager.gd               [MODIFIED] add property + room_cleared handler
autoload/RelicManager.gd              [MODIFIED] add gate in _on_room_cleared()
```

## Implementation

### MetaState — one new field

```gdscript
var adventurer_bag_unlocked: bool = false
```

Write-once: set to `true` on first elite clear, never reset. MetaManagerImpl enforces the invariant.

### SaveManagerImpl — backward-compatible persistence

`save_meta_state` adds `"adventurer_bag_unlocked": state.adventurer_bag_unlocked` to the dict.
`load_meta_state` reads it with `.get("adventurer_bag_unlocked", false)` — missing key silently defaults.

### MetaManagerImpl — unlock method

```gdscript
func unlock_adventurer_bag(save_manager: Node) -> bool:
    if meta_state.adventurer_bag_unlocked:
        return false
    meta_state.adventurer_bag_unlocked = true
    save_manager.save_meta_state(meta_state)
    return true
```

Returns `true` only on the first call (state changed). Idempotent on all subsequent calls.

### MetaManager autoload — property + handler

Computed property (thin wrapper over impl.meta_state):
```gdscript
var is_adventurer_bag_unlocked: bool:
    get: return _impl.meta_state.adventurer_bag_unlocked
```

New connection in `_ready()`:
```gdscript
RunManager.room_cleared.connect(_on_room_cleared)
```

New handler:
```gdscript
func _on_room_cleared(room_id: String) -> void:
    if RunManager.current_room == null:
        return
    var room_type: String = (RunManager.current_room as RoomSpawner).room_type_id
    if not room_type.contains("Elite"):
        return
    var unlocked: bool = _impl.unlock_adventurer_bag(SaveManager)
    if unlocked:
        print("[MetaManager] Adventurer Bag unlocked — room_id={id}".format({"id": room_id}))
```

### RelicManager autoload — gate

```gdscript
func _on_room_cleared(room_id: String) -> void:
    if not MetaManager.is_adventurer_bag_unlocked:   # ← new first line
        return
    if not RunManager.is_run_active:
        return
    # ... rest unchanged
```

The gate is the first check — cheapest possible fast path when locked.
