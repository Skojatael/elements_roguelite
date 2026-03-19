# Research: HP Regeneration (060-hp-regen)

## Decision 1: Where does the regen tick live?

**Decision**: `StatsComponent._process(delta)` — the existing player-health owner.

**Rationale**: StatsComponent already owns `current_health`, `max_health`, `heal()`, and the `health_changed` signal. Adding a per-frame tick here requires zero new scripts and zero architectural change. The `is_player` guard already separates player logic from enemy logic in `_ready()` — the same guard is used in `_process()` to ensure regen only applies to the player.

**Alternatives considered**:
- New `RegenComponent` attached to Player.tscn — rejected; Constitution V (YAGNI) prohibits a new component for a single consumer with no reuse candidates.
- Tick in `RunManager` — rejected; RunManager is not health-aware and crosses Constitution I (SRP).

---

## Decision 2: How is the regen rate accumulated across multiple sources?

**Decision**: Reuse the existing `RelicManager.get_stat_addend("hp_regen")` / `RelicManagerImpl.compute_stat_addend()` path.

**Rationale**: `compute_stat_addend` already sums `effect_mult` values for all held relics matching a given `effect_stat`. This is exactly the additive stacking behaviour required (FR-007). The `crit_chance` stat already uses this path, proving it works for fractional accumulation. No new RelicManager code is needed.

**Alternatives considered**:
- Dedicated `get_regen_rate()` method on RelicManager — rejected; duplicates `get_stat_addend` with no added value.
- Multiplicative stacking via `compute_stat_mult` — rejected; spec explicitly requires additive stacking.

---

## Decision 3: How is the regen rate stored in relics.json?

**Decision**: `effect_stat: "hp_regen"`, `effect_mult: 0.01` (representing 1% per second as a fraction).

**Rationale**: The existing relic schema already supports arbitrary `effect_stat` strings. `compute_stat_addend` returns the raw sum of `effect_mult` values, so `0.01` sums cleanly (two relics → `0.02`). StatsComponent multiplies by `max_health * delta` to get the absolute heal amount each frame.

**Alternatives considered**:
- Storing as integer percentage (1) — rejected; requires division in code, breaking the data-agnostic pattern used by all other relics.

---

## Decision 4: Run-active guard

**Decision**: Check `RunManager.is_run_active` inside `_process()` as an early return.

**Rationale**: Regen must be inactive in the hub and after a run ends (FR-004). `RunManager.is_run_active` is the canonical flag for this; no signal subscription is needed — the per-frame check is trivially cheap.

**Alternatives considered**:
- Connect to `run_started`/`run_ended` to set a local `_regen_active` bool — rejected; adds state that `is_run_active` already encodes, violating Constitution V.
