# Research: Gold Generator Gate (042)

## Decision 1: Config key location

**Decision**: Add `gold_generator` under `alchemy_lab.upgrades` in `meta_config.json`, not at the top level.

**Rationale**: The Transmuter is an Alchemy Lab upgrade, structurally identical to `essence_gain`. Reading it via `ResourceManager.get_meta_config().get("alchemy_lab", {}).get("upgrades", {}).get("gold_generator", {})` matches the existing pattern in `LabUpgradeScreen._update_buttons()`.

**Alternatives considered**: Top-level key (rejected — inconsistent with building-upgrade hierarchy already established for `magic_forge`, `mage_tower`, and `alchemy_lab`).

---

## Decision 2: Gate placement — impl layer vs. autoload layer

**Decision**: Gate gold accumulation inside `MetaManagerImpl.tick_gold()` and `MetaManagerImpl.apply_offline_gold()` via an early return on `meta_state.gold_generator_owned == false`.

**Rationale**: Constitution Principle I requires no algorithmic logic in autoloads. The gate is a conditional suppression of accumulation logic — it belongs in the impl. The autoload `MetaManager._process()` and `_ready()` remain unchanged: they call the impl methods unconditionally, and the impl decides whether to mutate state.

**Alternatives considered**: Gate in `MetaManager._process()` and `_ready()` (rejected — puts conditional logic in the autoload, violating Principle I thin-wrapper rule).

---

## Decision 3: Gold balance and timestamp reset behaviour on first load

**Decision**: On first load after the feature ships, `gold_generator_owned` defaults to `false`. Since `tick_gold()` and `apply_offline_gold()` both gate on this flag, no gold is credited regardless of the `gold_last_saved_timestamp` value. No explicit reset of `total_gold` or `gold_last_saved_timestamp` is needed — the gate is sufficient.

**Rationale**: Feature 041 (gold idle currency) is still in development; no player save files exist in the wild with `total_gold > 0`. A hard reset is unnecessary complexity (YAGNI, Principle V).

**Alternatives considered**: Explicit reset of `total_gold = 0.0` and `gold_last_saved_timestamp = 0` on load when `gold_generator_owned == false` (rejected — over-engineering for a pre-release scenario; the gate alone achieves the correct behaviour).

---

## Decision 4: Transmuter button wiring in LabUpgradeScreen

**Decision**: Connect `_transmuter_button.pressed` in `_ready()` via GDScript (not via the Godot Editor signal dock) for the new Transmuter entry.

**Rationale**: The existing `_close_button.pressed` is already connected in `_ready()`. Consistent approach. Also, one-time purchase logic (enable/disable) must be managed in `_update_buttons()`, which already runs on `shards_changed`.

**Alternatives considered**: Editor-signal connection (rejected — existing close button is code-connected; mixing methods creates inconsistency. Also, purchase calls `MetaManager.purchase_gold_generator()` which requires no inspector setup).

---

## Decision 5: No new autoload or service

**Decision**: No new autoload or dedicated service is introduced. All new logic fits within `MetaManagerImpl` (one additional purchase method + guards in two existing methods), `MetaState` (one new field), `SaveManagerImpl` (one new field in serialize/deserialize), and `LabUpgradeScreen` (one new button + handler).

**Rationale**: Principle V (YAGNI) — the change is small enough that a dedicated abstraction is unjustified. Principle I — MetaManager already owns the gold-generation domain.
