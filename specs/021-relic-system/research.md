# Research: Relic System

**Feature**: 021-relic-system
**Date**: 2026-03-02

---

## Decision 1: Logic Location for Relic Domain

**Decision**: `RelicManagerImpl` (in `scripts/managers/RelicManagerImpl.gd`) holds all algorithmic relic logic — offer frequency tracking, offer drawing, stat mult computation. `autoload/RelicManager.gd` is the thin wrapper.

**Rationale**: Consistent with the established pattern (`MetaManagerImpl`, `ResourceManagerImpl`, `SaveManagerImpl`). Keeps the autoload as a signal/state/delegation surface only. Satisfies the Constitution I thin-wrapper rule.

**Alternatives considered**:
- Separate `RelicService.gd` for stat application — rejected: unnecessary split for a single cohesive domain. RelicManagerImpl handles everything.
- Embed logic directly in RunManager — rejected: different domain (relics vs run session lifecycle). Would violate SRP.

---

## Decision 2: Offer Triggering — Integration with RunManager

**Decision**: `RelicManager` autoload connects to `RunManager.room_cleared` signal. At that point, `RunManager.current_room` still references the cleared RoomSpawner, so `room_type_id` is readable. RelicManagerImpl's `should_offer_for_room(room_type_id)` handles frequency logic in-place.

**Rationale**: `room_cleared` fires in `RunManager._on_room_cleared()` before any room transition. `current_room` is only nulled on door touch (`RoomLoader` sets `RunManager.current_room = null` before loading the next room). So the room_type_id is always accessible when the signal fires.

**Elite detection**: `room_type_id.contains("Elite")` — more robust than exact string match, accommodates any future elite room type IDs.

**Alternatives considered**:
- Tracking room type inside RunManager.room_cleared signal payload — rejected: would require changing existing signal signature.
- Checking room type ID from the dungeon layout dictionary — rejected: requires coupling to DungeonGenerator; current_room is simpler.

---

## Decision 3: Stat Multiplier Application — Reactive Signal Pattern

**Decision**: `RelicManager` emits `relic_applied(relic_id)` when a relic is picked. `CombatComponent` and `StatsComponent` connect to this signal in `_ready()` and recompute their stats from their cached base values.

- **CombatComponent**: Renames `_apply_damage_multiplier()` → `_recompute_stats()`. Adds `_base_attack_interval` cache. New formula: `attack_damage = _base_attack_damage * MetaManager.damage_multiplier * RelicManager.get_stat_mult("attack_damage")`. Attack speed: `attack_interval = _base_attack_interval / RelicManager.get_stat_mult("attack_speed")`.
- **StatsComponent**: Adds `_base_max_health` cached in `_ready()`. On `relic_applied`, recomputes `max_health = _base_max_health * RelicManager.get_stat_mult("max_health")`. Current health scales proportionally.

**Rationale**: Keeps each component responsible for its own stat. No direct coupling between RelicManager and player component internals. Same pattern already used for MetaManager damage multiplier.

**Alternatives considered**:
- RelicManager directly mutating player component fields — rejected: tight coupling, bypasses component encapsulation.
- Polling RelicManager in `_process()` — rejected: wasteful, relics don't change continuously.

---

## Decision 4: Offer UI — CanvasLayer Overlay + Joystick Hiding

**Decision**: `Main.gd` listens to `RelicManager.relic_offer_ready`. On signal: hides ExplorationHUD (disabling joystick), creates a CanvasLayer, instantiates `RelicOfferScreen.tscn` into it, calls `setup(options)`. On `relic_picked`: calls `RelicManager.pick_relic(id)`, frees CanvasLayer, shows ExplorationHUD.

**Rationale**: Hiding ExplorationHUD disables the joystick (it has no built-in disable — JoystickControl uses `_input` which still fires but gets consumed by the CanvasLayer overlay's touch blocks). This matches how ExplorationHUD is hidden during the results screen. The CanvasLayer pattern matches ResultsScreen exactly.

**Input blocking**: RelicOfferScreen's root Panel/ColorRect uses `mouse_filter = STOP` to absorb all pointer events. The full-screen background blocks touch from reaching the joystick area.

**Alternatives considered**:
- Player pausing via `get_tree().paused = true` — rejected: would pause signals and timers needed for the offer screen itself.
- Adding a `disabled` property to JoystickControl — rejected: extra modification to an existing component for a single use case.

---

## Decision 5: Relic Data File + Typed Model

**Decision**: New `data/relics.json` with a top-level `"relics"` array. Each entry has: `id`, `name`, `tier`, `tags`, `effect_stat`, `effect_mult`, `description`. Loaded by `ResourceManagerImpl.get_relics()` which caches the raw Dictionary. `RelicManager` converts to `Array[RelicData]` at run start using `RelicData.from_dict()`.

**Rationale**: Consistent with all other data files (`enemies.json`, `meta_config.json`). `RelicData.gd` is the typed wrapper (Constitution II). JSON stays engine-agnostic. Conversion happens once at run start, not every frame.

**Initial relic pool** (5 relics covering all 3 stat categories):
| ID | Name | Tier | Effect Stat | Mult |
|---|---|---|---|---|
| `sharp_edge` | Sharp Edge | common | attack_damage | 1.2 |
| `rage_crystal` | Rage Crystal | rare | attack_damage | 1.3 |
| `swift_strike` | Swift Strike | common | attack_speed | 1.25 |
| `iron_hide` | Iron Hide | common | max_health | 1.3 |
| `vital_core` | Vital Core | rare | max_health | 1.5 |

---

## Decision 6: Relic Stacking Rule

**Decision**: Multiplicative stacking. `compute_stat_mult(stat)` iterates `active_relic_ids`, finds all relics with matching `effect_stat`, multiplies their `effect_mult` values together. Returns 1.0 if no relics modify that stat.

**Example**: Two `attack_damage` relics with mult 1.2 and 1.3 → `1.0 * 1.2 * 1.3 = 1.56`.

**Rationale**: Spec explicitly states multiplicative (Assumptions section). Standard roguelite compounding pattern.

---

## Decision 7: PlayerState.active_modifiers

**Decision**: Replace the stub `var modifiers: Array = []` in `PlayerState.gd` with `var active_modifiers: Array[String] = []`. `RelicManager.pick_relic()` appends to both `RelicManagerImpl.active_relic_ids` and `RunManager.player_state.active_modifiers` so both stay in sync.

**Rationale**: Spec requirement: "PlayerState.active_modifiers: Array[String] (store IDs)". Typed array over untyped stub. `player_state` is recreated fresh on each `start_run()`, so no explicit reset needed for that field.

---

## Decision 8: Pool Exhaustion

**Decision**: If the pool has only 1 relic, offer shows that relic twice. If pool is empty, offer is skipped silently (degenerate edge case with 0 relics configured — should not occur in practice). Implemented in `RelicManagerImpl.draw_offer()`.

**Rationale**: Spec Assumption: "draw with replacement". With 5+ relics in pool, this edge case never triggers in normal play.
