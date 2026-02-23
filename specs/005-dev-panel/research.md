# Research: Dev Panel

**Feature**: 005-dev-panel
**Date**: 2026-02-21
**Status**: Complete — no NEEDS CLARIFICATION markers in spec

---

## Decision 1: DEV_MODE Flag Location

**Question**: Where should the `DEV_MODE` constant live — Main.gd, a dedicated config script, or a project setting?

**Decision**: `const DEV_MODE: bool = true` directly in `scenes/core/Main.gd`.

**Rationale**: Main.gd is already the orchestrator that initialises game systems in `_ready()`. Adding the flag there keeps instantiation logic co-located with the flag that controls it. Only one file needs editing to toggle dev mode. A separate config script would be premature abstraction (one constant, one consumer — Principle V YAGNI threshold not met).

**Alternatives considered**:
- Dedicated `scripts/DevConfig.gd` — rejected: overkill for one bool with one consumer.
- Godot Project Settings (`ProjectSettings.get_setting`) — rejected: adds project file coupling and is not code-level.
- Autoload — rejected: no other system needs to read DEV_MODE; would create an unnecessary singleton.

---

## Decision 2: Panel Scene Structure

**Question**: What node hierarchy ensures the panel always renders above all game content?

**Decision**: `DevPanel (CanvasLayer, layer=128) → PanelContainer → VBoxContainer → Button × 4`

**Rationale**: `CanvasLayer` with a high layer value (128) renders above the game world and all regular UI regardless of the scene tree position. `PanelContainer` provides a styled background so the buttons are readable over any game content. `VBoxContainer` stacks buttons vertically with automatic sizing.

**Alternatives considered**:
- `Control` at top of tree — rejected: z-ordering issues with world content; CanvasLayer is the correct Godot primitive for HUD-level overlay.
- Individual floating buttons with no container — rejected: harder to position and style consistently.

---

## Decision 3: Signal vs Direct Call

**Question**: Should DevPanel buttons call RunManager methods directly, or emit signals that Main.gd connects to RunManager?

**Decision**: DevPanel emits signals (`start_run_pressed`, `end_run_pressed`, `cash_out_pressed`, `start_boss_pressed`). Main.gd connects them.

**Rationale**: DevPanel's responsibility is to provide UI and surface user intent — not to know about RunManager. Emitting signals keeps DevPanel decoupled from the run system (Principle I SRP). Main.gd already wires game subsystems together, so it is the natural place to connect DevPanel signals to RunManager calls. This also satisfies the spec's "buttons that emit corresponding signals" wording exactly.

**Alternatives considered**:
- Buttons call RunManager directly in DevPanel.gd — rejected: couples a UI scene to a game logic autoload; violates SRP.
- Global signal bus — rejected: overkill for a dev-only tool with a single consumer.

---

## Decision 4: Panel Placement and Size

**Question**: Where on the 1080×1920 portrait screen should the panel sit, and how large should buttons be?

**Decision**: Top-left corner. `PanelContainer` anchored to top-left with a fixed offset. Buttons sized to approximately 200×60px — large enough for touchscreen use on a mid-range device.

**Rationale**: Top-left is clear of the primary play area (centre and bottom of screen hold joystick and combat). 200×60px buttons meet the recommended 44px minimum touch target with comfortable margin.

**Alternatives considered**:
- Bottom-right corner — rejected: overlaps with joystick area.
- Draggable panel — rejected: unnecessary complexity for a dev-only tool.

---

## Decision 5: Main.gd Bug Fix (end_run argument)

**Observation**: `Main.gd` currently calls `RunManager.end_run("dead")`, but `RunManager.end_run()` was implemented with no parameters. GDScript 4 with static typing will raise a runtime error on this call.

**Decision**: Fix `Main.gd` to call `RunManager.end_run()` with no argument. The reason for run end ("dead") is not used by RunManager's current implementation.

**Rationale**: Simplest fix. RunManager does not need a reason code in this feature. If reason tracking is needed in future, it can be added then (YAGNI).

---

## Decision 6: Instantiation Pattern

**Question**: Should DevPanel.tscn be permanently in Main.tscn (hidden when DEV_MODE=false) or only instantiated at runtime?

**Decision**: Runtime instantiation via `const PANEL_SCENE = preload(...)` in Main.gd. If `DEV_MODE` is true, call `instantiate()` and `add_child()` in `_ready()`. If false, zero nodes exist.

**Rationale**: FR-009 explicitly requires zero nodes when DEV_MODE is false. A permanently-instanced hidden node violates this. Runtime instantiation guarantees no memory or node overhead in production.
