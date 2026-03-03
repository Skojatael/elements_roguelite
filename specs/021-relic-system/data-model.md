# Data Model: Relic System

**Feature**: 021-relic-system
**Date**: 2026-03-02

---

## Entities

### RelicData

**File**: `scripts/data_models/RelicData.gd`
**Type**: `RefCounted` (typed data model, not persisted)

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique identifier (e.g., `"sharp_edge"`) |
| `name` | `String` | Display name shown on offer screen (e.g., `"Sharp Edge"`) |
| `tier` | `String` | `"common"`, `"rare"`, or `"epic"` — stored, not yet used for weighting |
| `tags` | `Array[String]` | Categorical tags (e.g., `["combat"]`, `["survival"]`) |
| `effect_stat` | `String` | Stat targeted: `"attack_damage"`, `"attack_speed"`, `"max_health"`, or `"move_speed"` |
| `effect_mult` | `float` | Multiplier applied to the targeted stat (e.g., `1.2` = +20%) |
| `description` | `String` | Short human-readable effect description (e.g., `"+20% attack damage"`) |

**Factory**: `static func from_dict(data: Dictionary) -> RelicData`

**Validation rules**:
- `id` must be non-empty
- `effect_mult` must be > 0.0
- `effect_stat` must be one of the 4 supported stat strings

---

### PlayerState (modified)

**File**: `scripts/data_models/PlayerState.gd` (existing)

**Change**: Replace stub field `var modifiers: Array = []` with:

| Field | Type | Description |
|---|---|---|
| `active_modifiers` | `Array[String]` | Relic IDs collected this run (order preserved, duplicates allowed) |

Populated by `RelicManager.pick_relic()`. Cleared implicitly when `RunManager.start_run()` creates a fresh `PlayerState`. Read-only for all systems except `RelicManager`.

---

### RelicManagerImpl (runtime state, not persisted)

**File**: `scripts/managers/RelicManagerImpl.gd`
**Type**: `RefCounted`

| Field | Type | Description |
|---|---|---|
| `active_relic_ids` | `Array[String]` | Relic IDs accumulated this run — source of truth for stat computation |
| `standard_rooms_cleared` | `int` | Counter: standard (non-elite) rooms cleared since last offer |

**Constants**:
- `OFFER_INTERVAL: int = 2` — offer every N standard room clears

---

## Data Source

### data/relics.json (new)

Top-level key `"relics"`: Array of relic entry objects.

**Schema per entry**:
```json
{
  "id":          "<string>",
  "name":        "<string>",
  "tier":        "common" | "rare" | "epic",
  "tags":        ["<string>", ...],
  "effect_stat": "attack_damage" | "attack_speed" | "max_health" | "move_speed",
  "effect_mult": <float>,
  "description": "<string>"
}
```

**Initial pool** (6 entries):
```json
{
  "relics": [
    { "id": "sharp_edge",   "name": "Sharp Edge",   "tier": "common", "tags": ["combat"],   "effect_stat": "attack_damage", "effect_mult": 1.2,  "description": "+20% attack damage" },
    { "id": "rage_crystal", "name": "Rage Crystal", "tier": "rare",   "tags": ["combat"],   "effect_stat": "attack_damage", "effect_mult": 1.3,  "description": "+30% attack damage" },
    { "id": "swift_strike", "name": "Swift Strike", "tier": "common", "tags": ["combat"],   "effect_stat": "attack_speed",  "effect_mult": 1.25, "description": "+25% attack speed"  },
    { "id": "iron_hide",    "name": "Iron Hide",    "tier": "common", "tags": ["survival"], "effect_stat": "max_health",    "effect_mult": 1.3,  "description": "+30% max health"    },
    { "id": "vital_core",   "name": "Vital Core",   "tier": "rare",   "tags": ["survival"], "effect_stat": "max_health",    "effect_mult": 1.5,  "description": "+50% max health"    },
    { "id": "wind_boots",   "name": "Wind Boots",   "tier": "common", "tags": ["mobility"], "effect_stat": "move_speed",    "effect_mult": 1.2,  "description": "+20% move speed"    }
  ]
}
```

---

## State Flow

```
run_started
  └─ RelicManagerImpl.reset()        ← active_relic_ids = [], standard_rooms_cleared = 0
  └─ PlayerState created fresh       ← active_modifiers = []
  └─ _relic_pool built from JSON

room_cleared
  └─ RelicManager._on_room_cleared() ← checks room_type_id
  └─ should_offer_for_room()         ← frequency gate
    ├─ if true → draw_offer()        ← picks 2 RelicData from pool
    └─ relic_offer_ready.emit()

player picks relic
  └─ pick_relic(id)
    ├─ RelicManagerImpl.active_relic_ids.append(id)
    ├─ PlayerState.active_modifiers.append(id)
    └─ relic_applied.emit(id)
      ├─ CombatComponent._recompute_stats()    ← attack_damage, attack_interval
      ├─ StatsComponent._on_relic_applied()    ← max_health
      └─ MovementComponent._recompute_stats()  ← move_speed

run_ended
  └─ RelicManagerImpl.reset()        ← clears all state
```

---

## Stat Multiplier Computation

`RelicManager.get_stat_mult(stat: String) -> float`:
- Iterates `RelicManagerImpl.active_relic_ids`
- Multiplies `effect_mult` of all relics whose `effect_stat == stat`
- Returns 1.0 if no relics modify that stat

**Formula**: `final_mult = Π(effect_mult_i for all relics i where effect_stat == stat)`

**Application per stat**:
| Stat | Formula in component |
|---|---|
| `attack_damage` | `_base_attack_damage × MetaManager.damage_multiplier × relic_mult` |
| `attack_speed` | `_base_attack_interval / relic_mult` (lower interval = faster) |
| `max_health` | `_base_max_health × relic_mult` (current_health scales proportionally) |
| `move_speed` | `_base_move_speed × relic_mult` |
