# Data Model: Unit Test Suite (039-gut-unit-tests)

No new persistent data models are introduced. This section documents the **stub data structures** each test file uses to drive its subject under test without autoload dependencies.

---

## Stub: DungeonGenerator config

Used by `test_dungeon_generation.gd` to call `DungeonGenerator._generate_with(config, gear_owned)`.

```gdscript
const STUB_CONFIG: Dictionary = {
    "combat_room_pool": ["CombatRoom01", "CombatRoom02"],
    "base_room_count": 9,
    "difficulty_scale": 0.12,
    "expansion_room_count": 4,
}
```

Fields match `dungeon_config.json` keys consumed by `_generate_with`. No other fields are needed.

---

## Stub: RelicManagerImpl pool

Used by `test_relic_deck.gd` to call `RelicManagerImpl.build_pool(relics_raw, config_raw)`.

### relics_raw (minimal viable pool)

```gdscript
const STUB_RELICS: Dictionary = {
    "relics": {
        "common": {
            "relic_a": { "name": "A", "effect_stat": "attack_damage", "effect_mult": 1.10 },
            "relic_b": { "name": "B", "effect_stat": "attack_speed",  "effect_mult": 1.05 },
            "relic_c": { "name": "C", "effect_stat": "move_speed",    "effect_mult": 1.08 },
        },
        "rare": {
            "relic_x": { "name": "X", "effect_stat": "attack_damage", "effect_mult": 1.25 },
            "relic_y": { "name": "Y", "effect_stat": "max_health",    "effect_mult": 1.30 },
        },
    }
}
```

### config_raw (tier weights — rare intentionally absent)

```gdscript
const STUB_CONFIG: Dictionary = {
    "relic_tier_weights": { "common": 1.0 }
    # "rare" key absent → excluded from _tier_weights → never drawn by draw_offer()
}
```

Three common relics enable a full-pass duplicate test (draw all 3, verify all distinct). Two rare relics enable the boss offer test (draw up to 3, only rares returned).

---

## Stub: MetaManagerImpl upgrade cost

No stub dictionary needed. `MetaManagerImpl.get_upgrade_cost(level, base_cost, scale)` is a pure function — inputs are inlined per assertion.

**Known cost table** (base_cost=50, scale=1.2, iterative floor):

| Level | Expected cost |
|-------|--------------|
| 0     | 50           |
| 1     | 60           |
| 2     | 72           |
| 3     | 86           |
| 4     | 103          |
| 5     | 123          |
| 6     | 147          |
| 7     | 176          |
| 8     | 211          |
| 9     | 253          |

---

## Stub: Boss unlock threshold

No stub needed. `ExplorationHUD.is_boss_available(cleared_count, required)` is a pure static function — inputs are inlined per assertion.

**Boundary table** (rooms_required=6):

| cleared_count | required | is_boss_available |
|--------------|----------|-------------------|
| 5            | 6        | false             |
| 6            | 6        | true              |
| 7            | 6        | true              |
| 0            | 6        | false             |
