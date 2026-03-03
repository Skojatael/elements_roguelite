# Implementation Plan: Relic System

**Branch**: `021-relic-system` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/021-relic-system/spec.md`

## Summary

Run-scoped relic modifier system. Relics are defined in `data/relics.json`, loaded via `ResourceManager`, managed by a new `RelicManager` autoload (thin wrapper over `RelicManagerImpl`). After qualifying room clears (every 2 standard rooms, always after elite), a `RelicOfferScreen` overlay appears with 2 choices. The chosen relic is stored in `PlayerState.active_modifiers` and applied immediately to player stats via reactive signals to `CombatComponent` and `StatsComponent`. All relics are cleared on run end.

## Technical Context

**Language/Version**: GDScript 4.6, static typing throughout
**Primary Dependencies**: Godot 4.6 engine, RunManager autoload (room_cleared signal), MetaManager autoload (damage_multiplier)
**Storage**: `data/relics.json` (JSON, load-time only — relics are run-scoped, never persisted)
**Testing**: Manual validation via quickstart.md scenarios
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Project Type**: Mobile game (single project)
**Performance Goals**: 60 fps; relic stat computation is O(n) per relic pick only — not per frame
**Constraints**: Mobile renderer, Jolt physics — no new shaders or physics bodies required

## Constitution Check

### Principle I — Single Responsibility ✅

- `RelicManager` autoload: thin wrapper only — signals, state fields, delegation. ✅
- `RelicManagerImpl`: pure algorithmic logic — frequency tracking, offer drawing, stat mult computation. No I/O, no scene interaction. ✅
- `RelicData`: data model only. ✅
- `RelicOfferScreen`: UI only — displays options, emits pick signal. ✅
- `RelicCard`: single card display + button — co-located with its scene. ✅
- New autoload `RelicManager` owns exactly one domain (run-scoped relic lifecycle). Does not overlap with `RunManager` (session), `MetaManager` (meta upgrades), or `ResourceManager` (data loading). ✅

**Justified new autoload**: Relic lifecycle is a distinct domain (run-scoped modifiers) with its own state, signals, and cross-system coordination. It cannot live in RunManager (different domain) or MetaManager (per-run, not persistent). Explicit justification required by Constitution I, provided here.

### Principle II — Data-Driven Content ✅

- All relic definitions in `data/relics.json`. ✅
- `RelicData.gd` typed wrapper — no raw dict access in game logic. ✅
- `OFFER_INTERVAL = 2` is a const in `RelicManagerImpl` — acceptable as an architectural constant (not a balance value). Balance values (mult, description) are in JSON. ✅

### Principle III — Mobile-First Performance ✅

- No new shaders, physics bodies, or draw calls introduced.
- Stat computation is O(active_relics) triggered only on relic pick — not in `_process()`. ✅
- Offer screen uses standard Control nodes (Panel, Label, Button) — minimal draw cost. ✅

### Principle IV — Editor-Centric Workflow ✅

- `RelicOfferScreen.tscn` and `RelicCard.tscn` created in Godot Editor. ✅
- All child node references via `@export var` + Inspector assignment. ✅
- No hardcoded `$NodeName` paths outside architecturally fixed names. ✅

### Principle V — Simplicity & YAGNI ✅

- No relic inventory HUD (out of scope — spec confirmed).
- No per-tier weighting (out of scope).
- No relic rerolling, synergy bonuses, or persistent relics (out of scope).
- `RelicCard` is used in exactly 2 places inside `RelicOfferScreen.tscn` — justified as its own `.tscn` for visual editing.

## Project Structure

### Documentation (this feature)

```text
specs/021-relic-system/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── interfaces.md    # Phase 1 output
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code Changes

```text
data/
└── relics.json                                    [NEW] relic pool definitions

scripts/
├── data_models/
│   ├── RelicData.gd                               [NEW] typed relic data model
│   └── PlayerState.gd                             [MODIFIED] active_modifiers field
└── managers/
    ├── RelicManagerImpl.gd                        [NEW] frequency, draw, mult logic
    └── ResourceManager.gd (ResourceManagerImpl)   [MODIFIED] get_relics()

autoload/
├── RelicManager.gd                                [NEW] thin wrapper autoload
└── ResourceManager.gd                            [MODIFIED] get_relics() delegation

scenes/
├── ui/relic_offer/
│   ├── RelicOfferScreen.gd                        [NEW] offer overlay script
│   ├── RelicOfferScreen.tscn                      [NEW — EDITOR] offer overlay scene
│   ├── RelicCard.gd                               [NEW] single card script
│   └── RelicCard.tscn                             [NEW — EDITOR] single card scene
├── player/components/
│   ├── CombatComponent.gd                         [MODIFIED] relic attack_damage + speed mult
│   └── StatsComponent.gd                          [MODIFIED] relic max_health mult
└── core/
    └── Main.gd                                    [MODIFIED] offer screen lifecycle
```

## Phase 0: Foundational Data

### data/relics.json

Create `data/relics.json` with the 5-relic initial pool (see data-model.md for full JSON). Cover all 3 supported stat categories:
- `attack_damage`: `sharp_edge` (×1.2), `rage_crystal` (×1.3)
- `attack_speed`: `swift_strike` (×1.25)
- `max_health`: `iron_hide` (×1.3), `vital_core` (×1.5)

### RelicData.gd

`scripts/data_models/RelicData.gd`:
```gdscript
class_name RelicData
extends RefCounted

var id: String = ""
var name: String = ""
var tier: String = ""
var tags: Array[String] = []
var effect_stat: String = ""
var effect_mult: float = 1.0
var description: String = ""

static func from_dict(data: Dictionary) -> RelicData:
    var r := RelicData.new()
    r.id = str(data.get("id", ""))
    r.name = str(data.get("name", ""))
    r.tier = str(data.get("tier", "common"))
    for t: Variant in data.get("tags", []):
        r.tags.append(str(t))
    r.effect_stat = str(data.get("effect_stat", ""))
    r.effect_mult = float(data.get("effect_mult", 1.0))
    r.description = str(data.get("description", ""))
    return r
```

### PlayerState.gd modification

Replace:
```gdscript
var modifiers: Array = []
```
With:
```gdscript
## Relic IDs collected this run. Populated by RelicManager.pick_relic().
var active_modifiers: Array[String] = []
```

### ResourceManagerImpl modification

Add to `scripts/managers/ResourceManager.gd`:
```gdscript
var _relics_cache: Dictionary = {}
var _relics_loaded: bool = false

func get_relics() -> Dictionary:
    if _relics_loaded:
        return _relics_cache
    var file := FileAccess.open("res://data/relics.json", FileAccess.READ)
    assert(file != null, "ResourceManager: failed to open res://data/relics.json")
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    assert(parsed is Dictionary,
        "ResourceManager: relics.json root must be a Dictionary")
    _relics_cache = parsed as Dictionary
    _relics_loaded = true
    return _relics_cache
```

Add to `autoload/ResourceManager.gd`:
```gdscript
func get_relics() -> Dictionary:
    return _impl.get_relics()
```

## Phase 1: Core Logic (RelicManagerImpl + RelicManager autoload)

### RelicManagerImpl

`scripts/managers/RelicManagerImpl.gd`:
```gdscript
class_name RelicManagerImpl
extends RefCounted

const OFFER_INTERVAL: int = 2

var active_relic_ids: Array[String] = []
var standard_rooms_cleared: int = 0

func reset() -> void:
    active_relic_ids = []
    standard_rooms_cleared = 0

func should_offer_for_room(room_type_id: String) -> bool:
    if room_type_id.contains("Elite"):
        return true
    standard_rooms_cleared += 1
    if standard_rooms_cleared >= OFFER_INTERVAL:
        standard_rooms_cleared = 0
        return true
    return false

func draw_offer(relic_pool: Array[RelicData]) -> Array[RelicData]:
    if relic_pool.is_empty():
        return []
    if relic_pool.size() == 1:
        return [relic_pool[0], relic_pool[0]]
    var shuffled: Array[RelicData] = relic_pool.duplicate()
    shuffled.shuffle()
    return [shuffled[0], shuffled[1]]

func pick_relic(relic_id: String) -> void:
    active_relic_ids.append(relic_id)

func compute_stat_mult(stat: String, relic_pool: Array[RelicData]) -> float:
    var mult: float = 1.0
    var data_by_id: Dictionary = {}
    for r: RelicData in relic_pool:
        data_by_id[r.id] = r
    for relic_id: String in active_relic_ids:
        var relic: Variant = data_by_id.get(relic_id)
        if relic is RelicData and (relic as RelicData).effect_stat == stat:
            mult *= (relic as RelicData).effect_mult
    return mult
```

### RelicManager autoload

`autoload/RelicManager.gd`:
```gdscript
extends Node

signal relic_offer_ready(options: Array)
signal relic_applied(relic_id: String)
signal relics_cleared()

var active_relic_ids: Array[String]:
    get: return _impl.active_relic_ids

var _impl: RelicManagerImpl = RelicManagerImpl.new()
var _relic_pool: Array[RelicData] = []


func _ready() -> void:
    RunManager.run_started.connect(func(_m: String) -> void: _on_run_started())
    RunManager.run_ended.connect(func(_r: RunManager.EndReason) -> void: _on_run_ended())
    RunManager.room_cleared.connect(_on_room_cleared)


func _on_run_started() -> void:
    _impl.reset()
    _relic_pool = _build_pool()
    relics_cleared.emit()
    print("[RelicManager] run started — pool_size={size}".format({"size": _relic_pool.size()}))


func _on_run_ended() -> void:
    _impl.reset()
    _relic_pool = []
    relics_cleared.emit()
    print("[RelicManager] run ended — relics cleared")


func _on_room_cleared(room_id: String) -> void:
    if not RunManager.is_run_active:
        return
    var room_type: String = ""
    if RunManager.current_room != null:
        room_type = (RunManager.current_room as RoomSpawner).room_type_id
    if _impl.should_offer_for_room(room_type):
        var options: Array[RelicData] = _impl.draw_offer(_relic_pool)
        if options.is_empty():
            return
        print("[RelicManager] offer triggered — room_type={type}".format({"type": room_type}))
        relic_offer_ready.emit(options)


func pick_relic(relic_id: String) -> void:
    _impl.pick_relic(relic_id)
    RunManager.player_state.active_modifiers.append(relic_id)
    print("[RelicManager] relic picked — id={id}".format({"id": relic_id}))
    relic_applied.emit(relic_id)


func get_stat_mult(stat: String) -> float:
    return _impl.compute_stat_mult(stat, _relic_pool)


func _build_pool() -> Array[RelicData]:
    var raw: Dictionary = ResourceManager.get_relics()
    var pool: Array[RelicData] = []
    for entry: Variant in raw.get("relics", []):
        if entry is Dictionary:
            pool.append(RelicData.from_dict(entry as Dictionary))
    return pool
```

**Register in Project → Project Settings → Autoload**:
- Path: `res://autoload/RelicManager.gd`
- Name: `RelicManager`
- Order: after RunManager (depends on RunManager signals)

## Phase 2: Player Component Modifications

### CombatComponent modifications

Rename `_apply_damage_multiplier()` → `_recompute_stats()`. Cache `_base_attack_interval`. Apply attack_speed relic mult.

Key changes:
```gdscript
var _base_attack_interval: float = 0.0

func _ready() -> void:
    # ... existing assertions ...
    _base_attack_damage = attack_damage
    _base_attack_interval = attack_interval
    RunManager.run_started.connect(func(_m: String) -> void: _recompute_stats())
    RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_stats())
    RelicManager.relics_cleared.connect(func() -> void: _recompute_stats())
    # ... existing body_entered/exited connections ...

func _recompute_stats() -> void:
    attack_damage = _base_attack_damage * MetaManager.damage_multiplier \
        * RelicManager.get_stat_mult("attack_damage")
    attack_interval = _base_attack_interval / RelicManager.get_stat_mult("attack_speed")
```

### StatsComponent modifications

Cache `_base_max_health`. Connect to relic signals.

Key changes:
```gdscript
var _base_max_health: float = 0.0

func _ready() -> void:
    assert(max_health > 0.0, "StatsComponent: max_health must be greater than 0")
    _base_max_health = max_health
    current_health = max_health
    RelicManager.relic_applied.connect(_on_relic_applied)
    RelicManager.relics_cleared.connect(func() -> void: _on_relic_applied(""))

func _on_relic_applied(_relic_id: String) -> void:
    var new_max: float = _base_max_health * RelicManager.get_stat_mult("max_health")
    if is_equal_approx(new_max, max_health):
        return
    var ratio: float = current_health / max_health
    max_health = new_max
    current_health = clampf(new_max * ratio, 1.0, new_max)
    health_changed.emit(current_health, max_health)
```

## Phase 3: Offer UI

### RelicCard.gd

`scenes/ui/relic_offer/RelicCard.gd`:
```gdscript
class_name RelicCard
extends Panel

signal relic_selected(relic_id: String)

@export var _name_label: Label
@export var _desc_label: Label
@export var _button: Button

var _relic_id: String = ""


func _ready() -> void:
    assert(_name_label != null, "RelicCard: _name_label not assigned")
    assert(_desc_label != null, "RelicCard: _desc_label not assigned")
    assert(_button != null, "RelicCard: _button not assigned")
    _button.pressed.connect(_on_button_pressed)


func setup(relic: RelicData) -> void:
    _relic_id = relic.id
    _name_label.text = relic.name
    _desc_label.text = relic.description


func _on_button_pressed() -> void:
    relic_selected.emit(_relic_id)
```

### RelicOfferScreen.gd

`scenes/ui/relic_offer/RelicOfferScreen.gd`:
```gdscript
class_name RelicOfferScreen
extends Control

signal relic_picked(relic_id: String)

@export var _card_left: RelicCard
@export var _card_right: RelicCard


func _ready() -> void:
    assert(_card_left != null, "RelicOfferScreen: _card_left not assigned")
    assert(_card_right != null, "RelicOfferScreen: _card_right not assigned")


func setup(options: Array) -> void:
    if options.size() >= 1:
        _card_left.setup(options[0] as RelicData)
        _card_left.relic_selected.connect(func(id: String) -> void: relic_picked.emit(id))
    if options.size() >= 2:
        _card_right.setup(options[1] as RelicData)
        _card_right.relic_selected.connect(func(id: String) -> void: relic_picked.emit(id))
```

### RelicCard.tscn (Editor task)

Scene structure:
```
RelicCard (Panel)  ← attach RelicCard.gd
  VBoxContainer
    _name_label (Label)   ← @export, Inspector-assigned
    _desc_label (Label)   ← @export, Inspector-assigned
    _button (Button)      ← @export, Inspector-assigned, text="Choose"
```

### RelicOfferScreen.tscn (Editor task)

Scene structure:
```
RelicOfferScreen (Control, full-rect)  ← attach RelicOfferScreen.gd
  Background (ColorRect, full-rect, semi-transparent)
    mouse_filter = STOP  ← blocks touch reaching nodes below
  CenterContainer (anchored center)
    VBoxContainer
      TitleLabel (Label, text="Choose a Relic")
      HBoxContainer
        _card_left (RelicCard.tscn instance)   ← @export, Inspector-assigned
        _card_right (RelicCard.tscn instance)  ← @export, Inspector-assigned
```

**Important**: `Background` ColorRect must have `mouse_filter = STOP` (in Control properties in Inspector) to block joystick input.

### Main.gd modifications

Add preload, fields, connections, and handlers per contracts/interfaces.md.

## Phase 4: CLAUDE.md Update

Add a new section documenting the Relic System architecture under the appropriate heading in CLAUDE.md.

## Phase 5: Polish & Validation

Run all 14 manual scenarios from `quickstart.md`. Confirm each passes.

## Dependencies & Execution Order

```
Phase 0 (data + data model + PlayerState) → Parallel opportunities:
  T001: data/relics.json
  T002: RelicData.gd
  T003: PlayerState.gd (modifiers stub → active_modifiers)
  T004: ResourceManagerImpl + autoload get_relics()

Phase 1 (core logic) — requires T001, T002, T004:
  T005: RelicManagerImpl.gd
  T006: RelicManager autoload (requires T005)

Phase 2 (player components) — requires T006:
  T007: CombatComponent.gd
  T008: StatsComponent.gd

Phase 3 (offer UI) — requires T006:
  T009: RelicCard.gd
  T010: RelicOfferScreen.gd
  T011 [EDITOR]: RelicCard.tscn
  T012 [EDITOR]: RelicOfferScreen.tscn (requires T011)
  T013: Main.gd (requires T010, T012)
  T014 [EDITOR]: Register RelicManager autoload in Project Settings

Phase 4:
  T015: CLAUDE.md update

Phase 5:
  T016: Run all 14 quickstart scenarios
```

## MVP Scope (US1 only)

1. Phase 0 (all 4 tasks)
2. Phase 1 (RelicManagerImpl + RelicManager with simplified frequency: always offer on clear)
3. Phase 3 (offer UI + Main.gd)
4. Validate: clear room → offer appears → pick relic → stat applied

For full delivery, add Phase 2 (player components for stat application) and correct Phase 1 frequency logic.
