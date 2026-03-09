# Research: Magic Forge

**Feature**: 036-magic-forge
**Date**: 2026-03-07

---

## Finding 1 — Existing hub building pattern

**Decision**: Follow the pattern established by `AdventuringGearShop.gd` and `BossRunShop.gd`.

All hub buildings are:
- A scene (`.tscn`) with a `Control` root, a `ColorRect` background, a `Button`
- A co-located `.gd` script with `@export var _button: Button`
- Visibility or state managed via `_update_*()` called from `_ready()` and reconnected on `MetaManager.shards_changed`
- Added as a child node to `HubRoom.tscn` in the Editor; `HubRoom.gd` only references nodes it needs to re-emit signals from (TeleportDoor, BossRunButton)

The MagicForge building follows this convention but requires two visual states (Ruined/Magic) and spawns overlays — it manages overlays itself rather than delegating to HubRoom, keeping HubRoom.gd unchanged.

---

## Finding 2 — Overlay management pattern

**Decision**: MagicForge creates and owns a CanvasLayer child at runtime to host each overlay (RestoreForgeOverlay or ForgeUpgradeScreen). Frees the layer when the overlay closes.

**Rationale**: This is identical to how `Main.gd` manages `RelicOfferScreen`, `ResultsScreen`, and `BossVictoryOverlay` — each overlay lives in a dynamically created CanvasLayer. Since MagicForge is a self-contained hub building (its overlays are forge-scoped and don't affect the run session), it can own its CanvasLayer rather than delegating to HubRoom.

**Alternatives rejected**:
- Signal to HubRoom to spawn overlays: couples HubRoom.gd to forge logic, grows HubRoom beyond its current single responsibility.
- Static CanvasLayer pre-added in MagicForge.tscn: wastes resources; cleaner to create on demand.

---

## Finding 3 — MetaState persistence pattern

**Decision**: Add `magic_forge_unlocked: bool = false` to `MetaState.gd`. Add `purchase_magic_forge(cost, save_manager)` to `MetaManagerImpl`. Add `is_magic_forge_unlocked` property + `purchase_magic_forge()` delegate to `MetaManager` autoload.

**Rationale**: Every permanent hub unlock (adventuring_gear_owned, boss_run_unlocked) follows exactly this three-layer pattern: MetaState field → MetaManagerImpl logic method → MetaManager thin-wrapper property + method.

**Save backward compatibility**: MetaState fields default to `false`, so old saves without `magic_forge_unlocked` will load correctly (missing JSON key → default false). SaveManager must add `magic_forge_unlocked` to its JSON serialization.

---

## Finding 4 — Forge cost config

**Decision**: Add `"magic_forge_cost": 120` to `data/meta_config.json`.

**Rationale**: Principle II — all cost values live in JSON. Every existing unlock cost (adventuring_gear_cost, boss_run_cost) is in meta_config.json.

---

## Finding 5 — Existing UpgradeShop

**Decision**: The existing `UpgradeShop` inline node in `HubRoom.tscn` must be **removed** as part of this feature's editor task.

**Rationale**: The `UpgradeShop` node (referencing `UpgradeShop.gd`) already provides direct damage upgrade access on the hub floor without any gating. The Magic Forge spec defines the forge as the upgrade hub for run upgrades. Keeping both creates confusing duplicate access. The forge becomes the single entry point for damage upgrades.

---

## Finding 6 — ForgeUpgradeScreen vs reusing UpgradeShop

**Decision**: Create a new `ForgeUpgradeScreen.gd` / `forgeupgradescreen.tscn` that replicates and slightly extends the `UpgradeShop.gd` logic with a close button and a proper screen layout.

**Rationale**: `UpgradeShop.gd` is a minimal inline button on the hub floor. The forge upgrade screen is a proper overlay panel with a close button — different UX context. Copying the 10-line update logic is simpler than trying to inherit or wrap the existing node (YAGNI). `UpgradeShop.gd` is removed with the UpgradeShop node (Finding 5).

---

## Summary of files

| Action | File |
|---|---|
| New | `scenes/hub/MagicForge.gd` |
| New | `scenes/hub/magicforge.tscn` |
| New | `scenes/hub/RestoreForgeOverlay.gd` |
| New | `scenes/hub/restoreforgeoverlay.tscn` |
| New | `scenes/hub/ForgeUpgradeScreen.gd` |
| New | `scenes/hub/forgeupgradescreen.tscn` |
| Modify | `scripts/data_models/MetaState.gd` |
| Modify | `autoload/MetaManager.gd` |
| Modify | `scripts/managers/MetaManager.gd` (MetaManagerImpl) |
| Modify | `autoload/SaveManager.gd` |
| Modify | `data/meta_config.json` |
| Editor | `scenes/hub/HubRoom.tscn` — add MagicForge at top-center, remove UpgradeShop node |
