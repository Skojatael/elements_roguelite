# Research: Conditional Damage Relics

**Feature**: 024-execute-relic
**Date**: 2026-03-03

---

## Decision 1: How to expose enemy HP ratio to CombatComponent

**Decision**: Add `get_hp_ratio() -> float` to `Enemy.gd`.

**Rationale**: `Enemy._stats` is a private `@onready` var (StatsComponent). CombatComponent already casts attack targets to `Enemy` and calls `take_damage()`. A `get_hp_ratio()` method gives CombatComponent exactly the value it needs without exposing the internal StatsComponent reference. If `max_health` is 0 (invalid data), the method returns `1.0` (no bonus), satisfying the edge-case requirement.

**Alternatives considered**:
- Expose `_stats` as public: rejected — unnecessary coupling, exposes the full StatsComponent API to callers.
- Read `current_health`/`max_health` as public fields on Enemy: rejected — more surface area than needed for a single ratio query.

---

## Decision 2: How CombatComponent reads player HP for the berserker check

**Decision**: Add `@export var _stats_component: StatsComponent` to CombatComponent; assign in Inspector.

**Rationale**: CombatComponent is a sibling component inside Player.tscn alongside StatsComponent. Constitution Principle IV requires `@export var` for child-node references rather than hardcoded `$NodePath` strings. The export is assigned once in the Godot Editor (Inspector drag-and-drop) and is stable for the lifetime of the scene.

**Alternatives considered**:
- `get_parent().get_node("StatsComponent")`: rejected — hardcoded path string, violates Principle IV.
- Signal from StatsComponent to CombatComponent syncing current HP: rejected — adds moving parts for a per-frame read that's already free via a direct reference.

---

## Decision 3: Where the conditional thresholds and multipliers live

**Decision**: Hardcoded constants in CombatComponent (`0.30`, `0.50`, `1.35`, `1.30`).

**Rationale**: These values are part of the mechanic's code, not tunable balance entries the way enemy stats or upgrade costs are. The relic's description is already stored in JSON (data-driven identity). The thresholds are mechanics-level constants tied to the specific code path that implements them. Extracting them to JSON would require a generic conditional-relic data schema and evaluation engine — premature abstraction for two relics (Principle V).

**Known limitation**: If a third conditional relic of the same type is added, revisit whether to introduce a data-driven conditional schema.

**Alternatives considered**:
- Store thresholds in `relics.json` alongside the entry: rejected — requires a generic conditional evaluation engine in CombatComponent; over-engineering for two relics.

---

## Decision 4: How conditional relics identify themselves

**Decision**: CombatComponent checks `RelicManager.active_relic_ids.has("executioners_mark")` and `RelicManager.active_relic_ids.has("berserker_stone")` by ID string.

**Rationale**: `RelicManager.active_relic_ids` is already a public field. The relic IDs are defined in `relics.json` (data-driven). Checking by ID is the same pattern used implicitly for stat relics (their IDs are stored and their `effect_stat` determines which code path applies them). For conditional relics, the ID is the coupling point, not a magic constant — it directly corresponds to the JSON entry key.

**Alternatives considered**:
- Tag-based check (`relic.tags.has("execute")`): rejected — requires iterating active relics and loading RelicData objects at hit time; more code for the same result.
- New `effect_type` field on RelicData: rejected — adds schema complexity, breaks the existing from_dict() pattern unnecessarily.
