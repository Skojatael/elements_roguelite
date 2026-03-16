# Research: Gold Idle Currency

**Feature**: 041-gold-idle-currency
**Date**: 2026-03-13

---

## Decision 1: Idle Generation Strategy

**Decision**: Option A (timestamp delta) with timestamp stamped on every save, not just session end.

**Rationale**: The existing `save_meta_state()` path writes all fields in a single JSON write, making the `(total_gold, gold_last_saved_timestamp)` pair inherently atomic — no extra work needed. Stamping the timestamp on every save (not just clean exit) means crash recovery is handled automatically: the offline credit on next launch covers the gap from the last save to relaunch, which naturally includes any in-session gold that was not yet flushed.

The math:
- Last save: T0, gold = G0, timestamp = T0
- Crash at T1 (accumulated G1 − G0 in memory, lost)
- Reopen at T2: elapsed = T2 − T0, credit = (T2 − T0) × rate
- Result: G0 + (T2 − T0) × rate = G0 + (T1 − T0) × rate [in-session] + (T2 − T1) × rate [offline] ✓

**Alternatives considered**:
- Option B (periodic auto-save): No benefit over the current approach since the timestamp is already stamped on every existing save trigger. A dedicated gold-only timer would add complexity for zero gain.
- Option C (OS background task): Overkill. Requires native GDExtension, complicates the build, and provides no meaningful accuracy improvement at 100 gold/hour.

---

## Decision 2: Where does tick logic live?

**Decision**: `MetaManagerImpl` (at `scripts/managers/MetaManager.gd`) gains `tick_gold(delta: float, rate_per_hour: float) -> int` and `apply_offline_gold(now_unix: int, rate_per_hour: float) -> void`. `MetaManager` autoload calls these from `_process()` and `_ready()` respectively.

**Rationale**: Consistent with the thin-wrapper pattern already established — all algorithmic logic in the impl, autoload delegates. `SaveManagerImpl` stays a pure serializer; it never needs to know the current time.

**How timestamp is stamped**: `MetaManagerImpl` gains a `_save(save_manager)` private helper that sets `meta_state.gold_last_saved_timestamp = int(Time.get_unix_time_from_system())` before every `save_manager.save_meta_state(meta_state)` call. All existing save callsites in MetaManagerImpl are routed through `_save()`.

---

## Decision 3: Signal contract

**Decision**: `MetaManager` emits `signal gold_changed(new_floor: int)` — the floor value, not the raw float. Emitted only when the floor changes (avoids redundant redraws). Emitted once after offline credit on `_ready()`, and on every frame where `floori(total_gold)` changes.

**Rationale**: Matches `shards_changed(new_total: int)` pattern already in use. `GoldDisplay` needs the integer; flooring at the signal site means the display never needs to call `floori()` itself.

---

## Decision 4: Rate as data

**Decision**: `gold_rate_per_hour: 100` added to `data/meta_config.json` (top-level key). Read by `MetaManager` via `ResourceManager.get_meta_config()`.

**Rationale**: Principle II — no hardcoded balance constants in GDScript.

---

## Decision 5: GoldDisplay scene

**Decision**: New `GoldDisplay.tscn` + `GoldDisplay.gd` in `scenes/hub/`, following the exact pattern of `ShardDisplay`. Exported `_label: Label`. Connects to `MetaManager.gold_changed` in `_ready()`. Initialises from `floori(MetaManager.total_gold)` on load.

**Rationale**: Self-contained, co-located with its scene, zero cross-scene coupling. No shared base class — two scenes is not sufficient to justify an abstraction (Principle V).

---

## Decision 6: Timestamp for new players

**Decision**: `gold_last_saved_timestamp = 0` in `MetaState` default. `apply_offline_gold` returns early if timestamp is 0 (treats as "no prior session"). Next save stamps the real time.

**Rationale**: Avoids crediting a new player with gold computed from Unix epoch (1970) to now.
