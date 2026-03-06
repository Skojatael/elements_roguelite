# Data Model: Boss Rewards (032)

## Data Change — enemies.json boss entry

Change `"base_essence"` from `0` to `80` in the boss entry.

```json
{
  "enemies": {
    "boss": [
      {
        "id": "boss",
        "max_health": 40.0,
        "damage": 5.0,
        "damage_cooldown": 2.0,
        "base_essence": 80,
        "rooms_required": 6
      }
    ]
  }
}
```

**Tuning note**: `base_essence` is the only value to change when adjusting boss reward. No code changes required.

---

## Scaled Boss Reward Formula

```
reward = floori(base_essence × (1.0 + 0.06 × max(0, rooms_cleared − 6)))
```

Scaling only activates beyond the 6-room unlock threshold. At exactly 6 rooms the boss awards full base value with no bonus.

| rooms_cleared | max(0, N−6) | multiplier | reward (base=80) |
|---------------|-------------|-----------|-----------------|
| 0             | 0           | 1.00      | 80              |
| 6             | 0           | 1.00      | 80              |
| 7             | 1           | 1.06      | 84              |
| 12            | 6           | 1.36      | 108             |
| 16            | 10          | 1.60      | 128             |

---

## New State: Main.gd

| Field | Type | Description |
|-------|------|-------------|
| `_boss_relic_pending` | `bool` | True between `trigger_boss_offer()` call and the relic pick. Distinguishes boss relic pick from regular pick in `_on_relic_picked()`. Reset to false in `_on_relic_picked()` and `_on_run_started()`. |

---

## No changes to:
- `EnemyData.gd` — `base_essence` field already exists
- `relics.json` — rare tier already has 4 relics; no additions needed
- `RunManager` signals or state
- `RelicOfferScreen` / `RelicData` — reused as-is
