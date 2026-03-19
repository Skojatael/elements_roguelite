# Data Model: Relic Deck Count

## Modified Entity: RelicData

**File**: `scripts/data_models/RelicData.gd`

| Field | Type | Default | Source | Notes |
|---|---|---|---|---|
| `id` | `String` | `""` | JSON key | Unchanged |
| `name` | `String` | `""` | `"name"` | Unchanged |
| `tier` | `String` | `"common"` | parent key | Unchanged |
| `tags` | `Array[String]` | `[]` | `"tags"` | Unchanged |
| `effect_stat` | `String` | `""` | `"effect_stat"` | Unchanged |
| `effect_mult` | `float` | `1.0` | `"effect_mult"` | Unchanged |
| `description` | `String` | `""` | `"description"` | Unchanged |
| **`deck_count`** | **`int`** | **`1`** | **`"deck_count"`** | **NEW — number of copies in offer pool** |

**Change to `from_dict`**: add `r.deck_count = int(data.get("deck_count", 1))`.

---

## Modified Data File: `data/relics.json`

### Schema change

Every relic entry gains a `deck_count` integer field:

```json
"<relic_id>": {
  "name": "...",
  "tags": [...],
  "effect_stat": "...",
  "effect_mult": 1.0,
  "description": "...",
  "deck_count": N
}
```

### Rename

`"sharp_edge"` key → `"common_damage"`. All other fields (name, tags, effect, description) are unchanged.

### Initial `deck_count` values

| ID | Tier | `deck_count` |
|---|---|---|
| `common_damage` (was `sharp_edge`) | common | 3 |
| `swift_strike` | common | 3 |
| `iron_hide` | common | 3 |
| `feather` | common | 3 |
| `common_regen` | common | 1 |
| `chaining_stone` | uncommon | 1 |
| `burn` | uncommon | 1 |
| `crit_projectile` | uncommon | 1 |
| `rage_crystal` | rare | 1 |
| `vital_core` | rare | 1 |
| `berserker_stone` | rare | 1 |
| `executioners_mark` | rare | 1 |

*Design note*: all common relics except `common_regen` are set to 3 because they represent the bread-and-butter stat boosts. `common_regen` is a stronger mechanic and is intentionally rarer (1). All uncommon and rare relics are 1 — their power level justifies lower frequency.

---

## Modified Component: RelicManagerImpl

**File**: `scripts/managers/RelicManagerImpl.gd`

### New helper method

```gdscript
## Builds a shuffled deck for the given tier, including each relic deck_count times.
## exclude_id: if non-empty, that relic is excluded (used for second-draw de-dup).
func _build_expanded_deck(tier: String, exclude_id: String = "") -> Array[RelicData]:
    var result: Array[RelicData] = []
    for r: RelicData in (_all_by_tier[tier] as Array[RelicData]):
        if r.id == exclude_id:
            continue
        for _i: int in r.deck_count:
            result.append(r)
    result.shuffle()
    return result
```

### Changes to `build_pool`

Replace the deck-building loop (lines 37–41) to call `_build_expanded_deck` instead of plain shuffle:

```gdscript
_decks = {}
for tier: Variant in _all_by_tier.keys():
    _decks[str(tier)] = _build_expanded_deck(str(tier))
```

### Changes to `_draw_one_from_tier` (refill path)

Replace the `refill.assign(_all_by_tier[tier])` + `refill.shuffle()` lines with:

```gdscript
_decks[tier] = _build_expanded_deck(tier)
```

### Changes to `draw_offer` (second-draw de-dup refill path)

Replace the manual filter + shuffle (lines 72–77) with:

```gdscript
_decks[tier] = _build_expanded_deck(tier, left.id)
```
