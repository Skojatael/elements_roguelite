# Research: Hub Shard Display

## Decision 1: Overlay placement

**Decision**: The shard display is a component node inside `HubRoom.tscn` — a `CanvasLayer` child
containing a `Control` with a `Label`. The component script `ShardDisplay.gd` is co-located at
`scenes/hub/ShardDisplay.gd`.

**Rationale**: Co-locating the overlay with HubRoom means it appears and disappears automatically
with the hub scene — no external management needed. When HubRoom is freed (run starts or player
exits), the overlay is freed too, satisfying US2 (hidden during runs) with zero extra wiring.
The `CanvasLayer` keeps the display screen-space, unaffected by Camera2D position.

**Alternatives considered**:
- Separate `HubOverlay.tscn` scene: YAGNI violation — the overlay is only used by HubRoom and has
  no reuse potential in this iteration. A standalone scene adds unnecessary file overhead.
- Managed by Main.gd (shown/hidden via signals): Requires Main.gd to know about shard display,
  coupling main scene orchestration to meta-progression UI. Violates SRP.
- Adding display logic to HubRoom.gd: Mixes hub lifecycle concerns with UI display. SRP violation.

---

## Decision 2: Script attachment point

**Decision**: `ShardDisplay.gd` is attached to a `Control` node that is a child of the `CanvasLayer`
inside `HubRoom.tscn`. It exports `@export var _label: Label` (assigned in Inspector).
In `_ready()` it reads `MetaManager.meta_state.total_shards` and writes the formatted string to
the label.

**Rationale**: Attaching to a `Control` (not directly to the `CanvasLayer` or `Label`) follows the
project convention of using `Control` nodes as the root of UI components. The `@export var _label`
satisfies Constitution Principle IV (no hardcoded `$NodeName` for configurable children).

**Alternatives considered**:
- Script extending `Label` directly: Works but limits future layout flexibility (can't easily add
  an icon or second label alongside without restructuring).
- `ShardDisplay.gd` extending `CanvasLayer`: Non-standard; Control nodes should manage UI logic.

---

## Decision 3: Data read timing

**Decision**: Read `MetaManager.meta_state.total_shards` once in `_ready()`. No subscription to
changes.

**Rationale**: Shards only change at run end, which happens before the hub is instantiated.
By the time HubRoom._ready() fires, MetaManager already has the correct persisted total.
A reactive subscription would be premature complexity (Constitution Principle V — YAGNI).

**Alternatives considered**:
- Subscribe to a `shards_changed` signal from MetaManager: No such signal exists and none is needed
  since the hub is always recreated fresh after each run. Adding the signal would be speculative
  infrastructure.
