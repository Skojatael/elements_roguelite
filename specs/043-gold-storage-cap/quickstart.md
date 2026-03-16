# Quickstart: Gold Offline Storage Cap (043)

Manual verification steps for all three user stories.

---

## Prerequisites

- Alchemy Lab is unlocked (≥ 500 shards spent).
- Transmuter is purchased (≥ 50 shards spent). Gold should be ticking in the hub.
- Developer access to device clock OR ability to manipulate `gold_last_saved_timestamp` in the save file.

---

## Story 1: Offline cap enforcement (base 4h)

### Setup

1. Open the game with Transmuter active.
2. Note current `gold_rate_per_hour` (default 100 gold/hr).
3. Set `gold_last_saved_timestamp` in save file to `now_unix - 21600` (6 hours ago) and reopen game.

### Expected result

- Gold credited = exactly 400 (4h × 100 gold/hr), not 600.
- `gold_last_saved_timestamp` in save file is updated to the current time.

### Under-cap case

4. Set timestamp to `now_unix - 7200` (2 hours ago) and reopen.
5. Expected: 200 gold credited (full 2h, not capped).

### Exact-cap case

6. Set timestamp to `now_unix - 14400` (exactly 4 hours ago) and reopen.
7. Expected: exactly 400 gold credited.

### Timer reset verification

8. Open game, note timestamp. Immediately close and reopen.
9. Set timestamp to `now_unix - 18000` (5 hours ago) and reopen.
10. Expected: only 4h cap applied (400 gold), timer reset to the moment of last open.

---

## Story 2: Storage cap upgrade

### Purchase first upgrade level

1. Ensure ≥ 100 shards.
2. Open Alchemy Lab. Observe `Gold Storage` button shows `"Gold Storage 4h → 8h (100 shards)"` (enabled).
3. Press the button.
4. Expected: shards decrease by 100, button updates to `"Gold Storage 8h → 12h (150 shards)"`.

### Verify new cap enforcement

5. Set `gold_last_saved_timestamp` to `now_unix - 36000` (10 hours ago) and reopen game.
6. Expected: 800 gold credited (8h × 100/hr), not 1000.

### Purchase second (max) upgrade level

7. Ensure ≥ 150 shards.
8. Press `Gold Storage` button (shows 8h → 12h, 150 shards).
9. Expected: button shows `"Gold Storage — MAX"` (disabled).

### Max cap verification

10. Set timestamp to `now_unix - 50400` (14 hours ago) and reopen.
11. Expected: 1200 gold credited (12h × 100/hr), not 1400.

### Affordability gate

12. With < 100 shards, open Alchemy Lab.
13. Expected: `Gold Storage` button is visible but disabled.

### Data-driven config check

14. Change `base_cost` in `meta_config.json` from 100 to 999. Reopen game.
15. Expected: upgrade button now shows 999 as cost, is disabled with < 999 shards.
16. Revert to 100.

---

## Story 3: Cap shown in Gold Display

### Base cap display

1. Open hub with Transmuter owned and level 0 storage cap.
2. Expected: GoldDisplay shows `"Cap: 4h"` (or equivalent label).

### Display updates after upgrade

3. Purchase the first storage cap upgrade.
4. Expected: cap label updates immediately to `"Cap: 8h"` without restarting.

### No display without Transmuter

5. On a fresh save (Transmuter not purchased), open the hub.
6. Expected: no cap label shown in GoldDisplay.

---

## Edge Cases

### Clock rollback

1. Set `gold_last_saved_timestamp` to `now_unix + 3600` (future — simulates rollback).
2. Reopen game.
3. Expected: 0 gold credited, timestamp NOT updated (rollback guard fires).

### First boot (timestamp = 0)

1. Delete save file or set `gold_last_saved_timestamp` to 0.
2. Open game.
3. Expected: 0 gold credited, `gold_last_saved_timestamp` is set to current time.

### Missing config key graceful fallback

1. Remove `gold_storage_cap` entry from `meta_config.json` entirely.
2. Open game.
3. Expected: base 4h cap applied via default fallback values; no crash.
