# Data Model: Mage Tower

**Feature**: 037-mage-tower
**Date**: 2026-03-09

## Persistent State (MetaState)

### New field

| Field | Type | Default | Description |
|---|---|---|---|
| `mage_tower_unlocked` | `bool` | `false` | True once the player pays 200 shards to restore the Mage Tower. One-time permanent unlock. |

### Existing fields consumed (read-only by Mage Tower screen)

| Field | Owner | Meaning in Mage Tower |
|---|---|---|
| `adventuring_gear_owned` | MetaState | Dungeon Expansion entry shows "Unlocked" when true |
| `adventurer_bag_unlocked` + `relic_offers_active` | MetaState | Relic System entry shows "Unlocked" when `relic_offers_active` is true |
| `boss_run_unlocked` | MetaState | Boss Challenge Mode entry shows "Unlocked" when true |

## Config (meta_config.json)

### New keys

| Key | Value | Description |
|---|---|---|
| `mage_tower_cost` | `200` | Shard cost to restore the Mage Tower |
| `mage_tower_dungeon_expansion_cost` | `200` | Shard cost for Dungeon Expansion unlock |
| `mage_tower_relic_system_cost` | `100` | Shard cost for Relic System unlock |
| `mage_tower_boss_challenge_cost` | `200` | Shard cost for Boss Challenge Mode unlock |

### Removed keys

| Key | Reason |
|---|---|
| `adventuring_gear_cost` | AdventuringGearShop removed; cost now under `mage_tower_dungeon_expansion_cost` |
| `boss_run_cost` | BossRunShop removed; cost now under `mage_tower_boss_challenge_cost` |

> Note: `boss_run_kill_threshold` key also becomes unused (no prerequisite kill gate in the Mage Tower). Remove it.

## Save File (user://meta_save.json)

### New field added to JSON

```json
{
  "mage_tower_unlocked": false
}
```

### Removed logic

- `adventurer_bag_unlocked` and `relic_offers_active` are still persisted (same keys) but now only written by `purchase_mage_tower_relic_system()`.
- `adventuring_gear_owned` and `boss_run_unlocked` still persisted — now written by reused purchase methods called from the Mage Tower screen.

## MetaManagerImpl — New Methods

| Method | Signature | Behaviour |
|---|---|---|
| `purchase_mage_tower` | `(cost: int, save_manager: Node) -> bool` | Guards: already unlocked → false; can't afford → false. Deducts cost, sets `mage_tower_unlocked = true`, saves. |
| `purchase_mage_tower_relic_system` | `(cost: int, save_manager: Node) -> bool` | Guards: `relic_offers_active` already true → false; can't afford → false. Deducts cost, sets `adventurer_bag_unlocked = true` and `relic_offers_active = true`, saves. |

> Dungeon Expansion and Boss Challenge purchases reuse existing `purchase_adventuring_gear()` and `purchase_boss_run()` methods unchanged.

## MetaManager Autoload — New Members

| Member | Type | Description |
|---|---|---|
| `is_mage_tower_unlocked` | `bool` (computed property) | Returns `_impl.meta_state.mage_tower_unlocked` |
| `purchase_mage_tower()` | `-> bool` | Reads cost from config, delegates to `_impl.purchase_mage_tower()`, emits `shards_changed` on success |
| `purchase_mage_tower_relic_system()` | `-> bool` | Reads cost from config, delegates to `_impl.purchase_mage_tower_relic_system()`, emits `shards_changed` on success |

## Removed Code

| File | What Is Removed |
|---|---|
| `autoload/MetaManager.gd` | `_on_hub_entered()` body call to `_impl.try_activate_relic_offers()` (method body becomes empty or is removed); `_on_room_cleared()` elite detection branch calling `_impl.unlock_adventurer_bag()` |
| `scripts/managers/MetaManager.gd` (MetaManagerImpl) | `try_activate_relic_offers()` method; `unlock_adventurer_bag()` method |
| `scenes/hub/AdventuringGearShop.gd` | Entire file deleted |
| `scenes/hub/AdventuringGearShop.gd.uid` | Deleted alongside script |
| `scenes/hub/BossRunShop.gd` | Entire file deleted |
| `scenes/hub/BossRunShop.gd.uid` | Deleted alongside script |
| `scenes/hub/HubRoom.tscn` | `AdventuringGearShop` node removed; `BossRunShop` node removed (Godot Editor) |

## Scene Structure

### MageTower.tscn (new, inherits nothing — plain Control)

```
MageTower (Control)              ← MageTower.gd attached
├── RuinedVisual (ColorRect)     ← @export _ruined_visual
├── MageTowerVisual (ColorRect)  ← @export _magic_visual
├── Label (Label)                ← @export _label  ("Ruined Mage Tower" / "Mage Tower")
└── Button (Button)              ← @export _button
```

### RestoreTowerOverlay.tscn (new, Control root)

```
RestoreTowerOverlay (Control)    ← RestoreTowerOverlay.gd attached
├── RestoreButton (Button)       ← @export _restore_button
└── LaterButton (Button)         ← @export _later_button
```

### MageTowerUpgradeScreen.tscn (new, Control root)

```
MageTowerUpgradeScreen (Control)     ← MageTowerUpgradeScreen.gd attached
├── DungeonExpansionButton (Button)  ← @export _de_button  (text + disabled state change on ownership)
├── RelicSystemButton (Button)       ← @export _rs_button
├── BossChallengeButton (Button)     ← @export _bc_button
└── CloseButton (Button)             ← @export _close_button
```
