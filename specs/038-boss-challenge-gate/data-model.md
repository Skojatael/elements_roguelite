# Data Model: Boss Challenge Gate

## Entities

### BossKillPopup (transient UI)

A one-time overlay shown after the first endless boss kill. Not persisted.

| Field | Type | Source |
|---|---|---|
| `message` | `String` | `meta_config.json → mage_tower.first_boss_killed.popup_message` |

### meta_config.json additions

```json
"mage_tower": {
    "first_boss_killed": {
        "popup_message": "You have defeated the boss. Boss Challenge Mode can now be purchased in the Mage Tower."
    },
    "upgrades": {
        "boss_challenge": {
            "name": "Boss Challenge Mode",
            "cost": 200,
            "gate_text": "Major essence required"
        }
    }
}
```

## Existing Entities (unchanged)

### MetaState.first_boss_killed: bool

Already persisted. Set by `MetaManagerImpl.record_boss_kill()` on first endless boss room clear. This feature adds no new persistence.

### MetaState.endless_boss_kill_count: int

Already persisted. Incremented on every endless boss kill. Used by Main.gd to detect first kill (`== 1`).

## State Transitions

```
first_boss_killed = false
    │
    │ (boss room cleared, endless mode, first time)
    ▼
first_boss_killed = true
endless_boss_kill_count = 1
    │
    │ triggers: BossKillPopup shown (after relic offer if active)
    ▼
Player taps OK
    │
    ▼
BossVictoryOverlay shown
```

## Gate Logic in MageTowerUpgradeScreen

Per-entry dict shape (boss_challenge only):
```
{
    "name":       String   ← from JSON
    "cost":       int      ← from JSON
    "gate_text":  String   ← from JSON ("Major essence required")
    "gate_prop":  String   ← hardcoded key ("is_first_boss_killed")
    "owned_prop": String   ← hardcoded key ("is_boss_run_unlocked")
    "button":     Button   ← runtime node ref
    "purchase":   Callable ← runtime method ref
}
```

`_apply_entry` priority order:
1. `gate_prop` set AND `MetaManager.get(gate_prop) == false` → show `gate_text`, disabled, return
2. `owned_prop` value true → show "Name — Unlocked", disabled, return
3. else → show "Name — X shards", disabled based on affordability
