# Data Model: Forge Rarity Upgrade (067)

## MetaState (modified)

**File**: `scripts/data_models/MetaState.gd`
**Change**: Add one field.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `rarity_luck_owned` | `bool` | `false` | Set to `true` after purchase; persisted across sessions. Never reset. |

---

## meta_config.json (modified)

**File**: `data/meta_config.json`
**Change**: Add entry under `magic_forge.upgrades`.

```json
"magic_forge": {
  "upgrades": {
    "rarity_luck_upgrade": {
      "name": "Rarity Luck",
      "cost": 350,
      "promotion_chance": 0.1
    }
  }
}
```

`promotion_chance` is read by `RelicManager._on_room_cleared` at offer time. Defaults to `0.1` in code if key is absent.

---

## SaveManager JSON schema (modified)

**File**: `scripts/managers/SaveManager.gd`
**Change**: Add `rarity_luck_owned` to save and load. Backward-compatible default: `false`.

---

## RelicManagerImpl draw_offer signature (modified)

**Old**: `draw_offer(tier: String) -> Array[RelicData]`
**New**: `draw_offer(tier: String, promotion_chance: float = 0.0) -> Array[RelicData]`

Default value of `0.0` keeps all existing callers (`trigger_offer`, `draw_boss_offer` calls nothing) unchanged without modification.

---

## New internal helpers in RelicManagerImpl

### `_next_tier(tier: String) -> String`
Pure function — no side effects.

| Input | Output |
|-------|--------|
| `"common"` | `"uncommon"` |
| `"uncommon"` | `"rare"` |
| `"rare"` | `""` (empty — no higher tier) |
| anything else | `""` |

### `_draw_one_with_promotion(base_tier: String, promotion_chance: float) -> RelicData`
- If `promotion_chance > 0.0`: get `next = _next_tier(base_tier)`.
  - If `next` is non-empty and tier has relics and `randf() < promotion_chance`: try `_draw_one_from_tier(next)`.
  - If that returns non-null, return it (promoted draw).
- Fall through to `_draw_one_from_tier(base_tier)`.
