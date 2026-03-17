# Data Model: Enemy Detection Radius (049)

## JSON Schema — `data/enemies.json` (no change)

`detection_range` already exists and is already parsed by `EnemyData.from_dict()`. No schema changes required.

```json
{ "id": "slime", "detection_range": 800.0, ... }
```

| Field | Type | Current values | Description |
|---|---|---|---|
| `detection_range` | float | slime=800, skeleton=800, boss=800 | World-space radius (px) at which this enemy detects the player |

**Constraint**: Must be > 0. Values ≤ 0 are invalid; system logs a warning and uses fallback 300.0.

---

## Runtime Application — `Enemy.initialize()`

| Field | Source | Applied to |
|---|---|---|
| `data.detection_range` | `EnemyData` | `CircleShape2D.radius` on `DetectionArea/CollisionShape2D` |

**Validation rule**: `detection_range > 0` — enforced at runtime in `initialize()` with `push_warning` + fallback.

---

## State

No new state fields. The radius is set once at initialization and never changes during the enemy's lifetime (difficulty scaling does not affect detection range — spec Assumption 4).
