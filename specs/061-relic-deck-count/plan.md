# Implementation Plan: Relic Deck Count

**Branch**: `061-relic-deck-count` | **Date**: 2026-03-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/061-relic-deck-count/spec.md`

## Summary

Add a `deck_count: int` field to every relic in `data/relics.json` and to the `RelicData` data model. Modify `RelicManagerImpl.build_pool()` (and its refill paths) to expand each relic `deck_count` times when constructing the per-tier draw deck, so higher-count relics appear proportionally more often in offers. Simultaneously rename the `sharp_edge` relic ID to `common_damage` — a pure data change with no runtime script impact.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing throughout
**Primary Dependencies**: `RelicManagerImpl`, `RelicData`, `data/relics.json`
**Storage**: JSON flat file (`data/relics.json`) — no save-file impact
**Testing**: GUT unit tests (`tests/unit/`) if applicable; manual DevPanel verification
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: No change — deck construction runs once per run start, not per frame
**Constraints**: `deck_count` must not affect boss relic offers (which need the unique pool)
**Scale/Scope**: 12 relics across 3 tiers; trivial scale

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

- **I. Single Responsibility** ✅ — `RelicData` owns the data model; `RelicManagerImpl` owns pool logic. No responsibility bleed. No new autoloads.
- **II. Data-Driven Content** ✅ — `deck_count` lives in `data/relics.json`; no numeric constants in code. The field is read by `RelicData.from_dict` (typed wrapper) as required.
- **III. Mobile-First** ✅ — Deck expansion is O(N × deck_count) at run start; with 12 relics and max count 3 the deck has at most ~18 entries. Zero runtime cost after construction.
- **IV. Editor-Centric** ✅ — No scene files modified. No `.tscn` changes. No node references affected.
- **V. Simplicity & YAGNI** ✅ — One new field, one new helper method. No abstractions introduced for a single call site.
- **VI. Early Return** ✅ — `_build_expanded_deck` uses a `continue` guard for `exclude_id`. No nesting beyond depth 1 in the new code.

**Result**: All principles satisfied. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/061-relic-deck-count/
├── plan.md          ← this file
├── research.md      ← Phase 0 output
├── data-model.md    ← Phase 1 output
├── quickstart.md    ← Phase 1 output
└── tasks.md         ← Phase 2 output (/speckit.tasks)
```

### Source Code (affected files only)

```text
data/
└── relics.json                          # Add deck_count; rename sharp_edge → common_damage

scripts/
├── data_models/
│   └── RelicData.gd                     # Add deck_count field + from_dict parse
└── managers/
    └── RelicManagerImpl.gd              # Add _build_expanded_deck; update 3 call sites
```

**Structure Decision**: Single-project layout. No new files or directories. Changes are localised to the data layer and one manager script.

## Phase 0: Research

See [research.md](research.md) — all decisions resolved, no NEEDS CLARIFICATION remaining.

Key decisions:
1. `_all_by_tier` stays unique; expansion happens only in `_build_expanded_deck` helper.
2. `deck_count` default = 1 (backward-compatible).
3. Rename is a pure JSON key change — zero runtime code impact.
4. Boss offers (`draw_boss_offer`) are unaffected by `deck_count`.

## Phase 1: Design & Contracts

See [data-model.md](data-model.md) for full field tables and pseudocode.

### Summary of changes

**`data/relics.json`**
- Rename key `sharp_edge` → `common_damage` (no stat changes).
- Add `"deck_count": N` to every relic entry per the table in `data-model.md`.

**`scripts/data_models/RelicData.gd`**
- Add `var deck_count: int = 1`
- In `from_dict`: `r.deck_count = int(data.get("deck_count", 1))`

**`scripts/managers/RelicManagerImpl.gd`**
- Add `_build_expanded_deck(tier: String, exclude_id: String = "") -> Array[RelicData]`
- `build_pool`: replace manual shuffle loop with `_build_expanded_deck`
- `_draw_one_from_tier` refill path: replace `refill.assign(...)` + `shuffle()` with `_build_expanded_deck`
- `draw_offer` de-dup refill path: replace manual filter + shuffle with `_build_expanded_deck(tier, left.id)`

### No contracts directory

This feature has no external API surface (no HTTP endpoints, no cross-engine interfaces). The `contracts/` directory is omitted per the "include only when relevant" rule.
