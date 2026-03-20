# Implementation Plan: Forge Rarity Upgrade

**Branch**: `067-forge-rarity-upgrade` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/067-forge-rarity-upgrade/spec.md`

## Summary

Add a one-time purchasable upgrade ("Rarity Luck", 350 shards) to the Magic Forge. When owned, each relic draw during a run has an independent 10% chance to be promoted one rarity tier higher than the room's default (common → uncommon in standard rooms; uncommon → rare in elite rooms). Boss offers are unaffected. Promotion rate and cost are stored in `meta_config.json`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Existing autoloads: `MetaManager`, `RelicManager`, `ResourceManager`, `SaveManager`. Existing scripts: `RelicManagerImpl`, `MetaManagerImpl`, `MetaState`, `SaveManagerImpl`, `ForgeUpgradeScreen`.
**Storage**: `user://meta_save.json` (JSON, via `SaveManagerImpl`); `data/meta_config.json` (read-only config)
**Testing**: GUT unit tests in `tests/unit/`
**Target Platform**: Android mobile (portrait 1080×1920); Windows for dev
**Project Type**: Single Godot project
**Performance Goals**: No impact — promotion roll is a single `randf()` call per draw, O(1)
**Constraints**: All balance values in JSON; no hard-coded constants; autoloads remain thin wrappers

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Single Responsibility** | ✅ PASS | Draw promotion logic lives entirely in `RelicManagerImpl`. `MetaManagerImpl` handles purchase. `ForgeUpgradeScreen` handles UI. No cross-concern mixing. |
| **II. Data-Driven Content** | ✅ PASS | Cost (350) and promotion_chance (0.1) stored in `meta_config.json`; no hard-coded balance values in GDScript. |
| **III. Mobile-First** | ✅ PASS | One extra `randf()` per draw — negligible overhead. No new scenes, shaders, or draw calls. |
| **IV. Editor-Centric** | ✅ PASS | New Button node added via Godot Editor; referenced via `@export var _rarity_luck_button: Button`. No raw `.tscn` edits. |
| **V. Simplicity & YAGNI** | ✅ PASS | No new abstractions. `promotion_chance` default of `0.0` keeps all existing callers unchanged. `_next_tier` and `_draw_one_with_promotion` are private helpers with exactly two call sites each. |
| **VI. Early Return** | ✅ PASS | New helpers use guard clauses and early returns. `_draw_one_with_promotion` returns immediately on successful promotion; falls through to base draw otherwise. |

## Project Structure

### Documentation (this feature)

```text
specs/067-forge-rarity-upgrade/
├── plan.md              ← this file
├── research.md          ← Phase 0
├── data-model.md        ← Phase 1
└── tasks.md             ← Phase 2 (/speckit.tasks)
```

### Source Code (affected files)

```text
data/
└── meta_config.json                        ← add rarity_luck_upgrade entry

scripts/
├── data_models/
│   └── MetaState.gd                        ← add rarity_luck_owned field
└── managers/
    ├── SaveManager.gd                      ← add rarity_luck_owned to save/load
    ├── MetaManagerImpl.gd                  ← add purchase_rarity_luck()
    └── RelicManagerImpl.gd                 ← add _next_tier(), _draw_one_with_promotion(),
                                               update draw_offer() signature

autoload/
├── MetaManager.gd                          ← add is_rarity_luck_owned, purchase_rarity_luck()
└── RelicManager.gd                         ← pass promotion_chance in _on_room_cleared()

scenes/hub/
├── ForgeUpgradeScreen.gd                   ← add rarity luck button wiring
└── ForgeUpgradeScreen.tscn                 ← EDITOR: add Button node, assign @export

tests/unit/
└── test_relic_rarity_upgrade.gd            ← new unit tests for draw_offer promotion
```

## Implementation Steps

### Step 1 — Data: `data/meta_config.json`

Add `rarity_luck_upgrade` under `magic_forge.upgrades`:
```json
"rarity_luck_upgrade": {
  "name": "Rarity Luck",
  "cost": 350,
  "promotion_chance": 0.1
}
```

---

### Step 2 — Data model: `scripts/data_models/MetaState.gd`

Add one field after `missile_extra_charge_owned`:
```gdscript
var rarity_luck_owned: bool = false
```

---

### Step 3 — Persistence: `scripts/managers/SaveManager.gd`

In `save_meta_state()`, add to the data dictionary:
```gdscript
"rarity_luck_owned": state.rarity_luck_owned,
```

In `load_meta_state()`, add to the parse block:
```gdscript
state.rarity_luck_owned = bool((parsed as Dictionary).get("rarity_luck_owned", false))
```

---

### Step 4 — Logic: `scripts/managers/MetaManagerImpl.gd`

Add purchase method following the established boolean-owned pattern:
```gdscript
## Purchases Rarity Luck upgrade if not already owned and affordable. Returns true on success.
func purchase_rarity_luck(cost: int, save_manager: Node) -> bool:
    if meta_state.rarity_luck_owned:
        return false
    if not can_spend(cost):
        return false
    meta_state.total_shards -= cost
    meta_state.rarity_luck_owned = true
    _save(save_manager)
    return true
```

---

### Step 5 — Autoload: `autoload/MetaManager.gd`

Add computed property (after `is_missile_extra_charge_owned`):
```gdscript
var is_rarity_luck_owned: bool:
    get: return _impl.meta_state.rarity_luck_owned
```

Add delegating purchase method:
```gdscript
func purchase_rarity_luck() -> bool:
    var cfg: Dictionary = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("rarity_luck_upgrade", {})
    var cost: int = cfg.get("cost", 350)
    var success: bool = _impl.purchase_rarity_luck(cost, SaveManager)
    if success:
        shards_changed.emit(meta_state.total_shards)
    return success
```

---

### Step 6 — Draw logic: `scripts/managers/RelicManagerImpl.gd`

**Add `_next_tier` helper** (pure function, no side effects):
```gdscript
## Returns the next rarity tier above tier, or "" if tier is already the highest.
func _next_tier(tier: String) -> String:
    match tier:
        "common": return "uncommon"
        "uncommon": return "rare"
    return ""
```

**Add `_draw_one_with_promotion` helper**:
```gdscript
## Draws one relic with optional per-draw rarity promotion.
## Attempts to draw from the next tier if promotion_chance > 0 and the roll succeeds.
## Falls back to base_tier if next tier is absent, empty, or the roll misses.
func _draw_one_with_promotion(base_tier: String, promotion_chance: float) -> RelicData:
    if promotion_chance > 0.0:
        var next: String = _next_tier(base_tier)
        if not next.is_empty() and _all_by_tier.has(next) and not (_all_by_tier[next] as Array).is_empty():
            if randf() < promotion_chance:
                var promoted: RelicData = _draw_one_from_tier(next)
                if promoted != null:
                    return promoted
    return _draw_one_from_tier(base_tier)
```

**Update `draw_offer`** — add `promotion_chance` parameter; use `_draw_one_with_promotion`; fix de-dup to strip from `left.tier` (the actual tier drawn from) not from the base `tier` argument:

```gdscript
## Returns Array[RelicData] of exactly 2 distinct entries drawn from tier (or promoted tier).
## promotion_chance: independent per-draw chance (0.0–1.0) to draw from the next higher tier.
## Falls back to base tier if promoted tier is empty. Default 0.0 = no promotion.
func draw_offer(tier: String, promotion_chance: float = 0.0) -> Array[RelicData]:
    if not _all_by_tier.has(tier) or (_all_by_tier[tier] as Array).is_empty():
        return []
    var left: RelicData = _draw_one_with_promotion(tier, promotion_chance)
    if left == null:
        return []
    # Strip copies of left from the deck it was actually drawn from (may differ from base tier).
    var deck: Array = (_decks[left.tier] as Array).filter(
        func(r: RelicData) -> bool: return r.id != left.id
    )
    if deck.is_empty():
        deck = _build_expanded_deck(left.tier, left.id)
    _decks[left.tier] = deck
    if (_decks[tier] as Array).is_empty() and not _all_by_tier.has(tier):
        return [left]
    var right: RelicData = _draw_one_with_promotion(tier, promotion_chance)
    if right == null:
        return [left]
    return [left, right]
```

> **Note on deck emptiness guard**: The original guard `if (_decks[tier] as Array).is_empty(): return [left]` checked if the *base* tier deck was empty before drawing right. The new version checks the base tier deck (unmodified when left was promoted) plus a `_all_by_tier` guard. `_draw_one_with_promotion` itself handles empty decks via `_draw_one_from_tier`'s reshuffle fallback, so this guard is mainly a safety check.

---

### Step 7 — Autoload: `autoload/RelicManager.gd`

In `_on_room_cleared`, read the promotion chance from config and pass it to `draw_offer`:

```gdscript
func _on_room_cleared(room_id: String) -> void:
    if room_id == "boss_room":
        return
    if not MetaManager.is_relic_offers_active:
        return
    if not RunManager.is_run_active:
        return
    var room_type: String = ""
    if RunManager.current_room != null:
        room_type = (RunManager.current_room as RoomSpawner).room_type_id
    if not _impl.should_offer_for_room(room_type):
        return
    var tier: String = "uncommon" if room_type.contains("Elite") else "common"
    var promotion_chance: float = 0.0
    if MetaManager.is_rarity_luck_owned:
        promotion_chance = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("rarity_luck_upgrade", {}).get("promotion_chance", 0.1)
    var options: Array[RelicData] = _impl.draw_offer(tier, promotion_chance)
    if options.is_empty():
        print("[RelicManager] relic pool is empty — no offer")
        return
    print("[RelicManager] offer triggered — room_id='{id}' room_type='{type}' tier='{tier}' promotion={p}".format({
        "id": room_id,
        "type": room_type,
        "tier": tier,
        "p": promotion_chance,
    }))
    relic_offer_ready.emit(options)
```

> **Note**: The early-return refactor of `_on_room_cleared` applies `should_offer_for_room` check before computing tier, replacing the nested-if structure with guard clauses to comply with Constitution VI.

---

### Step 8 — UI script: `scenes/hub/ForgeUpgradeScreen.gd`

Add export, update method, and buy handler following the `_missile_charge_button` pattern:

```gdscript
@export var _rarity_luck_button: Button

# In _ready():
_rarity_luck_button.pressed.connect(_on_rarity_luck_buy)

# In _update_buttons():
_update_rarity_luck_button()

func _update_rarity_luck_button() -> void:
    var cfg: Dictionary = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("rarity_luck_upgrade", {})
    var rl_name: String = cfg.get("name", "Rarity Luck")
    var rl_cost: int = cfg.get("cost", 350)
    if MetaManager.is_rarity_luck_owned:
        _rarity_luck_button.text = "{n} — Purchased".format({"n": rl_name})
        _rarity_luck_button.disabled = true
        return
    if MetaManager.can_spend(rl_cost):
        _rarity_luck_button.text = "{n} — {c} shards".format({"n": rl_name, "c": rl_cost})
        _rarity_luck_button.disabled = false
    else:
        _rarity_luck_button.text = "{n} — {c} shards (insufficient)".format({"n": rl_name, "c": rl_cost})
        _rarity_luck_button.disabled = true

func _on_rarity_luck_buy() -> void:
    MetaManager.purchase_rarity_luck()
    _update_buttons()
```

---

### Step 9 — Editor task: `scenes/hub/ForgeUpgradeScreen.tscn`

**Must be performed in the Godot Editor:**
1. Open `scenes/hub/ForgeUpgradeScreen.tscn`.
2. Add a new `Button` node as a sibling of `_missile_charge_button` (same container/parent).
3. Set the node name (e.g., `RarityLuckButton`).
4. Select the root `ForgeUpgradeScreen` node → Inspector → assign `RarityLuckButton` to the `_rarity_luck_button` export slot.
5. Save the scene.

---

### Step 10 — Unit tests: `tests/unit/test_relic_rarity_upgrade.gd`

Write GUT tests covering:
- `_next_tier("common")` returns `"uncommon"`
- `_next_tier("uncommon")` returns `"rare"`
- `_next_tier("rare")` returns `""`
- With `promotion_chance = 0.0`, draw_offer always returns base-tier relics
- With `promotion_chance = 1.0`, draw_offer always returns next-tier relics (deterministic)
- With `promotion_chance = 1.0` and next tier empty, draw_offer falls back to base tier
- Both relics in a 2-card offer are distinct (de-dup works across tiers)

## Complexity Tracking

No Constitution violations. No complexity exceptions needed.
