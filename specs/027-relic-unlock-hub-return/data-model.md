# Data Model: Relic Offers Activate on Hub Return

**Feature**: 027-relic-unlock-hub-return
**Date**: 2026-03-03

---

## MetaState (MODIFIED)

**File**: `scripts/data_models/MetaState.gd`

| Field | Type | Default | Description |
|---|---|---|---|
| `total_shards` | `int` | `0` | Existing |
| `damage_upgrade_level` | `int` | `0` | Existing |
| `adventurer_bag_unlocked` | `bool` | `false` | Existing (026) — set on first elite clear |
| `relic_offers_active` | `bool` | `false` | NEW — set on first hub visit after `adventurer_bag_unlocked` becomes `true` |

**State machine**:
```
adventurer_bag_unlocked=false, relic_offers_active=false
    → [first elite clear] →
adventurer_bag_unlocked=true, relic_offers_active=false
    → [first hub visit] →
adventurer_bag_unlocked=true, relic_offers_active=true  ← final state, permanent
```

**Invariants**:
- `relic_offers_active` is write-once: never set back to `false`.
- `relic_offers_active = true` implies `adventurer_bag_unlocked = true`.

---

## Persistence (SaveManagerImpl — MODIFIED)

**File**: `scripts/managers/SaveManager.gd`

**JSON key added**: `"relic_offers_active"` (bool)

**Save format** (after change):
```json
{
  "total_shards": 42,
  "damage_upgrade_level": 2,
  "adventurer_bag_unlocked": true,
  "relic_offers_active": true
}
```

**Backward compatibility**: Missing key defaults to `false`. Players with `adventurer_bag_unlocked: true` and missing `relic_offers_active` will activate on their next hub visit (US2 path).

---

## No new entities

No new data model classes introduced. Feature adds one field to MetaState and one signal to GlobalSignals.
