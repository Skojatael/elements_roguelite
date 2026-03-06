# Implementation Plan: Boss Rewards

**Branch**: `032-boss-rewards` | **Date**: 2026-03-05 | **Spec**: specs/032-boss-rewards/spec.md

## Summary

Two rewards on boss defeat: (1) scaled essence (`floori(80 × (1 + 0.06 × rooms_cleared))`) awarded immediately via `RunManager.add_currency()`; (2) three rare relics offered via a new `RelicManager.trigger_boss_offer()` path before the victory overlay appears. One latent bug fixed: `RelicManager._on_room_cleared()` was incorrectly processing the boss room clear, corrupting the regular relic offer counter.

## Technical Context

**Language/Version**: GDScript, Godot 4.6
**Primary Dependencies**: `RelicManagerImpl` (new `draw_boss_offer()`), `RelicManager` (new `trigger_boss_offer()`), `ResourceManager.get_enemy_base_essence()`, `RunManager.add_currency()`, existing `RelicOfferScreen`
**Storage**: `data/enemies.json` — `base_essence` 0 → 80
**Testing**: Manual (quickstart.md, 6 scenarios)
**Target Platform**: Android mobile (portrait); Windows dev
**Project Type**: Single Godot project
**Performance Goals**: All computation same-frame
**Constraints**: No new scenes; no new autoloads; no new JSON schemas
**Scale/Scope**: 1 data change, 2 script files modified, 1 new method in impl

## Constitution Check

- **I. Single Responsibility** ✅ `draw_boss_offer()` is a pure query on RelicManagerImpl; `trigger_boss_offer()` is a thin delegating method on RelicManager; `_show_boss_victory_overlay()` extracted so Main.gd callers stay small.
- **II. Data-Driven Content** ✅ Boss reward value (`base_essence: 80`) lives in enemies.json — tunable without code changes.
- **III. Mobile-First** ✅ No rendering impact; relic offer UI already exists.
- **IV. Editor-Centric** ✅ No scene changes.
- **V. Simplicity & YAGNI** ✅ `_show_boss_victory_overlay()` is extracted because two callers exist (fallback + post-pick). `_boss_relic_pending` is the minimal flag needed.
- **VI. Early Return** ✅ `draw_boss_offer()` returns early on empty tier; `_on_room_cleared()` returns early on boss_room; `_on_relic_picked()` uses `if _boss_relic_pending` branch at end.

## Project Structure

### Source Code

```text
data/
└── enemies.json                         MODIFIED — base_essence 0 → 80

scripts/managers/
└── RelicManagerImpl.gd                  MODIFIED — draw_boss_offer() added

autoload/
└── RelicManager.gd                      MODIFIED — _on_room_cleared() fix + trigger_boss_offer()

scenes/core/
└── Main.gd                              MODIFIED — _boss_relic_pending flag, rework _on_boss_room_cleared(),
                                                     modify _on_relic_picked(), extract _show_boss_victory_overlay(),
                                                     reset flag in _on_run_started()
```

No new files.

## Phase 1: Data + Bug Fix (Foundational)

### T1a — enemies.json: base_essence 0 → 80

In `data/enemies.json`, change `"base_essence": 0` to `"base_essence": 80` in the boss entry.

### T1b — RelicManager._on_room_cleared() fix

Add `if room_id == "boss_room": return` as the first guard clause in `RelicManager._on_room_cleared()`.

## Phase 2: draw_boss_offer() + trigger_boss_offer() (US2 foundation)

### T2a — RelicManagerImpl.draw_boss_offer()

```gdscript
func draw_boss_offer() -> Array[RelicData]:
	if not _all_by_tier.has("rare"):
		return []
	var available: Array[RelicData] = []
	for r: RelicData in (_all_by_tier["rare"] as Array):
		if not active_relic_ids.has(r.id):
			available.append(r)
	available.shuffle()
	return available.slice(0, mini(3, available.size()))
```

### T2b — RelicManager.trigger_boss_offer()

```gdscript
func trigger_boss_offer() -> bool:
	var options: Array[RelicData] = _impl.draw_boss_offer()
	if options.is_empty():
		print("[RelicManager] trigger_boss_offer — no rare relics available, skipping")
		return false
	print("[RelicManager] boss offer triggered — {count} rare relics".format({"count": options.size()}))
	relic_offer_ready.emit(options)
	return true
```

## Phase 3: Main.gd wiring

### T3a — Add _boss_relic_pending field

```gdscript
var _boss_relic_pending: bool = false
```

### T3b — Extract _show_boss_victory_overlay() from old _on_boss_room_cleared()

The old body of `_on_boss_room_cleared()` (creating CanvasLayer + overlay + connecting signals) becomes `_show_boss_victory_overlay()`.

### T3c — Rewrite _on_boss_room_cleared()

```gdscript
func _on_boss_room_cleared(_room_id: String) -> void:
	_boss_room_spawner = null
	var base: float = ResourceManager.get_enemy_base_essence("boss")
	var rooms_cleared: int = RunManager.cleared_rooms.size()
	var reward: int = floori(base * (1.0 + 0.06 * float(maxi(0, rooms_cleared - 6))))
	RunManager.add_currency(reward)
	print("[Main] boss reward — base={b} rooms_cleared={r} reward={w}".format({
		"b": base, "r": rooms_cleared, "w": reward,
	}))
	_exploration_hud.visible = false
	if RelicManager.trigger_boss_offer():
		_boss_relic_pending = true
	else:
		_show_boss_victory_overlay()
```

### T3d — Modify _on_relic_picked()

```gdscript
func _on_relic_picked(relic_id: String) -> void:
	RelicManager.pick_relic(relic_id)
	_relic_offer_layer.queue_free()
	_relic_offer_layer = null
	_relic_offer_screen = null
	if _boss_relic_pending:
		_boss_relic_pending = false
		_show_boss_victory_overlay()
	else:
		_exploration_hud.visible = true
```

### T3e — Reset _boss_relic_pending in _on_run_started()

Add `_boss_relic_pending = false` as first line of `_on_run_started()`.
