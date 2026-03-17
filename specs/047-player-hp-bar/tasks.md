# Tasks: Player HP Bar

**Input**: Design documents from `specs/047-player-hp-bar/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅

**Tests**: No GUT unit tests required — HPBar is a UI scene component with no static methods and no `*Impl.gd` counterpart. Manual playtest covers all acceptance criteria.

**Organization**: Tasks grouped by user story. US1 (bar fill) and US2 (label) share the same HPBar scene and script but are implemented in distinct steps.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the HPBar scene skeleton in the Godot Editor before any scripting begins.

- [ ] T001 Create `scenes/ui/hud/HPBar.tscn` in the Godot Editor: root node `Control` (rename to `HPBar`), add three children — `Background` (`ColorRect`, full bar size, dark colour), `Fill` (`ColorRect`, same initial size, green/accent colour), `Label` (anchored to full rect, centred, white text). Attach `HPBar.gd` to the root.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Write HPBar.gd — the script that drives both the fill width (US1) and the label text (US2). Must exist before ExplorationHUD or Main.gd can reference it.

**⚠️ CRITICAL**: T003–T006 cannot proceed until T002 is complete.

- [x] T002 Write `scenes/ui/hud/HPBar.gd`: `class_name HPBar extends Control`. Exports: `@export var _bg: ColorRect`, `@export var _fill: ColorRect`, `@export var _label: Label`. Public method `setup(stats: StatsComponent) -> void` — connects `stats.health_changed` and calls `_on_health_changed(stats.current_health, stats.max_health)` to initialise display. Private `_on_health_changed(new_health: float, max_hp: float) -> void` — guard `if max_hp <= 0.0: return`; compute `ratio = clampf(new_health / max_hp, 0.0, 1.0)`; set `_fill.size.x = _bg.size.x * ratio`; set `_label.text = "{cur} / {max}".format({"cur": floori(new_health), "max": floori(max_hp)})`.

**Checkpoint**: HPBar script compiled, exports declared — scene wiring can now proceed.

---

## Phase 3: User Story 1 — See Health at a Glance (Priority: P1) 🎯 MVP

**Goal**: HP bar visible in ExplorationHUD during a run, fill width reflecting player HP.

**Independent Test**: Start a run, enter a combat room, take damage. The bar rectangle visibly shortens each hit. At full HP the bar fills the background entirely; at low HP a small segment remains.

- [ ] T003 [US1] In the Godot Editor, open `scenes/ui/hud/ExplorationHUD.tscn`. Add an `HPBar` instance as a child of `ExplorationHUD`. Position at the top of the HUD (e.g., anchor top-left, size ~600×40 px). Assign the `_hp_bar` export on `ExplorationHUD` to this instance. In the HPBar Inspector, assign `_bg`, `_fill`, and `_label` exports to their respective child nodes.

- [x] T004 [US1] Update `scenes/ui/hud/ExplorationHUD.gd`: add `@export var _hp_bar: HPBar` and method `func setup_hp_bar(stats: StatsComponent) -> void: _hp_bar.setup(stats)`.

- [x] T005 [US1] Update `scenes/core/Main.gd` `_ready()`: after existing `@onready` wiring, add `_exploration_hud.setup_hp_bar(_stats)`.

**Checkpoint**: Run the game → enter run → HP bar fills proportionally. User Story 1 fully testable.

---

## Phase 4: User Story 2 — Read Exact HP Values (Priority: P2)

**Goal**: Label overlay on the bar shows `current / max` in integers, updating on every health change.

**Independent Test**: Read the label text while at partial HP. It must match `"floori(current_hp) / floori(max_hp)"`. Equip a relic that boosts max health — both denominator and bar ratio must update.

- [ ] T006 [US2] In the Godot Editor, open `scenes/ui/hud/HPBar.tscn`. Set the `Label` node's horizontal and vertical alignment to `Center`. Confirm the Label's anchor covers the full HPBar rect (anchors: top=0, left=0, bottom=1, right=1) so text overlays the bar. Set a readable font size for 1080×1920. No script changes needed — label text is driven by `_on_health_changed` (T002).

**Checkpoint**: Label text reads correct integers at 0%, ~50%, and 100% HP. Relic-driven max health change updates both label and fill.

---

## Phase 5: Polish & Validation

**Purpose**: End-to-end manual validation covering all spec acceptance criteria and edge cases.

- [ ] T007 Manual playtest in `scenes/core/Main.tscn`: verify all six acceptance scenarios from spec.md — (1) bar visible during run, (2) fill shrinks on damage, (3) full bar at full HP, (4) non-zero fill at 1 HP, (5) label reads "X / Y" at partial health, (6) relic max-health change updates both bar and label without scene reload.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 (HPBar.tscn must exist for `class_name HPBar` to resolve).
- **Phase 3 (US1)**: Depends on Phase 2 — HPBar.gd must compile before ExplorationHUD or Main reference it.
- **Phase 4 (US2)**: Depends on Phase 3 (HPBar must be in scene tree for label Inspector config to matter).
- **Phase 5 (Polish)**: Depends on Phases 3 and 4 complete.

### User Story Dependencies

- **US1 (P1)**: Requires Phase 1 + Phase 2 complete. No dependency on US2.
- **US2 (P2)**: Shares the same HPBar scene. Logically independent but practically built in T002 — Phase 4 only adds Inspector configuration.

### Parallel Opportunities

No meaningful parallelism — all 7 tasks form a strict linear chain for a single developer.

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. T001 → T002 → T003 → T004 → T005
2. **STOP and VALIDATE**: bar fill works in-game
3. Continue to T006 for label config

### Incremental Delivery

1. T001–T002: Scene + script ready
2. T003–T005: Bar wired and visible (US1 done)
3. T006: Label properly displayed (US2 done)
4. T007: Full validation

---

## Notes

- T001 and T003 are Editor tasks (Godot Inspector) — cannot be scripted.
- `_fill.size.x` is manipulated directly; ensure `Fill` ColorRect is NOT inside a Container node that would override its size.
- The `Label` must be a plain `Label`, not a `RichTextLabel` — no BBCode needed.
- If `ExplorationHUD` is a `CanvasLayer`, HPBar inherits screen-space rendering automatically — no extra CanvasLayer required.
