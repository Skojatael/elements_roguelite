# Research: Boss Rewards (032)

## Decision 1 — Essence Award via add_currency() in _on_boss_room_cleared()

**Decision**: Boss essence is awarded by calling `RunManager.add_currency(reward)` directly inside `Main._on_boss_room_cleared()`, not through the normal `enemy_defeated` signal path.

**Rationale**: The normal essence flow uses `floori(base_essence × (1 + 0.10 × (depth − 1)))`. The boss room has `depth = 0` (not set by RoomLoader for out-of-grid rooms), which would give `floori(base × 0.9)` — a penalty, not a reward. The boss needs `floori(base × (1 + 0.06 × rooms_cleared))`, a different formula. Implementing this directly in `_on_boss_room_cleared()` keeps the formula explicit and avoids adding boss-specific branching to RunManager or RoomSpawner.

The base value is read from `ResourceManager.get_enemy_base_essence("boss")` — the `base_essence` field already exists in the boss entry in enemies.json (currently 0; changed to 80 in this feature). No new data fields needed.

**Alternatives considered**:
- Set `base_essence = 80` and use normal formula via `enemy_defeated` — rejected: depth=0 produces a penalty; also normal formula uses a different multiplier (0.10 vs 0.06).
- Add a separate `boss_reward` field to enemies.json / EnemyData — rejected: `base_essence` is already the right semantic field; using two different fields for the same concept would be confusing.

---

## Decision 2 — draw_boss_offer(): Draw Directly from Full Rare Pool

**Decision**: Add `draw_boss_offer() -> Array[RelicData]` to `RelicManagerImpl`. It shuffles all rare relics not already held by the player and returns up to 3. It draws from `_all_by_tier["rare"]` (the full pool), not `_decks["rare"]` (the current deck sequence).

**Rationale**: The deck is used to maintain non-repeating random sequence across multiple run-long draws. The boss offer is a one-time event that should present the widest available selection to the player — offering the "next 3 from the deck" could exclude relics the player hasn't seen. Shuffling the full available pool is correct here.

Exclusion of already-held relics: iterate `_all_by_tier["rare"]`, skip any with `id` in `active_relic_ids`, shuffle, take `mini(3, size)`.

**Alternatives considered**:
- Draw from the deck — rejected: may produce non-ideal selection (e.g. only 1 rare left in deck even though others are available after a reshuffle).
- Draw via `_draw_one()` three times — rejected: uses weighted tier selection, may not produce 3 rares; also risks duplicates without extra dedup logic.

---

## Decision 3 — trigger_boss_offer() Returns bool; Fallback in Main.gd

**Decision**: `RelicManager.trigger_boss_offer() -> bool` emits `relic_offer_ready` if `draw_boss_offer()` is non-empty and returns `true`; returns `false` if no rare relics are available (skips offer).

Main.gd `_on_boss_room_cleared()` checks the return value:
- `true` → offer will appear; `_boss_relic_pending = true`; wait for `_on_relic_picked()`
- `false` → no offer; call `_show_boss_victory_overlay()` directly

**Rationale**: With only 4 rare relics in the pool, edge cases (player holds 3+ rares) can realistically occur. A clean fallback prevents the victory overlay from never appearing.

---

## Decision 4 — _boss_relic_pending Flag in Main.gd

**Decision**: `var _boss_relic_pending: bool = false` in Main.gd. Set to `true` before `trigger_boss_offer()`; read in `_on_relic_picked()` to decide whether to show the victory overlay or restore ExplorationHUD.

**Rationale**: `_on_relic_picked()` is shared between regular room relic picks and the boss relic pick. A flag is the simplest way to distinguish the two paths without duplicating handler code.

**Alternatives considered**:
- Use a separate signal / separate offer screen — rejected: over-engineering; the existing RelicOfferScreen handles 3 relics fine.
- Check `RunManager.cleared_rooms.has("boss_room")` in `_on_relic_picked()` — rejected: fragile coupling to room ID; flag is explicit.

---

## Decision 5 — Extract _show_boss_victory_overlay() Helper

**Decision**: Extract the victory overlay creation code from `_on_boss_room_cleared()` into a private `_show_boss_victory_overlay()` method. Both the fallback (no rare relics) and the post-relic-pick path call this method.

**Rationale**: Two callers → one extraction point (Constitution V: "introduced only when at least two concrete call sites require it").

---

## Decision 6 — RelicManager._on_room_cleared() Must Skip Boss Room

**Decision**: Add `if room_id == "boss_room": return` at the top of `RelicManager._on_room_cleared()`.

**Rationale**: When the boss room clears, `RunManager.room_cleared("boss_room")` fires. `RelicManager._on_room_cleared` is connected to this signal. It would call `should_offer_for_room("BossRoom01")`, which increments `standard_rooms_cleared` (since "BossRoom01" doesn't contain "Elite"). This corrupts the regular offer counter AND could trigger an unwanted regular offer. The boss offer is handled exclusively via `trigger_boss_offer()` — the room-cleared path must be bypassed.
