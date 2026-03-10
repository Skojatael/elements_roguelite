# Research: Mage Tower

**Feature**: 037-mage-tower
**Date**: 2026-03-09

## Decision 1: Relic System Unlock Migration

**Decision**: Remove the existing auto-unlock code paths entirely. The elite-clear detection (`unlock_adventurer_bag` in `MetaManager._on_room_cleared()`), the hub-return activation (`try_activate_relic_offers` in `MetaManager._on_hub_entered()`), and the `MetaManagerImpl.try_activate_relic_offers()` / `unlock_adventurer_bag()` methods are all deleted. The Mage Tower purchase of Relic System becomes the sole way to set `adventurer_bag_unlocked = true` and `relic_offers_active = true`, done atomically in one new `purchase_mage_tower_relic_system()` call.

**Rationale**: There are no existing save files to protect. Keeping dead code paths creates confusion about what actually controls relic activation and adds unnecessary complexity to MetaManager. Clean removal matches Constitution V (YAGNI).

**Alternatives considered**: Keep old paths for backward compatibility. Rejected — no saves exist, so compatibility is moot.

---

## Decision 2: Individual System Unlock Prerequisites

**Decision**: No kill-count or run prerequisites are required to see or purchase individual system unlocks inside the Mage Tower. The 200-shard tower gate is the sole barrier.

**Rationale**: The old `AdventuringGearShop` gated on `first_boss_killed`, and `BossRunShop` gated on `endless_boss_kill_count >= 3`. Both gates are removed — the Mage Tower consolidates all these unlocks under a single 200-shard entry point. Removing kill gates simplifies the progression model and avoids confusing the player ("why is this button greyed out inside the shop I just paid to unlock?").

**Alternatives considered**: Keep the `first_boss_killed` gate for Dungeon Expansion and `endless_boss_kill_count >= 3` for Boss Challenge Mode. Rejected because it creates inconsistent UX within the same screen — some entries would appear locked for non-shard reasons — and adds complexity.

---

## Decision 3: AdventuringGearShop and BossRunShop Removal

**Decision**: `AdventuringGearShop` and `BossRunShop` nodes are removed from `HubRoom.tscn` in the Godot Editor as part of this feature. Their `.gd` script files are deleted. The `BossRunButton` node (which launches an already-unlocked boss run) is retained — it is a launcher, not a shop.

**Rationale**: Both shop nodes become dead code once the Mage Tower screen handles their purchases. Keeping them would create duplicate purchase paths that could confuse players or, worse, allow double-spending (buying dungeon expansion via the old shop while the Mage Tower also shows it as unpurchased).

**Alternatives considered**: Leave the old shop nodes hidden via `visible = false`. Rejected as dead code — YAGNI (Constitution V).

---

## Decision 4: Mage Tower Screen Architecture

**Decision**: `MageTowerUpgradeScreen` uses three independent `@export var` groups (one per system unlock — each with a button and an "Unlocked" label). No generic `SystemUnlockRow` abstraction is introduced.

**Rationale**: There are exactly three systems, all known at spec time. A generic row abstraction would require a dynamic data structure and dynamic signal binding. Three `@export var` groups are simpler, fully Inspector-configurable, and directly aligned with the three FR-010 requirements. Constitution V (YAGNI): two is the minimum call-site count for an abstraction; three statically-defined rows do not meet that threshold.

**Alternatives considered**: Create a reusable `SystemUnlockRow.tscn` component. Rejected: would be its first and only use site, violating Constitution V.

---

## Decision 5: Mage Tower Hub Position

**Decision**: Mage Tower zone placed at approximately `(−400, 200)` in hub local coordinates (left-center area of hub, below center line). Exact position tuned in Godot Editor.

**Rationale**: Magic Forge is at top-center `(0, −400)`. A second building at left-center creates balanced spatial distribution and avoids overlap with the TeleportDoor (which is typically at center or right) and BossRunButton. The exact coordinates are editor-adjustable.

**Alternatives considered**: Right-center `(400, 200)`. Either works — left-center chosen to leave room for future buildings on the right side.

---

## Decision 6: MetaManagerImpl — New vs Reused Methods

**Decision**:
- Dungeon Expansion purchase → reuse existing `purchase_adventuring_gear(cost, save_manager)` directly.
- Boss Challenge purchase → reuse existing `purchase_boss_run(cost, save_manager)` directly.
- Relic System purchase → new method `purchase_mage_tower_relic_system(cost, save_manager)` that sets both `adventurer_bag_unlocked` and `relic_offers_active` in a single operation.
- Mage Tower restoration → new method `purchase_mage_tower(cost, save_manager)` following the exact same pattern as `purchase_magic_forge`.

**Rationale**: Reusing existing purchase methods avoids code duplication. A new Relic System purchase method is needed because no prior "buy relic system" method exists — the old flow was auto-unlock, not a purchase. The new method wraps a shard spend with both flag writes and a save, matching the established MetaManagerImpl pattern.
