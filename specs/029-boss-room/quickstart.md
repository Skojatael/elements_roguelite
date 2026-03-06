# Quickstart: Boss Room

**Feature**: [spec.md](spec.md)
**Date**: 2026-03-05

Manual test scenarios to validate the implementation. Run after all code tasks are complete and ExplorationHUD.tscn has been updated in the editor.

---

## Scenario 1 — Boss spawns with base HP when 0 rooms cleared

**Setup**: DevPanel bypass — enter boss room directly without clearing any rooms.

**Steps**:
1. Launch game.
2. In DevPanel: press "Start Run".
3. In DevPanel: find or add a "Teleport to Boss" trigger that bypasses the threshold guard (or temporarily set `rooms_required = 0` in enemies.json).
4. Confirm boss room loads.

**Expected**: One enemy spawns. Inspect via Godot debugger: `StatsComponent.max_health` ≈ 40.0 (base, no scaling).

**Acceptance**: SC-002 — `40 × (1 + 0.06 × 0) = 40.0`.

---

## Scenario 2 — Boss HP scales correctly after 6 rooms cleared

**Setup**: Full run, clear exactly 6 rooms then press "Teleport to Boss".

**Steps**:
1. Launch game, start run via TeleportDoor.
2. Clear 5 combat rooms (walk through dungeon, defeat all enemies).
3. Clear the 6th room. Confirm "Teleport to Boss" button appears.
4. Press "Teleport to Boss".
5. Enter the boss room (walk into EntryArea).
6. Inspect enemy HP: in Godot Debugger, select the Boss enemy node → StatsComponent → max_health.

**Expected**: `max_health ≈ 54.4` (= 40 × 1.36). One enemy in the room.

**Acceptance**: SC-001 (exactly 1 enemy), SC-002 (HP formula).

---

## Scenario 3 — "Teleport to Boss" button hidden below threshold, visible at threshold

**Setup**: Standard run.

**Steps**:
1. Start run. Confirm "Teleport to Boss" button is NOT visible.
2. Clear rooms 1 through 5. After each clear, confirm button is still hidden.
3. Clear room 6. Confirm button becomes visible immediately (no extra action required).
4. Press button. Confirm player is transported to boss room.

**Expected**: Button hidden for clears 1–5. Button visible immediately after clear 6. Teleport works.

**Acceptance**: SC-003, FR-005, FR-006.

---

## Scenario 4 — Camera correctly shows boss room on teleport

**Setup**: Standard run, clear 6 rooms.

**Steps**:
1. Start run, navigate to a room far from hub (e.g., depth 3–4).
2. Clear 6 rooms total. Press "Teleport to Boss".
3. Observe camera position immediately after teleport.

**Expected**: Camera snaps to boss room area (north of hub, not the last dungeon room). Player is visible in the boss room.

**Acceptance**: FR-008.

---

## Scenario 5 — Boss room not reachable via dungeon doors

**Setup**: Standard run.

**Steps**:
1. Start run. Explore dungeon via doors.
2. Confirm no door leads to the boss room (no door labeled or pointed to boss room).

**Expected**: Boss room does not appear in the dungeon door graph. Only the "Teleport to Boss" button provides access.

**Acceptance**: FR-004.

---

## Scenario 6 — Boss room cleared normally; run continues

**Setup**: Standard run, teleport to boss.

**Steps**:
1. Clear 6 rooms. Teleport to boss.
2. Defeat the boss.
3. Confirm results screen appears (or run continues to cash-out option, consistent with other combat rooms).

**Expected**: Boss defeat triggers `room_cleared("boss_room")`. Run-end flow proceeds normally (results screen on run end or cash-out option).

**Acceptance**: FR-010.

---

## Scenario 7 — Changing boss stats in data produces correct behavior

**Setup**: Temporarily edit enemies.json.

**Steps**:
1. Change boss `max_health` to 20.0 and `rooms_required` to 3 in enemies.json.
2. Restart game. Start run. Clear 2 rooms — confirm button still hidden.
3. Clear 3rd room — confirm button appears.
4. Teleport, enter boss room. Verify HP ≈ 20 × (1 + 0.06 × 3) = 23.6.
5. Restore original values.

**Expected**: All behavior matches new data values without any code change.

**Acceptance**: SC-004, FR-003.
