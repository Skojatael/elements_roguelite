# Data Model: Magic Forge

**Feature**: 036-magic-forge
**Date**: 2026-03-07

---

## Entities

### MagicForgeState (persisted field in MetaState)

| Field | Type | Default | Description |
|---|---|---|---|
| `magic_forge_unlocked` | `bool` | `false` | True once the player has paid 120 shards to restore the forge. Permanent. |

**Validation**: Can only transition false → true. Once unlocked, purchase attempts are no-ops (idempotent guard in MetaManagerImpl).

**Persistence**: Serialised as `"magic_forge_unlocked"` key in `user://meta_save.json`. Missing key on load → false (backward compatible).

---

### ForgeUnlockTransaction

Not a persisted entity — represents the in-memory purchase action:

| Step | Actor | Action |
|---|---|---|
| 1 | Player | Taps Ruined Forge zone |
| 2 | MagicForge | Shows RestoreForgeOverlay |
| 3 | Player | Taps "Restore the Forge" |
| 4 | MetaManager | Calls `purchase_magic_forge()` |
| 5 | MetaManagerImpl | Deducts 120 shards, sets `magic_forge_unlocked = true`, saves |
| 6 | MetaManager | Emits `shards_changed` |
| 7 | MagicForge | Closes overlay, updates visuals |

---

### Config values (meta_config.json)

| Key | Type | Value | Description |
|---|---|---|---|
| `magic_forge_cost` | `int` | `120` | One-time shard cost to unlock the forge |

---

## State Machine: Magic Forge visual

```
[Ruined Forge — black ColorRect]
        |
        | purchase_magic_forge() succeeds
        ▼
[Magic Forge — grey ColorRect]
```

No reverse transition. The Magic Forge state is permanent.

---

## Forge Upgrade Screen — data consumed (read-only)

The `ForgeUpgradeScreen` reads, but does not own, the following existing data:

| Source | Field/Method | Used for |
|---|---|---|
| `MetaManager.meta_state.damage_upgrade_level` | `int` | Current level display |
| `MetaManager.get_next_upgrade_cost()` | `int` | Button label cost |
| `MetaManager.can_spend(cost)` | `bool` | Button disabled state |
| `meta_config.json → damage_upgrade.max_levels` | `int` | "Maxed" detection |

The screen calls `MetaManager.purchase_damage_upgrade()` on button press — no new data owned.
