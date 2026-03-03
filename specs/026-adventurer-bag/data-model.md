# Data Model: Adventurer Bag

**Feature**: 026-adventurer-bag
**Date**: 2026-03-03

---

## MetaState (MODIFIED)

**File**: `scripts/data_models/MetaState.gd`

| Field | Type | Default | Description |
|---|---|---|---|
| `total_shards` | `int` | `0` | Existing — accumulated meta currency |
| `damage_upgrade_level` | `int` | `0` | Existing — damage upgrade tier |
| `adventurer_bag_unlocked` | `bool` | `false` | NEW — permanently true after first elite room clear |

**Invariant**: `adventurer_bag_unlocked` is write-once. Once set to `true` it is never set back to `false` during normal gameplay.

---

## Persistence (SaveManagerImpl — MODIFIED)

**File**: `scripts/managers/SaveManager.gd`

**JSON key added**: `"adventurer_bag_unlocked"` (bool)

**Save format** (after change):
```json
{
  "total_shards": 42,
  "damage_upgrade_level": 2,
  "adventurer_bag_unlocked": true
}
```

**Backward compatibility**: If key is absent on load (old save file), field defaults to `false`. No migration needed.

---

## No new entities

No new data model classes are introduced. The feature adds one field to an existing class.
