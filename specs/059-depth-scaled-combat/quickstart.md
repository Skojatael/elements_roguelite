# Quickstart: Depth-Scaled Combat Validation

## Scenario 1 — Depth 1: 3 enemies, no waves

1. Start a run. Enter a combat room at depth 1 (first ring from start).
2. **Observe**: Exactly 3 enemies spawn. Wait — no additional enemies appear regardless of kills.
3. Kill all 3.
4. **Observe**: Room clears after the 3rd kill.

**Pass criteria**: 3 enemies total, 0 wave reinforcements, room clears on 3rd kill.

---

## Scenario 2 — Depth 2: 4 enemies, no waves

1. Progress to a depth-2 room.
2. **Observe**: Exactly 4 enemies spawn. No further enemies arrive.
3. Kill all 4.
4. **Observe**: Room clears on 4th kill.

**Pass criteria**: 4 enemies total, 0 wave reinforcements, room clears on 4th kill.

---

## Scenario 3 — Depth 3 or 4: 4 + 1 wave (total 6)

1. Enter a depth-3 or depth-4 combat room.
2. **Observe**: 4 enemies spawn initially.
3. Kill 2 (leaving ≤2 alive).
4. **Observe**: 2 more enemies spawn (wave 1 trigger).
5. Kill the remaining 4.
6. **Observe**: Room clears on the 6th kill. No further enemies appear.

**Pass criteria**: 4 initial + 2 wave = 6 total kills to clear.

---

## Scenario 4 — Depth 5+: 4 + 2 waves (total 7)

1. Enter a depth-5+ combat room.
2. **Observe**: 4 enemies spawn initially.
3. Kill 2 (leaving ≤2 alive).
4. **Observe**: 2 more enemies spawn (wave 1).
5. Kill 2 of those (leaving ≤2 alive).
6. **Observe**: 1 final enemy spawns (wave 2).
7. Kill all remaining.
8. **Observe**: Room clears on the 7th kill.

**Pass criteria**: 4 + 2 + 1 = 7 total kills to clear.

---

## Scenario 5 — Elite and Start rooms unaffected

1. Enter StartRoom01 — verify no enemies and doors open immediately.
2. Enter EliteRoom01 — verify it uses its normal multi-enemy flat spawn (not depth-tier waves).

**Pass criteria**: Neither room uses depth-tier wave logic.

---

## Scenario 6 — Alive cap respected

1. Enter a depth-5+ room. Kill only 1 enemy (3 alive). Trigger threshold is ≤2 — wave should NOT fire yet.
2. Kill a second (2 alive). **Observe**: Wave 1 fires (2 more spawn). Total alive = 4 = alive cap.
3. Kill 2 more. **Observe**: Wave 2 fires (1 more spawns).

**Pass criteria**: Trigger fires at ≤2 alive, alive cap of 4 is never exceeded.
