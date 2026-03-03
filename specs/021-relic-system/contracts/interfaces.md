# Contracts: Relic System

**Feature**: 021-relic-system
**Date**: 2026-03-02

GDScript interface contracts. All new or modified method signatures, signals, and field expectations.

---

## RelicData (scripts/data_models/RelicData.gd) — NEW

```gdscript
class_name RelicData
extends RefCounted

var id: String = ""
var name: String = ""
var tier: String = ""
var tags: Array[String] = []
var effect_stat: String = ""   # "attack_damage" | "attack_speed" | "max_health"
var effect_mult: float = 1.0
var description: String = ""

static func from_dict(data: Dictionary) -> RelicData
```

**Invariant**: `effect_mult > 0.0`. Callers must not construct RelicData with negative or zero mult.

---

## RelicManagerImpl (scripts/managers/RelicManagerImpl.gd) — NEW

```gdscript
class_name RelicManagerImpl
extends RefCounted

const OFFER_INTERVAL: int = 2

var active_relic_ids: Array[String] = []
var standard_rooms_cleared: int = 0
var relic_pool: Array[RelicData] = []

## Clears all run state (active_relic_ids, standard_rooms_cleared, relic_pool).
func reset() -> void

## Parses raw relics.json Dictionary into relic_pool Array[RelicData].
func build_pool(raw: Dictionary) -> void

## Returns true if a relic offer should trigger for the given room type.
## SIDE EFFECT: increments standard_rooms_cleared for non-elite rooms,
## resets it to 0 when OFFER_INTERVAL is reached.
## Elite rooms: always returns true, does NOT touch standard_rooms_cleared.
func should_offer_for_room(room_type_id: String) -> bool

## Returns Array[RelicData] of exactly 2 entries drawn from relic_pool.
## If pool.size() == 1: returns same entry twice.
## If pool.is_empty(): returns [].
## Otherwise: returns 2 distinct entries (shuffled).
func draw_offer() -> Array[RelicData]

## Appends relic_id to active_relic_ids.
func pick_relic(relic_id: String) -> void

## Returns the compounded effect_mult for all held relics with effect_stat == stat.
## Returns 1.0 if no held relics match the stat.
func compute_stat_mult(stat: String) -> float
```

---

## RelicManager (autoload/RelicManager.gd) — NEW

```gdscript
extends Node

## Emitted when an offer screen should appear. options is Array[RelicData] (2 entries).
signal relic_offer_ready(options: Array)

## Emitted immediately after a relic is added to the active collection.
signal relic_applied(relic_id: String)

## Emitted when active relics are cleared (run start or run end).
signal relics_cleared()

## The relic IDs held by the player this run. Read-only for all systems except RelicManager.
var active_relic_ids: Array[String]:
    get: return _impl.active_relic_ids

## Adds relic_id to the active collection, updates PlayerState, emits relic_applied.
## Precondition: relic_id must exist in the loaded relic pool.
func pick_relic(relic_id: String) -> void

## Returns the combined multiplier for the given stat across all active relics.
## Returns 1.0 if no relics modify that stat.
func get_stat_mult(stat: String) -> float
```

**Connections made in `_ready()`**:
- `RunManager.run_started → _on_run_started()` (lambda for arg discard)
- `RunManager.run_ended → _on_run_ended()` (lambda for arg discard)
- `RunManager.room_cleared → _on_room_cleared(room_id)`

---

## ResourceManagerImpl (scripts/managers/ResourceManager.gd) — MODIFIED

```gdscript
## Returns raw parsed Dictionary from data/relics.json. Cached after first load.
## Root key: "relics" → Array of relic entry Dictionaries.
func get_relics() -> Dictionary
```

## ResourceManager autoload (autoload/ResourceManager.gd) — MODIFIED

```gdscript
## Delegates to _impl.get_relics().
func get_relics() -> Dictionary
```

---

## PlayerState (scripts/data_models/PlayerState.gd) — MODIFIED

**Remove**: `var modifiers: Array = []`
**Add**:
```gdscript
## Relic IDs collected this run. Appended by RelicManager.pick_relic().
## Read-only for all systems except RelicManager.
var active_modifiers: Array[String] = []
```

---

## CombatComponent (scenes/player/components/CombatComponent.gd) — MODIFIED

```gdscript
# New cached field:
var _base_attack_interval: float = 0.0

# Rename existing _apply_damage_multiplier() to _recompute_stats()
# and extend to cover attack_speed relic mult:
func _recompute_stats() -> void:
    attack_damage = _base_attack_damage * MetaManager.damage_multiplier \
        * RelicManager.get_stat_mult("attack_damage")
    attack_interval = _base_attack_interval / RelicManager.get_stat_mult("attack_speed")
```

**New connection in `_ready()`**:
```gdscript
RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_stats())
RelicManager.relics_cleared.connect(func() -> void: _recompute_stats())
```

**Existing connection** (unchanged, renamed method):
```gdscript
RunManager.run_started.connect(func(_m: String) -> void: _recompute_stats())
```

---

## StatsComponent (scenes/player/components/StatsComponent.gd) — MODIFIED

```gdscript
# New cached field:
var _base_max_health: float = 0.0

# Cache in _ready() (after existing assert):
_base_max_health = max_health

# New method:
func _on_relic_applied(_relic_id: String) -> void:
    var new_max: float = _base_max_health * RelicManager.get_stat_mult("max_health")
    if is_equal_approx(new_max, max_health):
        return
    var ratio: float = current_health / max_health
    max_health = new_max
    current_health = clampf(new_max * ratio, 1.0, new_max)
    health_changed.emit(current_health, max_health)
```

**New connections in `_ready()`**:
```gdscript
RelicManager.relic_applied.connect(_on_relic_applied)
RelicManager.relics_cleared.connect(func() -> void: _on_relic_applied(""))
```

---

## MovementComponent (scenes/player/components/MovementComponent.gd) — MODIFIED

```gdscript
# New cached field:
var _base_move_speed: float = 0.0

# New connections in _ready() (after existing assert):
RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_stats())
RelicManager.relics_cleared.connect(func() -> void: _recompute_stats())

# New method:
func _recompute_stats() -> void:
    move_speed = _base_move_speed * RelicManager.get_stat_mult("move_speed")
```

---

## RelicOfferScreen (scenes/ui/relic_offer/RelicOfferScreen.gd) — NEW

```gdscript
class_name RelicOfferScreen
extends Control

## Emitted when the player selects a relic. Carries the chosen relic's id.
signal relic_picked(relic_id: String)

@export var _card_left: RelicCard
@export var _card_right: RelicCard

## Populates both cards with the two relic options.
## options: Array[RelicData] with exactly 2 entries.
func setup(options: Array) -> void
```

---

## RelicCard (scenes/ui/relic_offer/RelicCard.gd) — NEW

```gdscript
class_name RelicCard
extends Panel

## Emitted when the player taps the Choose button on this card.
signal relic_selected(relic_id: String)

@export var _name_label: Label
@export var _desc_label: Label
@export var _button: Button

## Populates labels with relic data and stores id for the signal.
func setup(relic: RelicData) -> void
```

---

## Main.gd (scenes/core/Main.gd) — MODIFIED

**New constant**:
```gdscript
const _RELIC_OFFER_SCENE = preload("res://scenes/ui/relic_offer/RelicOfferScreen.tscn")
```

**New fields**:
```gdscript
var _relic_offer_layer: CanvasLayer = null
var _relic_offer_screen: RelicOfferScreen = null
```

**New connection in `_ready()`**:
```gdscript
RelicManager.relic_offer_ready.connect(_on_relic_offer_ready)
```

**New handlers**:
```gdscript
func _on_relic_offer_ready(options: Array) -> void:
    _exploration_hud.visible = false
    _relic_offer_layer = CanvasLayer.new()
    add_child(_relic_offer_layer)
    _relic_offer_screen = _RELIC_OFFER_SCENE.instantiate() as RelicOfferScreen
    _relic_offer_layer.add_child(_relic_offer_screen)
    _relic_offer_screen.setup(options)
    _relic_offer_screen.relic_picked.connect(_on_relic_picked)

func _on_relic_picked(relic_id: String) -> void:
    RelicManager.pick_relic(relic_id)
    _relic_offer_layer.queue_free()
    _relic_offer_layer = null
    _relic_offer_screen = null
    _exploration_hud.visible = true
```
