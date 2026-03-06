# Implementation Plan: DevPanel Start Boss

**Branch**: `031-devpanel-start-boss` | **Date**: 2026-03-05 | **Spec**: specs/031-devpanel-start-boss/spec.md

## Summary

Replace the stub DevPanel "Start Boss" handler in Main.gd with a real implementation. If no run is active, start one first. Then call the existing `_on_boss_teleport_pressed()` method. Guard against pressing while already in the boss room or while the victory overlay is showing.

## Technical Context

**Language/Version**: GDScript, Godot 4.6
**Primary Dependencies**: `RunManager.is_run_active`, `RunManager.start_run()`, `_on_boss_teleport_pressed()` (feature 029), `_boss_room_spawner` / `_boss_victory_layer` guards (feature 030)
**Storage**: N/A
**Testing**: Manual (quickstart.md, 5 scenarios)
**Target Platform**: Android mobile (portrait); Windows dev
**Project Type**: Single Godot project
**Performance Goals**: Same-frame teleport
**Constraints**: No new files; no new autoloads; change is confined to Main.gd
**Scale/Scope**: 1 method replaced + 1 method added in scenes/core/Main.gd

## Constitution Check

- **I. Single Responsibility** ✅ `_on_dev_start_boss()` owns only DevPanel guard + delegation; no logic duplication.
- **II. Data-Driven Content** ✅ No balance constants introduced.
- **III. Mobile-First** ✅ No rendering or physics impact.
- **IV. Editor-Centric** ✅ No scene changes; no raw .tscn edits.
- **V. Simplicity & YAGNI** ✅ Reuses `_on_boss_teleport_pressed()` — no new abstraction.
- **VI. Early Return** ✅ Two guard clauses at top of `_on_dev_start_boss()`.

## Project Structure

### Source Code

```text
scenes/core/
└── Main.gd    (MODIFIED — stub lambda replaced, _on_dev_start_boss() added)
```

No new files. No other files modified.

## Implementation

### Step 1 — Replace stub lambda in _ready()

```gdscript
# Before:
panel.start_boss_pressed.connect(func(): print("[DevPanel] start_boss pressed — stub"))

# After:
panel.start_boss_pressed.connect(_on_dev_start_boss)
```

### Step 2 — Add _on_dev_start_boss() alongside _on_dev_get_relic()

```gdscript
func _on_dev_start_boss() -> void:
    if _boss_room_spawner != null:
        return
    if _boss_victory_layer != null:
        return
    if not RunManager.is_run_active:
        RunManager.start_run("endless")
    _on_boss_teleport_pressed()
```

**Guard explanations**:
- `_boss_room_spawner != null` — boss room is currently active; a second spawn would corrupt state.
- `_boss_victory_layer != null` — victory overlay is showing; teleporting now would free an in-progress overlay incorrectly.
- `not RunManager.is_run_active` — hub is still showing; starting a run first causes `_on_run_started()` to free the hub synchronously before the teleport proceeds.
