# Research: Gold Offline Storage Cap (043)

## Decision 1: Cap application point

**Decision**: Clamp elapsed time inside `apply_offline_gold()` in MetaManagerImpl.

**Rationale**: `apply_offline_gold()` is the single function responsible for offline gold credit. Clamping `elapsed = mini(elapsed, cap_seconds)` there is the minimal change that correctly enforces the cap without touching `tick_gold()` (which is frame-based, not offline).

**Alternatives considered**: Capping in the autoload `_ready()` was considered and rejected — it would put balance logic in the thin wrapper, violating Principle I.

---

## Decision 2: Signature change for `apply_offline_gold()`

**Decision**: Add `cap_seconds: int` as a parameter to `apply_offline_gold(now_unix, rate_per_hour, cap_seconds, save_manager)`. The caller (autoload `_ready()`) computes cap_seconds from config and passes it in.

**Rationale**: Keeps MetaManagerImpl free of config access (it never touches `ResourceManager` or JSON), consistent with existing pattern where the autoload reads config and passes primitive values into the impl layer. Tests can pass any cap value directly without mocking a config system.

**Alternatives considered**: Reading cap from MetaState (storing seconds in state) was rejected — it conflates player level with a computed value that belongs in config. Computing cap inside the impl by accepting config dict was rejected — impl functions accept primitives, not raw dicts (Constitution II data model rule).

---

## Decision 3: Timestamp reset in `apply_offline_gold()`

**Decision**: After crediting offline gold (whether zero or positive), update `meta_state.gold_last_saved_timestamp = now_unix`. Also update timestamp on first-boot init (timestamp == 0 → set to now_unix without crediting gold). Do NOT update timestamp on clock-rollback early return.

**Rationale**: The spec requires the timer to reset whenever the game opens. The only legitimate skip is a clock rollback (negative elapsed), which should not advance the clock. Not updating on rollback prevents an attacker from rewinding the system clock to exploit the timer.

**Impact on existing tests**: All existing `apply_offline_gold` test calls must have a `cap_seconds` argument added. Existing tests for timestamp update (`test_apply_offline_gold_updates_timestamp`) will now pass correctly since the implementation will update the timestamp.

---

## Decision 4: `purchase_gold_storage_cap()` method pattern

**Decision**: Implement `purchase_gold_storage_cap(cost: int, max_levels: int, save_manager: Node) -> bool` in MetaManagerImpl, identical in structure to `purchase_damage_upgrade()`. Level tracked as `MetaState.gold_storage_cap_level: int`.

**Rationale**: Reuses the existing `get_upgrade_cost(level, base_cost, cost_scale)` helper for scaling costs. Each call increments `gold_storage_cap_level` by 1 up to `max_levels`. Consistent with all other upgrade purchases in the codebase.

**Alternatives considered**: A flat cost per level (not scaling) was considered; rejected in favour of scaling for balance consistency.

---

## Decision 5: `get_gold_storage_cap_seconds()` helper

**Decision**: Add `get_gold_storage_cap_seconds(base_hours: int, hours_per_level: int) -> int` to MetaManagerImpl. Returns `(base_hours + hours_per_level * meta_state.gold_storage_cap_level) * 3600`.

**Rationale**: Pure computation with no side effects — trivially testable. Keeps the autoload and LabUpgradeScreen from duplicating this formula.

---

## Decision 6: Config schema location

**Decision**: Nest `gold_storage_cap` under `alchemy_lab.upgrades` in `data/meta_config.json`, alongside `gold_generator`.

**Fields**: `name`, `base_hours` (4), `hours_per_level` (4), `base_cost` (100), `cost_scale` (1.5), `max_levels` (2).

**Default cap levels**: 0 → 4h (free/default), 1 → 8h (100 shards), 2 → 12h (150 shards).

**Rationale**: Consistent grouping with all other Alchemy Lab upgrades. Data-driven per Constitution II.

---

## Decision 7: GoldDisplay cap label

**Decision**: Update `GoldDisplay.gd` to show a secondary label with the current storage cap (e.g., "Cap: 4h"). Requires an additional `@export var _cap_label: Label` and connection to `MetaManager.shards_changed` signal (since a purchase changes the cap). Show/hide the cap label based on `MetaManager.is_gold_generator_owned`.

**Rationale**: US3 requirement. The existing `gold_changed` signal does not fire on upgrade purchase, so `shards_changed` is used as the trigger (purchases always emit it). Alternatively, a new `gold_storage_cap_changed` signal could be added, but YAGNI — `shards_changed` is sufficient since the UI recalculates on any shard event.
