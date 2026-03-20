# Research: Forge Rarity Upgrade (067)

## Decision 1: Where promotion logic lives

**Decision**: `RelicManagerImpl.draw_offer()` gains an optional `promotion_chance: float = 0.0` parameter. Two new private helpers (`_next_tier`, `_draw_one_with_promotion`) keep the per-draw roll self-contained.

**Rationale**: `draw_offer` is already the single per-draw dispatch point. Adding a `promotion_chance` parameter is minimal and backward-compatible — existing callers (`draw_boss_offer`, `trigger_offer` in DevPanel) pass nothing and get 0.0 (no promotion). No new public surface is added to RelicManager; `_on_room_cleared` passes the chance based on `MetaManager.is_rarity_luck_owned`.

**Alternatives considered**:
- Add a separate `draw_offer_with_luck()` method — rejected: duplicates all de-dup logic and adds dead code when luck is not owned.
- Compute promotion in `RelicManager._on_room_cleared` and pass a pre-rolled tier list — rejected: leaks random-number logic into the autoload wrapper, which must be thin.

---

## Decision 2: De-duplication across tiers

**Decision**: Strip `left.id` from `_decks[left.tier]` (not from `_decks[tier]`). `left.tier` is set by `build_pool` from the JSON tier key and is always accurate regardless of which deck the draw came from.

**Rationale**: The existing de-dup strips copies of the drawn relic from the deck it came from before drawing the second card. Since a promoted draw comes from `next_tier`, stripping from `_decks[base_tier]` would be a no-op (the promoted relic doesn't live there). Using `left.tier` correctly handles all four cases:

| left source | right source | risk of duplicate | after fix |
|-------------|--------------|-------------------|-----------|
| base tier   | base tier    | same pool — yes   | strip base ✓ |
| base tier   | next tier    | different pools — no | strip base (harmless) ✓ |
| next tier   | base tier    | different pools — no | strip next (harmless) ✓ |
| next tier   | next tier    | same pool — yes   | strip next ✓ |

---

## Decision 3: Tier ordering and next-tier resolution

**Decision**: `_next_tier(tier: String) -> String` encodes the chain `common → uncommon → rare`. Returns `""` for `rare` (no higher tier). Draw logic checks `next.is_empty()` before attempting promotion.

**Rationale**: Three tiers only; a `match` statement is simpler than a data-driven tier index. Boss offers always draw from `rare` directly and bypass `draw_offer` entirely via `draw_boss_offer()`, so there is no risk of trying to promote a `rare` draw.

---

## Decision 4: Promotion rate in config

**Decision**: The 10% promotion chance is stored as `rarity_luck_upgrade.promotion_chance: 0.1` in `meta_config.json → magic_forge.upgrades`. `RelicManager._on_room_cleared` reads it at offer time via `ResourceManager.get_meta_config()`.

**Rationale**: Satisfies Constitution II (no hard-coded balance constants). Allows tuning without reopening the editor.

---

## Decision 5: Persistence key naming

**Decision**: New `MetaState` field: `rarity_luck_owned: bool = false`. SaveManager JSON key: `"rarity_luck_owned"`. Follows the established boolean-owned pattern used by `missile_extra_charge_owned`, `gold_generator_owned`, etc.

**Alternatives considered**: Naming it `forge_rarity_luck_unlocked` — rejected: longer, inconsistent with the `_owned` suffix used for all other one-time Forge/Lab purchases.
