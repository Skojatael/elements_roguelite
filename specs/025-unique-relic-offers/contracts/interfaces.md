# Contracts: Unique Relic Offers

**Feature**: 025-unique-relic-offers
**Date**: 2026-03-03

---

## RelicManagerImpl (scripts/managers/RelicManagerImpl.gd) — MODIFIED

### draw_offer() — rewritten

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

**Removed**: the `_relics_by_id.size() == 1` branch (unreachable under FR-003).

**Behaviour**:
- `_draw_one()` is called unchanged for both draws.
- The exclusion-refill only executes when left's tier deck is exhausted after the left draw.
- FR-003 guarantees the refilled deck always has at least 1 relic (tier has 2+, one excluded).
- The exclusion is offer-scoped: `_decks[left.tier]` is left in normal state for subsequent offers.

---

## All other methods — UNCHANGED

`_draw_one()`, `build_pool()`, `reset()`, `compute_stat_mult()`, `get_hit_damage_mult()`, `should_offer_for_room()`, `pick_relic()` — no changes.
