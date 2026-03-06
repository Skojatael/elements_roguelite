# Implementation Plan: Close Relic Offer on Run End

**Branch**: `028-close-offer-on-run-end` | **Date**: 2026-03-03 | **Spec**: [spec.md](spec.md)

## Summary

When a run ends while a relic offer is open, the offer's CanvasLayer must be freed before the results screen is shown. `Main._on_run_ended()` already owns both the relic offer layer and the results screen. Add one null-guard free block at the top of that method — identical to the existing `_hub_room` guard pattern. One file, four lines.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing
**Primary Dependencies**: Main.gd (existing)
**Storage**: N/A — no persistent state changes
**Testing**: Manual — see quickstart.md
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: Null check on every run end — negligible
**Constraints**: No new files; no new autoloads; no scene changes; one method modified
**Scale/Scope**: 1 method in 1 file; 4 lines added

## Constitution Check

- **I. Single Responsibility**: `Main._on_run_ended()` already owns both the relic offer layer and the results screen. Adding the offer cleanup here keeps all run-end UI teardown in one place. ✅
- **II. Data-Driven Content**: No content changes. ✅
- **III. Mobile-First**: One null check per run end — negligible. ✅
- **IV. Editor-Centric**: No scene changes. ✅
- **V. Simplicity & YAGNI**: Four lines. No new abstraction. Mirrors the existing `_hub_room` guard pattern already in the same method. ✅

## Project Structure

```text
specs/028-close-offer-on-run-end/
├── plan.md              ← this file
├── research.md          ✅
├── quickstart.md        ✅
├── contracts/
│   └── interfaces.md    ✅
└── tasks.md             ← /speckit.tasks output

Source changes:
scenes/core/Main.gd    [MODIFIED] _on_run_ended() gains relic offer guard
```

## Implementation

### Main._on_run_ended() — guard added

```gdscript
func _on_run_ended(_reason: RunManager.EndReason) -> void:
    if _relic_offer_layer != null:          # ← NEW (4 lines)
        _relic_offer_layer.queue_free()
        _relic_offer_layer = null
        _relic_offer_screen = null
    if is_instance_valid(_hub_room):        # existing
        _hub_room.queue_free()
        _hub_room = null
    _player.visible = false
    # ... rest unchanged
```

**Why this order**: Offer is freed first so the CanvasLayer is gone before the results screen CanvasLayer is created. Avoids any z-order overlap.

**Why no `pick_relic()` call**: FR-002. The run is ending; no relic should be awarded. `RelicManager._on_run_ended()` will reset the pool anyway.

**Pattern match**: Identical structure to the `_hub_room` guard two lines below. Both check non-null, call `queue_free()`, null both refs.
