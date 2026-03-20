# Implementation Plan: Poison Mechanic

**Branch**: `073-poison-mechanic` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)

## Summary

Add a bidirectional poison status effect. Poisonous enemies apply it to the player on contact damage; the player can apply it to enemies via a new Common-tier relic on melee hit. Poison reduces the poisoned entity's outgoing attack damage by a configurable modifier fraction for a configurable duration. Duration stacks additively on re-application; modifier stays constant.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Storage**: `data/enemies.json`, `data/relics.json` (existing JSON layer)
**Testing**: GUT unit tests (`tests/unit/`)
**Target Platform**: Mobile portrait, 60 fps (Jolt physics, Mobile renderer)
**Performance Goals**: Poison tick is one duration decrement per `_physics_process` — negligible cost.
**Constraints**: No new autoloads. No new scenes (editor-side: one new child node in Player.tscn). PoisonComponent must be reachable via `get_node_or_null("PoisonComponent")` by Enemy, matching the RootComponent grab pattern.

## Constitution Check

- **I. Single Responsibility**: `PoisonComponent` owns only poison state + timer. Enemy owns its own poison state; it does not manage the player's. RelicManagerImpl owns the relic-side proc logic. CombatComponent only reads the modifier at attack time. ✅
- **II. Data-Driven Content**: `poison_duration`, `poison_modifier` in `enemies.json`; `poison_chance`, `poison_duration`, `poison_modifier` in `relics.json`. No hard-coded balance values. ✅
- **III. Mobile-First**: PoisonComponent `_physics_process` is a single float decrement; Enemy adds one null-check per contact-damage tick. No draw calls, no allocations per frame. ✅
- **IV. Editor-Centric**: PoisonComponent added to Player.tscn via Godot Editor. CombatComponent accesses it via `@onready` path (architecturally fixed component name, consistent with existing `$"../StatsComponent"` pattern in CombatComponent). No `.tscn` edits as raw text. ✅
- **V. Simplicity & YAGNI**: One new class (`PoisonComponent`), two data-model extensions, one new relic, one new enemy field pair. No intermediate layers. ✅
- **VI. Early Return**: All new methods use guard clauses. ✅

## Decisions

**Decision 1 — PoisonComponent as Node (not RefCounted)**
The enemy-to-player application direction requires Enemy to grab a reference to the player's poison state via `body.get_node_or_null("PoisonComponent")`, exactly as it grabs `RootComponent`. A RefCounted object cannot be found this way. Using a Node also removes the need to manually tick the player's poison duration in CombatComponent — `PoisonComponent._physics_process` handles it automatically.

**Decision 2 — PoisonComponent location: `scripts/PoisonComponent.gd`**
PoisonComponent is used by two distinct scenes: Player.tscn (as a permanent child node) and Enemy.gd (instantiated in `_ready()` via `PoisonComponent.new(); add_child(...)`). Per the constitution's co-location rule, a script used by two or more scenes must live in `res://scripts/`. This also matches the spirit of the rule: it is a shared, reusable component, not exclusive to Player.tscn.

**Decision 3 — `poison_modifier` stored as a fraction (0.0–1.0)**
All modifier values in this codebase use decimal fractions (`damage_reduction: 0.10` = 10%). The pre-existing `forest_poisoner` entry in `enemies.json` incorrectly stores `"poison_modifier": 10.0` (likely entered as a raw percentage). This will be corrected to `0.10` during this feature. The new relic will use `"poison_modifier": 0.15`.

## Schema Changes

### `scripts/PoisonComponent.gd` (new file)
`class_name PoisonComponent extends Node`. Fields: `_remaining_duration: float = 0.0`, `_damage_modifier: float = 0.0`. Computed property `is_poisoned: bool`. Methods: `apply(duration: float, modifier: float)` — stacks duration, sets modifier only on fresh application; `get_damage_mult() -> float` — returns `1.0 - _damage_modifier` while active, else `1.0`; `_physics_process(delta)` — decrements remaining duration.

### `scripts/data_models/EnemyData.gd`
Add two optional fields with defaults: `poison_duration: float = 0.0`, `poison_modifier: float = 0.0`. Parsed from JSON in `from_dict()` via `data.get(...)` with 0.0 defaults (backward compatible — existing enemies without these fields are unaffected).

### `scripts/data_models/RelicData.gd`
Add three optional fields with defaults: `poison_chance: float = 0.0`, `poison_duration: float = 0.0`, `poison_modifier: float = 0.0`. Parsed in `from_dict()` via `data.get(...)` with 0.0 defaults.

### `data/enemies.json`
Fix `forest_poisoner.poison_modifier` from `10.0` to `0.10` (fraction, not percentage).

### `data/relics.json`
Add `venomous_strike` entry in the `"common"` tier. Fields: `name: "Venom Fang"`, `tags: ["melee", "debuff"]`, `effect_stat: ""`, `effect_mult: 1.0`, `condition_type: ""`, `poison_chance: 0.25`, `poison_duration: 3.0`, `poison_modifier: 0.15`, `description: "Melee hits have a 25% chance to poison enemies, reducing their damage by 15% for 3s."`, `deck_count: 2`.

## Affected Files

### New files

**`scripts/PoisonComponent.gd`**
New Node-based component implementing poison state for both Player and Enemy. Provides `apply()`, `get_damage_mult()`, and a self-ticking `_physics_process`. Placed in `scripts/` because it is instantiated by Enemy.gd as well as parented to Player.tscn.

**`tests/unit/test_poison_component.gd`**
GUT unit test covering: fresh apply sets duration and modifier; re-apply stacks duration and keeps modifier; `get_damage_mult()` returns correct fraction while active and 1.0 after expiry; apply with duration ≤ 0 is a no-op.

### Modified files

**`scripts/data_models/EnemyData.gd`**
Add `poison_duration: float` and `poison_modifier: float` fields with 0.0 defaults. Extend `from_dict()` to parse them optionally.

**`scripts/data_models/RelicData.gd`**
Add `poison_chance: float`, `poison_duration: float`, and `poison_modifier: float` fields with 0.0 defaults. Extend `from_dict()` to parse them optionally.

**`data/enemies.json`**
Correct `forest_poisoner.poison_modifier` from `10.0` to `0.10`.

**`data/relics.json`**
Add `venomous_strike` relic entry in the `"common"` tier.

**`scenes/combat/enemies/Enemy.gd`**
Add `_poison: PoisonComponent` (enemy's own poison state — instantiated in `_ready()` and added as child, mirroring the existing `_root: RootComponent` pattern). Add `_player_poison: PoisonComponent` (reference grabbed in `_on_contact_entered`, cleared in `_on_contact_exited`). Add `apply_poison(duration, modifier)` public method that delegates to `_poison.apply(...)`. Modify the contact-damage block in `_physics_process` to: (a) multiply `_data.damage` by `_poison.get_damage_mult()` before sending to the player (enemy's own outgoing damage is reduced when it is poisoned), and (b) after dealing contact damage, call `_try_apply_poison()` if `_data.poison_duration > 0.0`. Add `_try_apply_poison()` private method that guards on `_player_poison != null` and calls `_player_poison.apply(_data.poison_duration, _data.poison_modifier)`.

**`scenes/player/components/CombatComponent.gd`**
Add `@onready var _poison: PoisonComponent = $"../PoisonComponent"`. In the melee attack block: multiply final `dmg` by `_poison.get_damage_mult()` before passing to `target.take_damage()` (player's outgoing damage reduced when player is poisoned). After `target.take_damage(dmg)`, call `RelicManager.try_apply_poison(target)`.

**`scripts/managers/RelicManagerImpl.gd`**
Add constant `POISON_RELIC_ID: String = "venomous_strike"`. Add `has_poison_relic() -> bool`. Add `try_apply_poison(target: Enemy) -> void` — guards on `has_poison_relic()`, reads relic's `poison_chance`, rolls `randf()`, and on success calls `target.apply_poison(relic.poison_duration, relic.poison_modifier)`.

**`autoload/RelicManager.gd`**
Add thin-wrapper method `try_apply_poison(target: Enemy) -> void` that delegates to `_impl.try_apply_poison(target)`.

**`scenes/player/Player.tscn`** *(Editor task)*
Add `PoisonComponent` as a child node of Player (script: `res://scripts/PoisonComponent.gd`). No exported properties to configure — all behaviour is internal.
