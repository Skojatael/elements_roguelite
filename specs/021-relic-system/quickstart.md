# Quickstart: Relic System Manual Validation

**Feature**: 021-relic-system
**Date**: 2026-03-02

Run these scenarios manually in the Godot Editor (Play Scene or F5). All scenarios assume a fresh run started via the TeleportDoor or DevPanel.

---

## Setup Before Testing

- Open `Main.tscn` and Play (F5).
- Start a run (TeleportDoor or DevPanel "Start Run").
- Note the player's starting **attack_damage** (from CombatComponent Inspector), **attack_interval**, and **max_health** (from StatsComponent Inspector).
- Use DevPanel or Output panel to confirm values.

---

## Scenario 1 — No offer after first standard room clear

**Steps**:
1. Enter CombatRoom01. Kill all enemies.
2. Observe: no offer screen appears.

**Expected**: The offer screen does NOT appear. Player can move freely.

---

## Scenario 2 — Offer appears after second standard room clear

**Steps**:
1. Clear room 1 (no offer).
2. Enter and clear room 2.
3. Observe: offer screen appears with 2 distinct relics showing name and description.

**Expected**: Offer screen appears. Two different relics are shown.

---

## Scenario 3 — Player must pick one relic (no skip)

**Steps**:
1. When offer screen is shown, attempt to close it without picking (no close/dismiss button should exist).
2. Tap one of the two relic cards.

**Expected**: No dismiss option exists. After tapping a card, the screen closes. Player can move again.

---

## Scenario 4 — Attack damage relic is applied immediately

**Steps**:
1. When the offer shows, pick the `Sharp Edge` relic (+20% attack damage).
2. Before entering the next room, note the CombatComponent's `attack_damage` in the Output panel or by triggering an attack.

**Expected**: `attack_damage = base_attack_damage × MetaManager.damage_multiplier × 1.2`.
If base = 1.0, meta mult = 1.0: `attack_damage = 1.2`.

---

## Scenario 5 — No offer after third standard room (1st since last offer)

**Steps**:
1. After collecting a relic (offer count reset), clear the next standard room.
2. Observe: no offer.

**Expected**: Counter resets after offer. One clear is not enough for a new offer.

---

## Scenario 6 — Offer after fourth standard room (2nd since last offer)

**Steps**:
1. After scenario 5 (no offer at room 3), clear one more standard room (room 4).

**Expected**: Offer appears again.

---

## Scenario 7 — Elite room always triggers an offer

**Steps**:
1. Navigate to an `EliteRoom01` at any point in the run.
2. Kill all enemies (there will be more than a standard room due to the 1.5× multiplier).
3. Observe offer screen immediately after the last kill.

**Expected**: Offer appears regardless of current standard_rooms_cleared counter.

---

## Scenario 8 — Elite offer does not reset the standard room counter

**Steps**:
1. Clear 1 standard room (counter = 1). [Confirm no offer.]
2. Clear an elite room → offer appears.
3. Clear 1 more standard room (counter should be 2 now? No — counter was 1 before elite, stays 1).
   Actually: counter = 1 going into elite; elite doesn't change it; so after elite offer, counter = 1.
4. Clear 1 standard room → counter = 2 → offer appears.

**Expected**: Offer appears after 1 additional standard room post-elite (because counter was 1 before elite).
Confirm: after elite offer, the rhythm resumes correctly from where the counter was.

---

## Scenario 9 — Two damage relics stack multiplicatively

**Steps**:
1. Pick `Sharp Edge` (×1.2). Confirm attack_damage = base × 1.2.
2. Clear 2 more rooms. Pick `Rage Crystal` (×1.3).
3. Confirm attack_damage = base × 1.2 × 1.3 = base × 1.56.

**Expected**: Stacking is multiplicative. If base = 1.0: attack_damage = 1.56.

---

## Scenario 10 — Attack speed relic reduces attack interval

**Steps**:
1. Note current `attack_interval` before picking.
2. Pick `Swift Strike` (×1.25 attack speed).
3. Confirm `attack_interval = base_attack_interval / 1.25`.

**Expected**: If base interval = 0.5, new interval = 0.4 (attacks 25% faster).

---

## Scenario 11 — Max health relic increases max HP proportionally

**Steps**:
1. Take some damage (e.g., run into an enemy) so current_health < max_health.
2. Pick `Iron Hide` (×1.3 max_health).
3. Confirm new max_health = base_max_health × 1.3.
4. Confirm current_health scaled proportionally (not zero, not above new max).

**Expected**: Max health increased. Current health preserved proportionally.

---

## Scenario 12 — Relics cleared on run end; new run starts clean

**Steps**:
1. Collect 2–3 relics during a run. Note elevated stats.
2. End the run (cash out or die).
3. Start a new run.
4. Confirm: attack_damage = base × MetaManager.damage_multiplier (no relic mult).
5. Confirm: attack_interval = base (no relic speed mult).
6. Confirm: max_health = base max_health (StatsComponent @export value).

**Expected**: All relic effects are gone. Stats return to base × meta-mult.

---

## Scenario 13 — RelicManager print log verification

When picking a relic, confirm Output panel shows:
```
[RelicManager] relic picked — id=sharp_edge
[RelicManager] stat_mult attack_damage=1.2
```
(Or equivalent log lines confirming the pick was registered.)

---

## Scenario 14 — Offered relics are drawn from the pool and are distinct

**Steps**:
1. Observe multiple offers throughout a run.
2. Confirm each offer shows 2 relics with different names (never the same relic twice in one offer).
3. Confirm relics shown match entries in `data/relics.json`.

**Expected**: Two distinct relics per offer. Both names and descriptions match the JSON definitions.
