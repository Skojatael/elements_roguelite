# Implementation Plan: Dodge Skill

**Branch**: `070-dodge-skill` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)

## Summary

Implement a tap-to-dodge button on the HUD that moves the player a fixed configurable distance (default 300 units) in their last movement direction, granting full invulnerability for the duration. A 1.5-second data-driven cooldown prevents spam. `DodgeComponent.gd` exists as a stub and is the primary implementation target.

## Technical Context

**Language/Version**: GDScript 4.6, static typing
**Primary Dependencies**: Godot CharacterBody2D physics (`move_and_slide`), existing `ResourceManager.get_skills()`, `GlobalSignals`
**Storage**: `data/skills.json` — dodge entry added to existing `skills` array
**Testing**: GUT unit tests (`tests/unit/`)
**Target Platform**: Android mobile portrait; Windows dev
**Performance Goals**: 60 fps sustained; dash is a velocity override in `_physics_process` — no allocations
**Constraints**: No new autoloads; no new scenes beyond editor-side Button node addition; no Tween (velocity-based movement only)

## Constitution Check

- **I. Single Responsibility** ✅ — Dodge logic lives entirely in `DodgeComponent.gd`. `MovementComponent` gains only a `last_direction` cache (single cohesive addition). `StatsComponent` gains one guard flag. No logic in autoloads or HUD.
- **II. Data-Driven Content** ✅ — `cooldown` and `dash_distance` live in `data/skills.json`. No numeric constants in scripts.
- **III. Mobile-First** ✅ — `_physics_process` velocity override: O(1) per frame, zero allocations during dash. Jolt-compatible (`move_and_slide` is the existing movement path).
- **IV. Editor-Centric** ✅ — `DodgeComponent` exports `_movement: MovementComponent` and `_stats: StatsComponent` (assigned in Inspector). HUD `_dodge_button: Button` export assigned in Inspector. No raw `.tscn` edits.
- **V. Simplicity & YAGNI** ✅ — No dash-speed config exposed (derived as `distance / 0.1s` internally); no relic hooks for dodge yet; cooldown signal reuses HUD pattern from `SkillComponent`.
- **VI. Early Return** ✅ — `activate()` guards: `not RunManager.is_run_active`, `_cooldown_remaining > 0.0`, `_is_dashing` each get an early return.

## Decisions

1. **Dash implementation**: Velocity override in `_physics_process`. Each frame while dashing, set `parent.velocity = _dash_direction * _dash_speed` and call `move_and_slide()`, decrementing `_dash_remaining` by distance covered. When `_dash_remaining <= 0`, end dash. This integrates naturally with Jolt and wall collision (dash stops if CharacterBody2D can't move further).
2. **Dash speed**: Computed at init as `dash_distance / DASH_DURATION_SEC` where `DASH_DURATION_SEC = 0.1` is a private constant (not in JSON — YAGNI). At 300 units / 0.1s = 3000 px/s.
3. **Invulnerability**: `StatsComponent.is_invulnerable: bool` flag. `take_damage()` and `take_damage_raw()` guard with `if is_invulnerable: return` at top. Set `true` at dash start, `false` at dash end.
4. **Last direction**: `MovementComponent.last_direction: Vector2 = Vector2.DOWN`. Updated each `_physics_process` frame when `_joystick.input_vector` is non-zero. Default `Vector2.DOWN` handles the stationary case (spec FR-008).
5. **HUD wiring**: `ExplorationHUD` adds `signal dodge_button_pressed` and a `setup_dodge(dodge: DodgeComponent)` method mirroring `setup_skill`. `GlobalSignals.dodge_button_pressed` is not needed — HUD emits its own signal directly to `DodgeComponent.activate()` via Main.gd, matching the existing `boss_teleport_pressed` pattern.
6. **Cooldown HUD feedback**: `DodgeComponent` emits `signal cooldown_changed(remaining: float, total: float)` (same shape as `SkillComponent.cooldown_changed`). `ExplorationHUD` modulates `_dodge_button` using the existing `SKILL_COOLDOWN_MODULATE` / `SKILL_READY_MODULATE` constants.

## Schema Changes

`data/skills.json` — add a `"dodge"` object to the `skills` array:
- `id: "dodge"`
- `cooldown: 1.5` (seconds before button is ready again)
- `dash_distance: 300.0` (pixels traveled per activation)

No new data model class is needed — `DodgeComponent._ready()` iterates `ResourceManager.get_skills()` to find `id == "dodge"` and reads the two fields directly (same pattern as `SkillComponent`).

## Affected Files

### Modified

- **`data/skills.json`** — Add the `"dodge"` skills entry with `cooldown` and `dash_distance` fields.

- **`scenes/player/components/DodgeComponent.gd`** — Full implementation replacing the stub. Exports `_movement: MovementComponent` and `_stats: StatsComponent`. Reads config in `_ready()`. Exposes `activate() -> void` (called by Main on dodge button press) and `signal cooldown_changed(remaining: float, total: float)`. Manages `_is_dashing`, `_dash_remaining`, `_cooldown_remaining`, `_dash_direction` state. In `_physics_process`: advances cooldown timer and, when dashing, drives parent velocity at `_dash_speed` until distance is covered.

- **`scenes/player/components/MovementComponent.gd`** — Add `var last_direction: Vector2 = Vector2.DOWN`. In `_physics_process`, when `_joystick.input_vector` is non-zero, update `last_direction = _joystick.input_vector.normalized()`. DodgeComponent reads this property at activation time.

- **`scenes/player/components/StatsComponent.gd`** — Add `var is_invulnerable: bool = false`. Add early-return guard at the top of both `take_damage()` and `take_damage_raw()`: if `is_invulnerable` is true, return immediately without applying damage.

- **`scenes/ui/hud/ExplorationHUD.gd`** — Add `@export var _dodge_button: Button`. Add `signal dodge_button_pressed`. Add `setup_dodge(dodge: DodgeComponent) -> void` that connects `dodge.cooldown_changed` to a `_on_dodge_cooldown_changed` handler (mirrors `setup_skill`). Wire `_dodge_button.pressed` to emit `dodge_button_pressed`. Handle `_dodge_button.visible` in `_on_gameplay_started()`, `_on_gameplay_ended()`, and `_on_hub_entered()` to match skill button visibility rules.

- **`scenes/core/Main.gd`** — Add `@onready var _dodge_component: DodgeComponent`. Call `_exploration_hud.setup_dodge(_dodge_component)` alongside the existing `setup_skill` call. Connect `_exploration_hud.dodge_button_pressed` to `_dodge_component.activate`.

### Editor tasks (Godot Editor only)

- **`scenes/ui/hud/ExplorationHUD.tscn`** — Add a `Button` node named `DodgeButton` as a sibling of `_skill_button`; assign it to the `_dodge_button` export in the Inspector.

- **`scenes/player/Player.tscn`** — Assign `_movement` (MovementComponent node) and `_stats` (StatsComponent node) on the DodgeComponent child node via the Inspector.
