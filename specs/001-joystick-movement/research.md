# Research: Player Movement Joystick Controls

**Branch**: `001-joystick-movement` | **Date**: 2026-02-19
**Phase**: 0 — Outline & Research

---

## Finding 1: Touch Input API

**Decision**: Use `_gui_input(event: InputEvent)` on the Joystick `Control` node.

**Rationale**:
- `_gui_input` only fires for events within the Control's rect, so input outside
  the joystick area is automatically ignored — no manual hit-testing needed.
- `InputEventScreenTouch` (finger down/up) and `InputEventScreenDrag` (finger
  move) are the correct event types for virtual joystick logic.
- Calling `accept_event()` inside `_gui_input` prevents the touch from falling
  through to the game world (e.g., triggering an attack on tap).

**Alternatives considered**:
- `_input(event)` (global): rejected — does not scope to the joystick rect;
  requires manual boundary checks and is harder to silence for downstream nodes.
- `InputMap` / action remapping: rejected — designed for discrete actions, not
  continuous analog touch drag values.

---

## Finding 2: MovementComponent Integration Pattern

**Decision**: Joystick exposes a `var input_vector: Vector2` property. A
coordinator (Main.gd or the active game scene) holds references to both the
Joystick node and MovementComponent and passes the joystick reference into
MovementComponent via a `set_joystick(node: Node)` method. MovementComponent
polls `joystick.input_vector` each `_physics_process` frame.

**Rationale**:
- Polling continuous directional data each physics frame is idiomatic Godot;
  signals are better suited to discrete events.
- The coordinator pattern keeps JoystickControl unaware of MovementComponent
  and vice versa — both have one responsibility (SRP).
- Avoids adding a new domain to the `GlobalSignals` autoload for per-frame data.
- The coordinator (game scene / Main.gd) is the appropriate owner of cross-tree
  wiring; it already knows about both the HUD (containing the joystick) and the
  Player (containing MovementComponent).

**Alternatives considered**:
- `GlobalSignals.joystick_changed.emit(vector)` each frame: rejected — signals
  carry overhead and are semantically incorrect for continuous per-frame data.
- `@export var joystick: NodePath` on MovementComponent set in the editor:
  rejected — the Joystick lives in ExplorationHUD (CanvasLayer), a sibling
  subtree to Player; cross-tree NodePath exports set inside Player.tscn cannot
  reference nodes outside the Player scene without the parent scene open,
  making it fragile.

---

## Finding 3: Scene Placement

**Decision**: Joystick stays in `scenes/ui/hud/` (already scaffolded there).
ExplorationHUD.tscn instantiates Joystick.tscn as a child Control node.

**Rationale**:
- The joystick is a UI element — it belongs in the HUD layer, not in the game
  world or inside the Player scene.
- `CanvasLayer` (ExplorationHUD) renders on top of the 2D world automatically,
  which is the correct draw order for touch controls.
- Follows the existing folder conventions from CLAUDE.md.

**Alternatives considered**:
- Joystick as a child of Player.tscn: rejected — couples UI to a game entity;
  violates SRP (player scene would own both gameplay and UI logic).
- Joystick as a standalone CanvasLayer: rejected — HUD already owns all overlay
  UI (SkillButton, DodgeButton are also in hud/); consolidating in one HUD
  scene is simpler.

---

## Finding 4: Dead Zone Implementation

**Decision**: Radial dead zone — if `knob_offset.length() < dead_zone_radius`
then `input_vector = Vector2.ZERO`.

**Rationale**:
- A circular joystick produces circular drag offsets; a radial dead zone matches
  the natural geometry and eliminates the cross-shaped artifact of per-axis dead
  zones.
- Simple to implement: one length comparison.

**Alternatives considered**:
- Per-axis dead zone (abs(x) < threshold AND abs(y) < threshold): rejected —
  produces a cross-shaped dead zone that feels unnatural for analog sticks.

---

## Finding 5: Visual Node Structure

**Decision**: Joystick.tscn uses `TextureRect` child nodes for base and knob
visuals (placeholders). Art assets are swapped in without touching GDScript.

**Rationale**:
- Separating visuals (scene nodes) from logic (GDScript) lets an artist update
  artwork without modifying code — consistent with the Data-Driven and SRP
  principles.
- `TextureRect` is the standard Godot 4 node for static image display inside a
  `Control` hierarchy.

**Alternatives considered**:
- Drawing circles via `_draw()` override: deferred — works well as a first
  placeholder during development but requires a script change to swap in art.
  Can be adopted later if TextureRect overhead is measurable.

---

## Finding 6: Existing Codebase State

All relevant scenes and scripts are empty scaffolding:
- `Joystick.tscn`: bare `Control` node — needs full build-out.
- `ExplorationHUD.tscn`: bare `CanvasLayer` — needs Joystick added.
- `Player.tscn`: bare `Node2D` — needs MovementComponent added.
- `MovementComponent.gd`: `_ready()` and `_process()` stubs only.
- `GlobalSignals.gd`: empty stubs — no signals declared yet.
- `Main.tscn`: bare `Node2D` — needs Player and ExplorationHUD added,
  plus wiring logic.

No pre-existing joystick logic or movement code to preserve or migrate.

---

## Summary of Resolved Unknowns

| Unknown | Resolution |
|---------|------------|
| Touch input API | `_gui_input` with `InputEventScreenTouch` / `InputEventScreenDrag` |
| Integration pattern | Property poll via coordinator reference |
| Scene placement | `scenes/ui/hud/Joystick.tscn` → child of ExplorationHUD |
| Dead zone shape | Radial (length comparison) |
| Visual nodes | `TextureRect` placeholder nodes |
| Codebase state | Fully greenfield; no migration needed |
