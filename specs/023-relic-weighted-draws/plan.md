# Implementation Plan: Relic Weighted Draws

**Branch**: `023-relic-weighted-draws` | **Date**: 2026-03-03 | **Spec**: [spec.md](spec.md)

## Summary

Replace the flat `relic_pool` shuffle in `RelicManagerImpl` with per-tier decks drawn by weighted tier selection. Tier weights are stored in `meta_config.json`. Each tier has its own shuffled deck that reshuffles automatically on exhaustion. Two independent draws produce the offer pair.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing
**Primary Dependencies**: RelicManagerImpl, ResourceManager (existing)
**Storage**: `data/meta_config.json` (existing), `data/relics.json` (existing)
**Testing**: Manual — see quickstart.md
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: N/A (3-tier weighted draw is trivial)
**Constraints**: No new files; no new autoloads; no scene changes
**Scale/Scope**: 3 files modified (RelicManagerImpl.gd, meta_config.json, relics.json) + 1 autoload call site

## Constitution Check

- **I. Single Responsibility**: All deck + weight logic stays in `RelicManagerImpl`. RelicManager autoload only updates the `build_pool` call. ✅
- **II. Data-Driven Content**: Weights in `meta_config.json`; relics in `relics.json`. ✅
- **III. Mobile-First**: Array pop_back() is O(1); 3-tier weight scan is negligible. ✅
- **IV. Editor-Centric**: No scene changes. ✅
- **V. YAGNI**: Minimal change surface. ✅

## Project Structure

```text
specs/023-relic-weighted-draws/
├── plan.md
├── research.md
├── data-model.md
├── contracts/interfaces.md
├── quickstart.md
└── tasks.md             ← /speckit.tasks output

Source changes:
data/meta_config.json                              [MODIFIED] add relic_tier_weights
data/relics.json                                   [MODIFIED] add uncommon tier
scripts/managers/RelicManagerImpl.gd               [MODIFIED] per-tier decks + weighted draw
autoload/RelicManager.gd                           [MODIFIED] pass config_raw to build_pool
```

## Implementation

### meta_config.json

```json
"relic_tier_weights": {
    "common":   0.6,
    "uncommon": 0.3,
    "rare":     0.1
}
```

### relics.json — add uncommon section

```json
"uncommon": {
    "<id>": {
        "name": "...",
        "tags": [...],
        "effect_stat": "...",
        "effect_mult": ...,
        "description": "..."
    }
}
```

### RelicManagerImpl.gd — full rewrite of state + methods

```gdscript
class_name RelicManagerImpl
extends RefCounted

const OFFER_INTERVAL: int = 2

var active_relic_ids: Array[String] = []
var standard_rooms_cleared: int = 0
var _relics_by_id: Dictionary = {}
var _all_by_tier: Dictionary = {}
var _decks: Dictionary = {}
var _tier_weights: Dictionary = {}


func reset() -> void:
    active_relic_ids = []
    standard_rooms_cleared = 0
    _relics_by_id = {}
    _all_by_tier = {}
    _decks = {}
    _tier_weights = {}


func build_pool(relics_raw: Dictionary, config_raw: Dictionary) -> void:
    _relics_by_id = {}
    _all_by_tier = {}
    for tier: Variant in relics_raw.get("relics", {}).keys():
        var tier_str: String = str(tier)
        _all_by_tier[tier_str] = []
        for relic_id: Variant in relics_raw["relics"][tier].keys():
            var entry: Dictionary = relics_raw["relics"][tier][relic_id].duplicate()
            entry["id"] = str(relic_id)
            entry["tier"] = tier_str
            var r: RelicData = RelicData.from_dict(entry)
            _relics_by_id[r.id] = r
            (_all_by_tier[tier_str] as Array).append(r)
    # build weights — only tiers with relics, normalised
    var raw_weights: Dictionary = config_raw.get("relic_tier_weights", {})
    var weight_sum: float = 0.0
    for tier: Variant in _all_by_tier.keys():
        if raw_weights.has(tier):
            weight_sum += float(raw_weights[tier])
    for tier: Variant in _all_by_tier.keys():
        var w: float = float(raw_weights.get(tier, 0.0))
        _tier_weights[str(tier)] = w / weight_sum if weight_sum > 0.0 else 1.0 / _all_by_tier.size()
    # initialise decks
    _decks = {}
    for tier: Variant in _all_by_tier.keys():
        var deck: Array[RelicData] = (_all_by_tier[str(tier)] as Array[RelicData]).duplicate()
        deck.shuffle()
        _decks[str(tier)] = deck
    print("[RelicManager] pool built — relics={count} tiers={tiers}".format({
        "count": _relics_by_id.size(),
        "tiers": _all_by_tier.keys(),
    }))


func _draw_one() -> RelicData:
    var roll: float = randf()
    var cumulative: float = 0.0
    var selected_tier: String = ""
    for tier: Variant in _tier_weights.keys():
        cumulative += float(_tier_weights[tier])
        if roll < cumulative:
            selected_tier = str(tier)
            break
    if selected_tier.is_empty():
        selected_tier = str((_tier_weights.keys() as Array).back())
    if (_decks[selected_tier] as Array).is_empty():
        var refill: Array[RelicData] = (_all_by_tier[selected_tier] as Array[RelicData]).duplicate()
        refill.shuffle()
        _decks[selected_tier] = refill
        print("[RelicManager] deck reshuffled — tier={tier}".format({"tier": selected_tier}))
    return (_decks[selected_tier] as Array[RelicData]).pop_back()


func draw_offer() -> Array[RelicData]:
    if _relics_by_id.is_empty():
        return []
    if _relics_by_id.size() == 1:
        var single: RelicData = (_relics_by_id.values() as Array)[0]
        return [single, single]
    return [_draw_one(), _draw_one()]


func pick_relic(relic_id: String) -> void:
    active_relic_ids.append(relic_id)


func compute_stat_mult(stat: String) -> float:
    var mult: float = 1.0
    for relic_id: String in active_relic_ids:
        var relic: Variant = _relics_by_id.get(relic_id)
        if relic is RelicData and (relic as RelicData).effect_stat == stat:
            mult *= (relic as RelicData).effect_mult
    return mult


func should_offer_for_room(room_type_id: String) -> bool:
    if room_type_id.contains("Elite"):
        return true
    standard_rooms_cleared += 1
    if standard_rooms_cleared >= OFFER_INTERVAL:
        standard_rooms_cleared = 0
        return true
    return false
```

### RelicManager autoload — _on_run_started()

```gdscript
func _on_run_started() -> void:
    _impl.reset()
    _impl.build_pool(ResourceManager.get_relics(), ResourceManager.get_meta_config())
    relics_cleared.emit()
```
