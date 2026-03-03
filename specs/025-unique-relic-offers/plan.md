# Implementation Plan: Unique Relic Offers

**Branch**: `025-unique-relic-offers` | **Date**: 2026-03-03 | **Spec**: [spec.md](spec.md)

## Summary

Rewrite `draw_offer()` in `RelicManagerImpl` to draw sequentially — left first, then right — with an exhaustion-refill-excluding-left step between draws. This structurally guarantees the two offered relics are always different without ID comparison, retry loops, or changes to `_draw_one()`. FR-003 (every tier must have 2+ relics) makes the exclusion-refill always produce a non-empty deck.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing
**Primary Dependencies**: RelicManagerImpl (existing)
**Storage**: `data/relics.json` (existing — no changes)
**Testing**: Manual — see quickstart.md
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: One array filter (size ≤ tier relic count, max ~10) per offer when a tier deck exhausts — negligible
**Constraints**: No new files; no new autoloads; no scene changes; one method rewritten
**Scale/Scope**: 1 method rewritten in 1 file (`draw_offer()` in RelicManagerImpl.gd)

## Constitution Check

- **I. Single Responsibility**: Change is entirely within `RelicManagerImpl.draw_offer()` — the correct owner of offer logic. ✅
- **II. Data-Driven Content**: No new constants. FR-003 is a data authoring rule, not a hardcoded value. ✅
- **III. Mobile-First**: One array filter over a small set (≤ tier size) executed at most once per offer. Negligible cost. ✅
- **IV. Editor-Centric**: No scene changes. ✅
- **V. Simplicity & YAGNI**: Single method rewrite, no new abstractions, no retry loops, no new parameters on `_draw_one()`. ✅

## Project Structure

```text
specs/025-unique-relic-offers/
├── plan.md              ← this file
├── research.md          ✅
├── data-model.md        ✅
├── quickstart.md        ✅
├── contracts/
│   └── interfaces.md    ✅
└── tasks.md             ← /speckit.tasks output

Source changes:
scripts/managers/RelicManagerImpl.gd    [MODIFIED] draw_offer() rewritten
```

## Implementation

### Sequential draw mechanism

The sentence removed from the spec belongs here:

> Drawing is sequential — left first, then right. After the left draw, if that tier's deck is exhausted, it is refilled from `_all_by_tier` excluding the left relic's ID before the right draw proceeds. This guarantees the right draw can never produce the same relic as the left draw, with no special-case branches needed — because FR-003 ensures the exclusion-refill always leaves at least one relic in the deck.

### draw_offer() — full rewrite

```gdscript
## Returns Array[RelicData] of exactly 2 distinct entries.
## Empty if no relics defined.
## Left relic is drawn first; if its tier deck exhausts, it is refilled
## excluding the left relic before right is drawn — guaranteeing uniqueness.
func draw_offer() -> Array[RelicData]:
    if _relics_by_id.is_empty():
        return []
    var left: RelicData = _draw_one()
    if (_decks[left.tier] as Array).is_empty():
        var refill: Array[RelicData] = []
        for r: RelicData in (_all_by_tier[left.tier] as Array):
            if r.id != left.id:
                refill.append(r)
        refill.shuffle()
        _decks[left.tier] = refill
    var right: RelicData = _draw_one()
    return [left, right]
```

**What changed vs current**:
- `_relics_by_id.size() == 1` branch removed (unreachable under FR-003)
- `return [_draw_one(), _draw_one()]` replaced with sequential draw + conditional exhaustion-refill-excluding-left
- `_draw_one()` itself is unchanged
