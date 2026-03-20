# Implementation Plan: Burn Relic Damage Scaling (065)

**Date**: 2026-03-19 | **Spec**: `specs/065-burn-relic-scaling/spec.md`

## Summary

Activate two burn-related relics that exist in the JSON pool but have no live effect. Bottled Oil's `burn_damage` stat multiplier must be applied to burn tick damage at projectile hit time. Searing Seal requires a new boolean parameter threaded through the conditional hit-multiplier pipeline, plus a new `is_burning()` query method on Enemy.

This feature also makes conditional relics fully data-driven: `condition_type`, `condition_threshold`, and `condition_mult` fields are added to `relics.json` and `RelicData`, and `get_hit_damage_mult()` becomes a generic loop with no hard-coded relic IDs or multipliers. Adding future conditional relics requires only JSON changes.

No new files needed — all changes are additive modifications to six existing scripts plus test updates.

## Technical Context

- **Language**: GDScript (Godot 4.6), static typing throughout
- **Files modified**: 7 (no new files, no `.tscn` changes)
- **Testing**: GUT — `tests/unit/test_relic_deck.gd` updated (6 broken call sites fixed + 5 new tests)
- **Performance**: O(n) over active relics per hit — negligible (active relic count is small, typically < 10)

## Constitution Check

- **I. Thin-wrapper rule**: RelicManager autoload forwards the new parameter with no logic. PASS.
- **II. Data-driven content**: Conditional multipliers and thresholds move from code into JSON. Condition type names remain an enum in code (unavoidable — they map to runtime context). PASS (improved).
- **III. Mobile-first**: O(n) over a short active-relics array per hit event. No per-frame scanning. PASS.
- **IV. Editor-centric**: No `.tscn` files modified. No hardcoded `$NodeName` paths. PASS.
- **V. YAGNI**: The data-driven approach is directly motivated by the need to add Searing Seal without hardcoding a third ID — it also retroactively cleans up the two existing hard-coded relics. PASS.
- **VI. Early return**: `is_burning()` uses early return on null guard. Loop uses `continue` on unmet conditions. PASS.

## Files

```
data/relics.json                         — add condition_type/threshold/mult to 3 conditional relics
scripts/data_models/RelicData.gd         — add condition_type, condition_threshold, condition_mult fields
scenes/combat/enemies/Enemy.gd           — add is_burning() public method
scripts/managers/RelicManagerImpl.gd     — replace hard-coded checks with generic condition loop
autoload/RelicManager.gd                 — forward new target_is_burning param in wrapper
scenes/player/components/CombatComponent.gd — pass target.is_burning() to get_hit_damage_mult
scenes/combat/projectiles/Projectile.gd  — multiply burn tick by get_stat_mult("burn_damage")
tests/unit/test_relic_deck.gd            — fix 6 existing call sites + 5 new Searing Seal tests
```

---

## Phase 1 — relics.json: add condition fields

**File**: `data/relics.json`

Add `condition_type`, `condition_threshold`, and `condition_mult` to the three existing conditional relics. Non-conditional relics omit these fields (they will default to empty/zero in RelicData).

```json
"executioners_mark": {
    "name": "Executioner's Mark",
    "tags": ["combat"],
    "effect_stat": "",
    "effect_mult": 1.0,
    "condition_type": "target_hp_below",
    "condition_threshold": 0.30,
    "condition_mult": 1.35,
    "description": "+35% damage to enemies below 30% HP",
    "deck_count": 1
},
"berserker_stone": {
    "name": "Berserker Stone",
    "tags": ["combat"],
    "effect_stat": "",
    "effect_mult": 1.0,
    "condition_type": "attacker_hp_below",
    "condition_threshold": 0.50,
    "condition_mult": 1.30,
    "description": "+30% damage when below 50% HP",
    "deck_count": 1
},
"burn_damage": {
    "name": "Searing Seal",
    "tags": ["burn_unlocked"],
    "effect_stat": "",
    "effect_mult": 1.0,
    "condition_type": "target_is_burning",
    "condition_threshold": 0.0,
    "condition_mult": 1.50,
    "description": "Burning enemies take 50% more damage while burning.",
    "deck_count": 1
}
```

---

## Phase 2 — RelicData: add condition fields

**File**: `scripts/data_models/RelicData.gd`

Add three fields and parse them in `from_dict()`:

```gdscript
var condition_type: String = ""
var condition_threshold: float = 0.0
var condition_mult: float = 1.0
```

In `from_dict()`:
```gdscript
r.condition_type = str(data.get("condition_type", ""))
r.condition_threshold = float(data.get("condition_threshold", 0.0))
r.condition_mult = float(data.get("condition_mult", 1.0))
```

---

## Phase 3 — Enemy.is_burning()

**File**: `scenes/combat/enemies/Enemy.gd`

Add after `get_hp_ratio()`:

```gdscript
## Returns true if the enemy currently has an active burn effect.
## Returns false if no burn has ever been applied or if the burn has expired.
func is_burning() -> bool:
	if _burn == null:
		return false
	return _burn.is_active()
```

---

## Phase 4 — RelicManagerImpl: generic condition loop

**File**: `scripts/managers/RelicManagerImpl.gd`

Replace `get_hit_damage_mult()` entirely:

```gdscript
## Returns the combined damage multiplier from conditional relics at hit time.
## target_hp_ratio:   target's current_hp / max_hp  (0.0–1.0)
## attacker_hp_ratio: attacker's current_hp / max_hp (0.0–1.0)
## target_is_burning: true if the target enemy has an active burn effect
## Returns 1.0 if no conditional relics are active or no conditions are met.
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float, target_is_burning: bool) -> float:
	var mult: float = 1.0
	for relic_id: String in active_relic_ids:
		var relic: Variant = _relics_by_id.get(relic_id)
		if not relic is RelicData:
			continue
		var r: RelicData = relic as RelicData
		if r.condition_type.is_empty():
			continue
		match r.condition_type:
			"target_hp_below":
				if target_hp_ratio < r.condition_threshold:
					mult *= r.condition_mult
			"attacker_hp_below":
				if attacker_hp_ratio < r.condition_threshold:
					mult *= r.condition_mult
			"target_is_burning":
				if target_is_burning:
					mult *= r.condition_mult
	return mult
```

No relic IDs or multiplier values are hard-coded. Adding a new conditional relic requires only a JSON entry with the appropriate `condition_type`.

---

## Phase 5 — RelicManager autoload: forward parameter

**File**: `autoload/RelicManager.gd`

Replace the wrapper:

```gdscript
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float, target_is_burning: bool) -> float:
	return _impl.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio, target_is_burning)
```

---

## Phase 6 — CombatComponent: pass burning state

**File**: `scenes/player/components/CombatComponent.gd`

Update the `get_hit_damage_mult(...)` call to pass `target.is_burning()` as the third argument.

---

## Phase 7 — Projectile: apply burn damage multiplier

**File**: `scenes/combat/projectiles/Projectile.gd`

In `_on_body_entered()`:
```gdscript
primary.on_burn_hit(_damage * _burn_damage_per_tick * RelicManager.get_stat_mult("burn_damage"), _burn_duration, _burn_extend_seconds)
```

In `_try_chain()`:
```gdscript
chain_target.on_burn_hit(_damage * _burn_damage_per_tick * RelicManager.get_stat_mult("burn_damage"), _burn_duration, _burn_extend_seconds)
```

Both burn-hit call sites updated so scaling applies regardless of direct hit or chain hit.

---

## Phase 8 — Tests

**File**: `tests/unit/test_relic_deck.gd`

**Step 8a** — Fix 6 existing broken call sites (add `false` as third arg):

```gdscript
_impl.get_hit_damage_mult(0.5, 0.5, false)
_impl.get_hit_damage_mult(0.29, 0.6, false)
_impl.get_hit_damage_mult(0.30, 0.6, false)
_impl.get_hit_damage_mult(0.8, 0.49, false)
_impl.get_hit_damage_mult(0.8, 0.50, false)
_impl.get_hit_damage_mult(0.20, 0.30, false)
```

**Step 8b** — Add 5 new Searing Seal tests. These also implicitly validate that the generic loop correctly reads `condition_mult` and `condition_threshold` from relic data, so the test setup must use relics loaded from the real JSON (via `build_pool`) rather than bare `active_relic_ids.append`.

```gdscript
func test_searing_seal_no_bonus_when_target_not_burning() -> void:
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("burn_damage")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.8, false), 1.0, 0.0001,
		"searing_seal must apply no bonus when target is not burning")


func test_searing_seal_bonus_when_target_burning() -> void:
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("burn_damage")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.8, true), 1.50, 0.0001,
		"searing_seal must apply 1.50x multiplier when target is burning")


func test_searing_seal_no_bonus_without_relic() -> void:
	_impl.active_relic_ids.clear()
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.8, true), 1.0, 0.0001,
		"no searing_seal held — no bonus even when target is burning")


func test_searing_seal_stacks_with_executioners_mark() -> void:
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("burn_damage")
	_impl.active_relic_ids.append("executioners_mark")
	assert_almost_eq(_impl.get_hit_damage_mult(0.20, 0.8, true), 1.50 * 1.35, 0.0001,
		"searing_seal and executioners_mark both active — multiplicative stacking")


func test_searing_seal_stacks_with_berserker_stone() -> void:
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("burn_damage")
	_impl.active_relic_ids.append("berserker_stone")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.30, true), 1.50 * 1.30, 0.0001,
		"searing_seal and berserker_stone both active — multiplicative stacking")
```

---

## CLAUDE.md Assessment

No update required. The data-driven conditional relic pattern is a refinement of the existing Relic System architecture — no new architectural concept is introduced.

`repo_map.md` will need updating after implementation to reflect:
- `Enemy.gd` gains `is_burning() -> bool`
- `RelicData.gd` gains `condition_type`, `condition_threshold`, `condition_mult`
- `RelicManagerImpl.gd` / `RelicManager.gd` — `get_hit_damage_mult` signature changes
