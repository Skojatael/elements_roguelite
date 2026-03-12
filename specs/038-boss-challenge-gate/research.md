# Research: Boss Challenge Gate

## Decision 1 — How does Main know it's the first boss kill?

**Decision**: Check `MetaManager.endless_boss_kill_count == 1` inside `_on_boss_room_cleared()`.

**Rationale**: `MetaManagerImpl.increment_endless_boss_kills()` runs on every endless boss kill immediately before Main's handler fires (MetaManager connects first in `_ready()`). After the first kill the count is 1; after subsequent kills it is 2+. This is a single read of an already-tracked value — no new signal, no snapshot variable needed.

**Alternatives considered**:
- New `signal first_boss_kill_recorded` on MetaManager — adds API surface and a new connection for one use case.
- Snapshot `is_first_boss_killed` before teleport, compare after — works but requires an extra field on Main and a two-point comparison.

---

## Decision 2 — Where does popup display fit in the post-boss flow?

**Decision**: Main.gd sets `_first_boss_popup_pending: bool` in `_on_boss_room_cleared()`. The popup is shown at the point the victory overlay would normally appear: inside `_show_boss_victory_overlay()` if the flag is set — popup shown first, OK dismissal triggers the overlay. If `_boss_relic_pending` is true (relic offer fires before victory overlay), the same `_show_boss_victory_overlay()` path is used after relic pick, so the ordering is automatic.

**Rationale**: `_show_boss_victory_overlay()` is already the single convergence point for both the relic and no-relic paths (it is an extracted helper, called from both `_on_boss_room_cleared` directly and from `_on_relic_picked` when `_boss_relic_pending`). Inserting the popup here means it works correctly for both paths with a single code change.

**Alternatives considered**:
- Show popup in `_on_boss_room_cleared()` directly — breaks the relic-active path because the relic offer hasn't shown yet.
- Show popup in `_on_relic_picked()` for the relic path and in `_on_boss_room_cleared()` for the no-relic path — duplicates the popup logic across two callsites.

---

## Decision 3 — Gate text in JSON or code?

**Decision**: `gate_text` stored in JSON under `mage_tower.upgrades.boss_challenge.gate_text` (alongside existing `name` and `cost` keys). Read by `MageTowerUpgradeScreen` via the same `_entries` dict merge.

**Rationale**: Consistent with Principle II — no string constants in code. Also allows the text to be changed without touching GDScript.

---

## Decision 4 — How does `_apply_entry` handle the gate?

**Decision**: Each entry dict may optionally contain `gate_prop: String` and `gate_text: String`. `_apply_entry` checks: if `gate_prop` is non-empty AND `MetaManager.get(gate_prop) == false`, show `gate_text` and disable — no affordability check. Otherwise fall through to existing owned/cost logic. Entries without `gate_prop` are completely unaffected.

**Rationale**: Opt-in gate per entry — no other entries carry `gate_prop`, so their behaviour is unchanged. The existing `_apply_entry` logic is not restructured, just prepended with one guard.

---

## Decision 5 — Popup scene location

**Decision**: `scenes/ui/boss_kill_popup/BossKillPopup.tscn` + `BossKillPopup.gd`. Follows the co-location rule; placed in `scenes/ui/` alongside other transient overlay scenes. Instantiated by Main.gd into a new `_boss_kill_popup_layer: CanvasLayer`, freed on OK press.

**Rationale**: Mirrors the pattern used by `BossVictoryOverlay`, `RelicOfferScreen`, and `ResultsScreen` — all instantiated by Main into a dedicated CanvasLayer.
