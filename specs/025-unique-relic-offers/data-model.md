# Data Model: Unique Relic Offers

**Feature**: 025-unique-relic-offers
**Date**: 2026-03-03

---

## Runtime State — No changes

No new fields. No new state. The exclusion-refill is a transient operation inside `draw_offer()` — it modifies `_decks[tier]` in place, which is already mutable draw state.

---

## draw_offer() Flow (after this feature)

```
draw_offer() called
  ├─ _relics_by_id.is_empty() → return []
  ├─ left = _draw_one()            # pops left relic from its tier deck
  ├─ if _decks[left.tier] is empty:
  │    refill = _all_by_tier[left.tier] filtered to exclude left.id
  │    refill.shuffle()
  │    _decks[left.tier] = refill  # deck ready for right draw, left relic absent
  └─ right = _draw_one()           # guaranteed different: left relic not in any deck
     return [left, right]
```

**Contrast with previous flow**:
```
# Old (could duplicate):
return [_draw_one(), _draw_one()]
```

---

## Data Integrity Constraint (FR-003)

Every tier in `data/relics.json` MUST contain at least 2 entries. Current state:

| Tier | Count | Compliant |
|---|---|---|
| common | 4 | ✅ |
| uncommon | 4 | ✅ |
| rare | 2 | ✅ |

Adding a new tier with only 1 relic would violate FR-003 and break the uniqueness guarantee.
