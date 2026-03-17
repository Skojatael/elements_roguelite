# Research: Alchemy Lab — Essence Condenser Upgrade

**Feature**: 045-shard-generator
**Date**: 2026-03-17

---

## Decision 1: Tick pattern for fractional shard accumulation

**Decision**: Add `shard_accumulator: float = 0.0` to `MetaState`. Every `_process()` frame, delta × rate is added to the accumulator. The floor is extracted as whole shards, the remainder stays in the accumulator. Whole shards are passed to the existing `add_shards()` path.

**Rationale**: `total_shards` is `int` (existing invariant), so fractional progress cannot live there. A float accumulator field is the minimal change — identical to how `total_gold: float` buffers fractional gold. Persisting `shard_accumulator` prevents losing sub-shard progress across restarts.

**Alternatives considered**:
- Use `total_gold` pattern exactly (store a float that is floored for display) — rejected because shards are spent as int and the existing `spend()` / `add_shards()` API assumes int. Changing shard to float would cascade across 10+ call sites.
- Accumulate only whole shards per tick, discarding fractional remainder — rejected because at 2 shards/hour the tick fires at ~30 min intervals, causing noticeable jitter.

---

## Decision 2: Shared offline timestamp and cap with gold generator

**Decision**: `apply_offline_shards()` reads `gold_last_saved_timestamp` (same field used by `apply_offline_gold`). The cap in seconds comes from `get_gold_storage_cap_seconds()`. Both functions are called in `MetaManager._ready()`, with `apply_offline_shards` called **before** `apply_offline_gold` so both observe the original persisted timestamp before `apply_offline_gold` overwrites it via `_save()`.

**Rationale**: FR-007 requires a shared cap. The timestamp and cap are already computed by the gold path; introducing a second timestamp or cap field would duplicate state and risk desync. Call-order is the only coupling required.

**Alternatives considered**:
- Compute elapsed once in the caller and pass it to both functions — cleaner but requires changing `apply_offline_gold`'s signature, which would break existing tests. Call-order is simpler.
- Separate shard timestamp — rejected (unnecessary field, cap desync risk).

---

## Decision 3: Cost formula reuse

**Decision**: Reuse existing `get_upgrade_cost(level, base_cost, scale)` with `base_cost = 600`, `cost_scale = 2.0`. At levels 0/1/2 this yields 600 / 1200 / 2400 exactly. No new cost helper needed.

**Rationale**: The function already exists in MetaManagerImpl and is tested. FR-003 costs match exactly.

---

## Decision 4: Config structure for rates

**Decision**: `meta_config.json` gains a `shard_generator` block under `alchemy_lab.upgrades`:

```json
"shard_generator": {
  "name": "Essence Condenser",
  "base_cost": 600,
  "cost_scale": 2.0,
  "max_levels": 3,
  "rates_per_hour": [2, 3, 5]
}
```

`rates_per_hour[level - 1]` gives the active rate. Index 0 = level 1 rate.

**Rationale**: Mirrors existing upgrade config shapes. An array is cleaner than individual `rate_lv1`, `rate_lv2`, `rate_lv3` keys for a variable-length list.

---

## Decision 5: Purchase uses spend_gold, not spend (shards)

**Decision**: Purchasing the Essence Condenser deducts `total_gold` via `spend_gold()`. It does NOT touch `total_shards`. The upgrade generates shards passively but is paid for in gold, consistent with all other Alchemy Lab upgrades.

**Rationale**: FR-003 states gold costs. Consistent with Transmuter, Gold Storage Cap, and Essence Gain.

---

## Decision 6: `purchase_shard_generator` follows existing purchase pattern

**Decision**: New `MetaManagerImpl.purchase_shard_generator(cost, max_levels, save_manager)` mirrors `purchase_gold_storage_cap` exactly: level-cap guard → `spend_gold` → increment level → save.

**No new `_save()` call needed** — `spend_gold` already saves when it deducts gold. But `essence_gain_level += 1` after the spend means we need one more `_save()`. Pattern is identical to `purchase_essence_gain`.

---

## Existing APIs used (no changes needed)

| API | Location | Usage |
|---|---|---|
| `add_shards(amount, save_manager)` | MetaManagerImpl | Credits shard ticks |
| `get_upgrade_cost(level, base, scale)` | MetaManagerImpl | Computes per-level cost |
| `spend_gold(cost, save_manager)` | MetaManagerImpl | Deducts gold on purchase |
| `get_gold_storage_cap_seconds(...)` | MetaManagerImpl | Shared offline cap |
| `gold_last_saved_timestamp` | MetaState | Shared offline timestamp |
| `shards_changed` signal | MetaManager autoload | Emitted when shards credited |
| `gold_changed` signal | MetaManager autoload | Emitted when gold deducted |
