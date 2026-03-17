# Research: Player HP Bar

**Feature**: 047-player-hp-bar
**Date**: 2026-03-17

## Decision Log

### How to drive fill width

**Decision**: Set `_fill.size.x = _bg.size.x * ratio` directly in GDScript.

**Rationale**: The HP bar uses a fixed-size `Control` root (size set in the Editor). Both `_bg` and `_fill` are non-container `ColorRect` children. `size.x` assignment on a non-anchored-to-right rect gives pixel-accurate fill with no layout system involvement. `scale.x` was considered but shifts the rect from its pivot, causing alignment drift without extra anchor work.

**Alternatives considered**:
- `scale.x` on fill — shifts rect from pivot unless pivot is set to left edge; more error-prone.
- `custom_minimum_size` — doesn't shrink below the default; not suitable for a 0–100% fill.

---

### Signal source for HP updates

**Decision**: Connect to `StatsComponent.health_changed(new_health: float, max_health: float)` from `HPBar.setup(stats: StatsComponent)`.

**Rationale**: `health_changed` already carries both `new_health` and `max_health` as floats — exactly what the bar needs with no additional polling. Main.gd already holds `_stats: StatsComponent` as `@onready`, so it can wire the bar in `_ready()` at zero cost.

**Alternatives considered**:
- Polling `RunManager.player_state.current_hp` in `_process` — more overhead, and `player_state` doesn't expose max_health directly.
- A new GlobalSignal — unnecessary indirection; StatsComponent already owns and broadcasts this data.

---

### Where HPBar lives

**Decision**: `scenes/ui/hud/HPBar.tscn` + `HPBar.gd`, added as a child node of `ExplorationHUD.tscn`.

**Rationale**: All in-run HUD elements live in `ExplorationHUD.tscn`. Co-locating `HPBar` there keeps it self-contained and naturally hidden/shown with the HUD. No new autoload or scene tree restructuring required.

---

### Wiring path

**Decision**: Main.gd calls `_exploration_hud.setup_hp_bar(_stats)` in `_ready()` (after `@onready` vars are set).

**Rationale**: Main.gd already owns both `_stats` and `_exploration_hud` as `@onready` references. This is the same pattern used for joystick wiring (`MovementComponent.set_joystick`). No new infrastructure needed.

---

## No JSON data needed

HP bar has no tuneable balance values — fill ratio is computed purely from live health state. Constitution II (Data-Driven Content) does not apply to pure UI display components.
