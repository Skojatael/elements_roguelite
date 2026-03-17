# Quickstart: Homing Projectile Skill (046)

## Validate the feature end-to-end

### Prerequisites
- Godot 4.6 editor open with the project loaded.
- A run is started (use DevPanel if needed).

### Test 1 — Skill button visible
1. Start a run via the TeleportDoor or DevPanel.
2. Verify the ExplorationHUD is visible and the **Skill** button appears.
3. Enter the start room (no enemies). Confirm the button is visible and tappable.

### Test 2 — No-op in empty room
1. While in the start room (or after clearing a combat room), tap the Skill button.
2. Verify no projectile appears. No errors in the output log.

### Test 3 — Projectile fires and homes
1. Enter a combat room and wait for enemies to spawn.
2. Move the player so multiple enemies are visible at different distances.
3. Tap the Skill button. Verify:
   - A small yellow rectangle spawns at the player's position.
   - It curves toward the closest enemy (not the farthest).
   - On contact with the enemy, the projectile disappears and the enemy loses HP.

### Test 4 — Correct damage (50%)
1. Note the player's attack damage (check DevPanel or StatsComponent in debugger).
2. Fire a projectile at a high-HP enemy.
3. Check that the HP reduction equals `floori(attack_damage * 0.5)`.

### Test 5 — Multiple simultaneous projectiles
1. In a room with at least 2 enemies, rapidly tap the Skill button 3 times.
2. Verify 3 separate projectiles appear, each homing toward the closest enemy at their respective fire moments.

### Test 6 — Target death mid-flight
1. Fire a projectile at an enemy, then immediately kill that enemy (move player into melee).
2. Verify the in-flight projectile disappears immediately when the target dies.

### Test 7 — Max distance self-destruct
1. Fire a projectile in a room where all enemies are killed just before it would reach them (or use a very long room travel path).
2. Alternatively: temporarily set `max_distance` to a small value in `skills.json` (e.g. 100), fire, and confirm the projectile disappears before reaching any enemy.

### Test 8 — No orphaned projectiles on room transition
1. Fire a projectile, then immediately walk through a door to the next room.
2. Verify no projectile persists in the new room. Check the scene tree has no orphaned `Projectile` nodes.

### Test 9 — Run end cleanup
1. Fire one or more projectiles, then end the run via DevPanel (or die).
2. Verify the results screen appears cleanly with no errors. No Projectile nodes remain in the scene tree.
