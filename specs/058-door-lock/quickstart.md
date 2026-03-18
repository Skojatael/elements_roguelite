# Quickstart: Door Lock Validation

## Scenario 1 — Doors lock on enemy spawn

1. Start a run. Enter CombatRoom01.
2. Immediately walk toward any door before killing enemies.
3. **Observe**: Walking into the door zone does nothing — no room transition fires.

**Pass criteria**: No room transition on door contact while enemies are alive.

---

## Scenario 2 — Doors unlock on room clear

1. Enter CombatRoom01. Verify doors are locked (Scenario 1).
2. Kill all 6 enemies across all three waves.
3. Walk toward a door.
4. **Observe**: Room transition fires normally — next room loads.

**Pass criteria**: Door transition works immediately after the 6th kill.

---

## Scenario 3 — StartRoom01 doors are never locked

1. Start a run. Stand in StartRoom01 (first room, no enemies).
2. Walk toward any door immediately.
3. **Observe**: Room transition fires normally — no locking occurs.

**Pass criteria**: Doors in rooms with no enemies are always passable.

---

## Scenario 4 — Already-cleared room stays unlocked on re-entry

1. Clear a combat room. Move to the next room. Return through the door to the cleared room.
2. Walk toward any door in the cleared room.
3. **Observe**: Doors are passable — no re-locking occurs.

**Pass criteria**: Cleared rooms never lock doors on re-entry.

---

## Scenario 5 — Wave system keeps doors locked across all waves

1. Enter CombatRoom01 (wave room: 3→2→1 enemies).
2. Kill 2 of wave 1 (wave 2 triggers). Attempt a door immediately after wave 2 spawns.
3. **Observe**: Door still locked — room not yet cleared.
4. Kill all remaining enemies through all three waves (6 total).
5. **Observe**: Door unlocks after the 6th kill.

**Pass criteria**: Doors locked for entire wave sequence; unlock only on final kill.
