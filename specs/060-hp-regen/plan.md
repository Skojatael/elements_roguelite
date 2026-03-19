# Implementation Plan: HP Regeneration

**Branch**: `060-hp-regen` | **Date**: 2026-03-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/060-hp-regen/spec.md`

## Summary

Add a passive HP regeneration mechanic to the player, driven by a new `common_regen` relic in `data/relics.json`. The regen tick lives in `StatsComponent._process()`, uses the existing `RelicManager.get_stat_addend("hp_regen")` additive path, and is guarded by `RunManager.is_run_active`. Only two files change; no new scripts, scenes, or editor work are required.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: RelicManager (autoload), RunManager (autoload), StatsComponent
**Storage**: `data/relics.json` (existing file, new entry only)
**Testing**: Manual in-editor playtest; DevPanel relic trigger
**Target Platform**: Android mobile portrait 1080×1920; Windows dev
**Project Type**: Single Godot project (mobile roguelite)
**Performance Goals**: 60 fps on mid-range Android; regen tick is O(1) per frame
**Constraints**: Mobile renderer; Jolt physics; no new autoloads
**Scale/Scope**: Player-only; single relic; additive stacking for future regen sources

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Single Responsibility** ✅ — Regen tick lives in `StatsComponent`, which already owns HP. No new autoload. No responsibility bleed into RunManager or RelicManager.
- **II. Data-Driven Content** ✅ — Regen rate (0.01) is stored in `data/relics.json`. No numeric constant in GDScript.
- **III. Mobile-First** ✅ — `_process()` addition is O(1): one `get_stat_addend` call (linear in active_relic_ids, typically ≤5), one multiply, one `minf`. Negligible on any hardware.
- **IV. Editor-Centric** ✅ — No new scenes or node hierarchy changes. StatsComponent is already attached in Player.tscn; no Inspector changes required.
- **V. Simplicity & YAGNI** ✅ — No new component, no new abstraction. Regen tick added directly to existing `StatsComponent`. Two files changed total.
- **VI. Early Return** ✅ — `_process()` exits at first unmet guard: `not is_player`, `not is_run_active`, `rate <= 0.0`, `current_health >= max_health`.

## Project Structure

### Documentation (this feature)

```text
specs/060-hp-regen/
├── plan.md          ← this file
├── research.md      ← Phase 0 output
├── data-model.md    ← Phase 1 output
├── quickstart.md    ← Phase 1 output
└── tasks.md         ← Phase 2 output (/speckit.tasks)
```

### Source Code (modified files only)

```text
data/
└── relics.json                              ← add common_regen entry

scenes/player/components/
└── StatsComponent.gd                        ← add _process(delta) regen tick
```

No new files. No contracts directory (no API surface — game-internal mechanic).
