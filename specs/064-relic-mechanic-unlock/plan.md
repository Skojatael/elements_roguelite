# Implementation Plan: Relic Mechanic Unlock Tags

**Branch**: `064-relic-mechanic-unlock` | **Date**: 2026-03-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/064-relic-mechanic-unlock/spec.md`

## Summary

Extend `RelicManagerImpl` with run-scoped mechanic activation tracking. When a relic carrying a mechanic tag (e.g. `"burn"`) is picked, that tag is recorded as active. Subsequent offer draws exclude relics gated by that tag and include relics tagged `"burn_unlocked"`. Which tags count as mechanic gates is derived automatically from the pool: a tag is a mechanic gate only if a `<tag>_unlocked` relic exists in `relics.json`. Two stub `_unlocked` relics (`burn_damage`, `chain_reach`) are added to the JSON to exercise the system.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `RelicManagerImpl` (RefCounted), `RelicData` (RefCounted), `relics.json`
**Storage**: N/A (run-scoped in-memory state only; no persistence required)
**Testing**: GUT unit tests in `tests/unit/test_relic_deck.gd`
**Target Platform**: Android mobile (portrait); Windows dev
**Performance Goals**: No draw-time overhead beyond existing O(n) deck filtering
**Constraints**: All tag classification logic must be data-driven from `relics.json`; no hard-coded mechanic names in GDScript
**Scale/Scope**: ~3 new methods + 2 new fields in `RelicManagerImpl`; 2 new JSON entries; ~10 new unit tests

## Constitution Check

- **I. Single Responsibility** ✅ — All logic in `RelicManagerImpl` (the algorithmic impl). `RelicManager` autoload unchanged (thin wrapper). `RelicData` unchanged (data model only).
- **II. Data-Driven Content** ✅ — Which tags are mechanic gates is determined entirely by `relics.json` (presence of `_unlocked` relics). No hard-coded tag names in GDScript.
- **III. Mobile-First** ✅ — `_is_relic_eligible` is an O(tags) check, called only on deck rebuild (not per-frame). Negligible overhead.
- **IV. Editor-Centric** ✅ — No scenes, nodes, or `.tscn` files modified.
- **V. Simplicity & YAGNI** ✅ — No new abstractions or base classes. Two new fields and three new methods on the existing impl class.
- **VI. Early Return** ✅ — `_is_relic_eligible` and `pick_relic` exit early on first unmet precondition; loop bodies use `continue` pattern.

## Project Structure

### Documentation (this feature)

```text
specs/064-relic-mechanic-unlock/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (affected files only)

```text
data/
└── relics.json                          # add burn_damage, chain_reach entries

scripts/
└── managers/
    └── RelicManagerImpl.gd              # core logic changes

tests/
└── unit/
    └── test_relic_deck.gd               # new mechanic-unlock test cases
```

No new files. No scene changes. No autoload changes.

## Implementation Detail

### RelicManagerImpl.gd changes

**New fields**:

```gdscript
var _activated_mechanics: Array[String] = []
var _mechanic_tag_names: Array[String] = []
```

**`reset()` extension** — add two lines at end of existing reset body:

```gdscript
_activated_mechanics = []
_mechanic_tag_names = []
```

**`build_pool()` extension** — after the existing tier/relic loop, call `_compute_mechanic_tags()`:

```gdscript
func _compute_mechanic_tags() -> void:
    _mechanic_tag_names = []
    for r: RelicData in _relics_by_id.values():
        for tag: String in r.tags:
            if not tag.ends_with("_unlocked"):
                continue
            var mechanic: String = tag.left(tag.length() - "_unlocked".length())
            if _mechanic_tag_names.has(mechanic):
                continue
            _mechanic_tag_names.append(mechanic)
```

**`_is_relic_eligible(r: RelicData) -> bool`** — new private method:

```gdscript
func _is_relic_eligible(r: RelicData) -> bool:
    for tag: String in r.tags:
        if tag.ends_with("_unlocked"):
            var mechanic: String = tag.left(tag.length() - "_unlocked".length())
            if not _activated_mechanics.has(mechanic):
                return false
        elif _mechanic_tag_names.has(tag) and _activated_mechanics.has(tag):
            return false
    return true
```

**`_build_expanded_deck()` extension** — add eligibility guard inside the existing `for r` loop:

```gdscript
# existing loop body — add early continue before deck_count inner loop:
if not _is_relic_eligible(r):
    continue
```

**`pick_relic()` extension** — after `active_relic_ids.append(relic_id)`, record activated mechanics:

```gdscript
var relic: Variant = _relics_by_id.get(relic_id)
if not relic is RelicData:
    return
for tag: String in (relic as RelicData).tags:
    if not _mechanic_tag_names.has(tag):
        continue
    if _activated_mechanics.has(tag):
        continue
    _activated_mechanics.append(tag)
    print("[RelicManager] mechanic activated — tag={tag}".format({"tag": tag}))
```

**`draw_boss_offer()` extension** — add eligibility guard inside the `for r` loop:

```gdscript
# existing guard: if not active_relic_ids.has(r.id)
# add second guard:
if not _is_relic_eligible(r):
    continue
```

### relics.json changes

Add under `"uncommon"` tier alongside `chaining_stone`, `burn`, `crit_projectile`:

```json
"burn_damage": {
    "name": "Searing Seal",
    "tags": ["burn_unlocked"],
    "effect_stat": "",
    "effect_mult": 1.0,
    "description": "Burning enemies take 50% more damage while burning.",
    "deck_count": 1
},
"chain_reach": {
    "name": "Arc Shard",
    "tags": ["chain_unlocked"],
    "effect_stat": "",
    "effect_mult": 1.0,
    "description": "Chain strikes can reach a third target for 25% damage.",
    "deck_count": 1
}
```

### test_relic_deck.gd additions

New stub pool with mechanic pairs:

```gdscript
const STUB_RELICS_MECHANIC: Dictionary = {
    "relics": {
        "uncommon": {
            "burn": {"name": "Burn", "tags": ["burn"], "effect_stat": "", "effect_mult": 1.0, "deck_count": 1},
            "burn_damage": {"name": "Burn Dmg", "tags": ["burn_unlocked"], "effect_stat": "", "effect_mult": 1.0, "deck_count": 1},
            "chain": {"name": "Chain", "tags": ["chain"], "effect_stat": "", "effect_mult": 1.0, "deck_count": 1},
            "chain_reach": {"name": "Chain Reach", "tags": ["chain_unlocked"], "effect_stat": "", "effect_mult": 1.0, "deck_count": 1},
            "generic": {"name": "Generic", "tags": ["combat"], "effect_stat": "attack_damage", "effect_mult": 1.1, "deck_count": 1},
        }
    }
}
```

New test cases:
- `test_unlocked_relic_absent_before_mechanic_activated` — fresh pool: `burn_damage` not in deck.
- `test_mechanic_relic_excluded_after_activation` — after `pick_relic("burn")` + reshuffle: `burn` not in deck.
- `test_unlocked_relic_present_after_mechanic_activated` — after `pick_relic("burn")` + reshuffle: `burn_damage` in deck.
- `test_non_mechanic_tag_does_not_activate_mechanic` — `generic` relic has `"combat"` tag; picking it does not add `combat` to `_activated_mechanics`.
- `test_mechanic_pairs_independent` — picking `burn` does not affect `chain` or `chain_reach` eligibility.
- `test_both_mechanics_unlock_both` — picking both `burn` and `chain` makes both `burn_damage` and `chain_reach` eligible.
- `test_boss_offer_respects_mechanic_eligibility` — `draw_boss_offer()` excludes unlocked relics when mechanic not active.

## Quickstart

No scene or editor work required. Implementation is pure GDScript + JSON:

1. Edit `data/relics.json` — add `burn_damage` and `chain_reach` under `"uncommon"`.
2. Edit `scripts/managers/RelicManagerImpl.gd` — add fields, methods, and inline guards per above.
3. Edit `tests/unit/test_relic_deck.gd` — add stub pool constant and new test functions.
4. Run GUT tests: Godot Editor → GUT panel → run `test_relic_deck.gd`.
5. Manual validation: Start run, pick `burn` relic, trigger next offer, verify `burn` absent and `burn_damage` present.
