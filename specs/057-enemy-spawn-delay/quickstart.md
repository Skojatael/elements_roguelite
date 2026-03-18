# Quickstart: Enemy Spawn Delay Validation

## Scenario 1 — Delay prevents immediate engagement

1. Open CombatRoom01 in a run.
2. Stand at room center and enter the room trigger.
3. **Observe**: 3 enemies spawn. For ~1–2 seconds they are stationary with no velocity.
4. **Observe**: Player takes no contact damage during that window even if an enemy appears adjacent.
5. After the delay, enemies begin pursuing normally.

**Pass criteria**: No movement and no damage received for exactly 1.0 second post-spawn.

---

## Scenario 2 — Wave 2 enemies also delay individually

1. In CombatRoom01, kill 2 of the 3 wave-1 enemies (leaving 1 alive — triggers wave 2).
2. **Observe**: 2 new enemies appear. Each is stationary for ~1–2 seconds before pursuing.
3. The surviving wave-1 enemy is unaffected (its delay expired long ago).

**Pass criteria**: Only the freshly spawned wave-2 enemies are frozen; existing living enemies continue pursuing.

---

## Scenario 3 — Enemy can be killed during delay

1. Spawn any room. During the delay window, fire a projectile at a stationary enemy.
2. **Observe**: Enemy takes damage normally and dies if health reaches zero.
3. No errors in the Godot output panel.

**Pass criteria**: Damage and death work correctly during the delay period.

---

## Scenario 4 — Delay expires correctly

1. Spawn a room, do nothing for 2 seconds.
2. **Observe**: All enemies begin pursuing once their individual delays expire (staggered by up to 1 s due to random range).

**Pass criteria**: Every enemy is actively pursuing within 1.5 seconds of room entry (1.0 s delay + reaction time).
