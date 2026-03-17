# Data Model: Player Crit Chance

## JSON Schema Change — `data/player.json`

Add a `"crit"` section alongside existing sections:

```json
{
  "combat": {
    "attack_damage": 20.0,
    "attack_interval": 0.75
  },
  "stats": {
    "max_health": 100.0
  },
  "movement": {
    "move_speed": 200.0
  },
  "crit": {
    "crit_chance": 0.0,
    "crit_multiplier": 0.5
  }
}
```

| Field | Type | Default | Valid range | Description |
|-------|------|---------|-------------|-------------|
| `crit_chance` | float | `0.0` | 0.0–1.0 (clamped above 1.0) | Probability per hit of a critical strike |
| `crit_multiplier` | float | `0.5` | any float | Bonus multiplier applied on crit: `dmg × (1 + mult)` |

## Runtime State — `CombatComponent`

New fields (load-once in `_ready()`):

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `_crit_chance` | `float` | `0.0` | Loaded from `player.json["crit"]["crit_chance"]`, clamped to [0, 1] |
| `_crit_multiplier` | `float` | `0.5` | Loaded from `player.json["crit"]["crit_multiplier"]` |

## Runtime State — `SkillComponent`

New fields (load-once in `_load_skill_data()`):

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `_crit_chance` | `float` | `0.0` | Same values as CombatComponent — independent load |
| `_crit_multiplier` | `float` | `0.5` | Same values as CombatComponent — independent load |

## Crit Roll Logic (applied per hit)

```
roll = randf()           # uniform float in [0.0, 1.0)
if roll < _crit_chance:
    damage = floorf(base_damage * (1.0 + _crit_multiplier))
else:
    damage = base_damage  # unchanged
```

## Invariants

- `_crit_chance` is clamped: `minf(1.0, raw_value)` on load
- `crit_chance = 0.0` → roll is NEVER less than 0.0 → crits never occur
- `crit_chance = 1.0` → roll is ALWAYS less than 1.0 → crits always occur
- Enemy `take_damage()` is called with the final (possibly crit-adjusted) float; no change to `Enemy` or `StatsComponent`
