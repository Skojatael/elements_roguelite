# Research: Dungeon Expansion (033)

---

## Decision 1: Grid Size

**Decision**: Change `GRID_SIZE` from `5` to `13`, `CENTER` from `Vector2i(2,2)` to `Vector2i(6,6)`.

**Rationale**:

The expansion algorithm places 4 rooms from Room A (deepest base room) using strict depth > Room A's depth constraint. To guarantee 4 rooms always fit, the grid must have enough free cells reachable (via chaining) from Room A at strictly greater depth.

With 9 base rooms (8 steps from center), the theoretical maximum depth of Room A is 8 (all rooms in a straight line). Expansion cells must have depth > 8.

**Why 11×11 is insufficient for 9 base rooms**:

In an 11×11 grid (center 5,5), depth-8 positions on the grid boundary include (0,2) and (0,8):

Worst-case trace — Room A at (0,2) [depth |0−5|+|2−5|=8]:
- Outward neighbors (depth > 8): only (0,1) at depth 9. One start.
- (0,1) → (0,0) at depth 10. frontier = [(0,0)]
- (0,0) → (1,0) at depth 9. frontier = [(1,0)]
- (1,0) → neighbors: (2,0) depth 8 pruned, (1,1) depth 8 pruned, OOB. **frontier empty.**

Result: 3 expansion rooms placed, 1 short. 11×11 **fails** for 9 base rooms.

**Analysis of 13×13 grid (cells 0–12, center 6,6)**:

Depth-8 boundary positions in 13×13: (0,4), (0,8), (4,0), (8,0), (12,4), (12,8), (4,12), (8,12) — all symmetrically equivalent.

Worst-case trace — Room A at (0,4) [depth |0−6|+|4−6|=8]:
- Outward neighbor: only (0,3) at depth 9.
- (0,3) → (0,2) at depth 10. frontier = [(0,2)]
- (0,2) → (1,2) at depth 9, (0,1) at depth 11. frontier = [(1,2), (0,1)]
- Pick any — frontier non-empty. **4th room placed.** ✓

| Room A position | Room A depth | Expansion chain result | Count |
|---|---|---|---|
| (0, 4) | 8 | (0,3)→(0,2)→{(1,2),(0,1)}→4th | 4 ✓ |
| (4, 0) | 8 | symmetric | 4 ✓ |
| (0, 8) | 8 | symmetric | 4 ✓ |
| (8, 0) | 8 | symmetric | 4 ✓ |

All reachable depth-8 boundary positions confirmed to have ≥4 valid expansion cells via chaining.

**Proof that base rooms cannot block expansion cells**: Each grid step changes Manhattan depth by ±1. In 8 steps (9 rooms), max reachable depth = 8. Expansion cells are at depth ≥ 9. Base rooms can NEVER occupy depth-9+ cells — they are unreachable in 8 steps. The guarantee holds unconditionally.

**Alternatives considered**:
- **11×11** (center 5,5): Sufficient for 8 base rooms (max depth 7), but fails for 9 base rooms (max depth 8) — worst-case Room A at (0,2) yields only 3 expansion cells. Rejected.
- **Dynamic grid growth**: Resize at expansion time. More complex, breaks room ID consistency. Rejected (YAGNI).
- **Relaxed depth constraint**: Allow expansion rooms at same depth as Room A. Violates spec FR-009. Rejected.

---

## Decision 2: Expansion Algorithm Design

**Decision**: Reuse `_record_room()` for expansion rooms, with a post-add frontier prune that keeps only cells at depth > Room A's depth.

**Rationale**: `_record_room()` already handles depth calculation, world_pos, occupied tracking, and frontier growth. Adding a prune step after each expansion room ensures the frontier never regresses toward the center (satisfying FR-009) without requiring a separate code path.

**Alternative considered**: A fully separate `_record_expansion_room()` that only adds deeper neighbors to the frontier. Rejected — `_record_room()` already adds all valid unoccupied neighbors; pruning afterward is simpler.

---

## Decision 3: Elite Promotion After Expansion

**Decision**: Move the single `_promote_elite_rooms()` call to AFTER expansion (when gear is owned), so it runs once over all 13 rooms rather than once over the base 9.

**Rationale**: Running promotion once at the end means expansion rooms at depth 8, 10, etc. are eligible for elite slots (depth step 2, 4, 6, 8…) alongside base rooms. Running it twice — once before and once after — would be wrong because the second call would randomly re-assign already-set elite rooms in the base layout.

---

## Decision 4: AdventuringGearShop UI Component

**Decision**: New `scenes/hub/AdventuringGearShop.gd` + `AdventuringGearShop.tscn` (Control root, single Button child). Visibility managed in `_update_visibility()`. Button never disabled — `purchase_adventuring_gear()` is a silent no-op when insufficient shards.

**Rationale**: Mirrors the existing `UpgradeShop.gd` pattern exactly, but with the distinction that the button is never disabled (per spec FR-004). Two separate scripts are cleaner than one parameterized component (only one caller for each, YAGNI).

---

## Decision 5: Boss Kill Detection in MetaManager

**Decision**: Detect boss kill in `MetaManager._on_room_cleared()` by checking `room_id == "boss_room"` — the same signal already connected for elite detection.

**Rationale**: `RunManager.room_cleared` already fires with `"boss_room"` when the boss dies (wired via `_on_boss_room_cleared()` in `Main.gd` → `RoomSpawner.room_cleared`). `MetaManager` already listens to this signal for elite detection. Adding a boss_room guard at the top of `_on_room_cleared()` follows the same early-return pattern as the RelicManager fix in feature 032.
