# Quickstart: HP Regeneration (060-hp-regen)

## What changes

| File | Change |
|---|---|
| `data/relics.json` | Add `common_regen` entry under `"common"` tier |
| `scenes/player/components/StatsComponent.gd` | Add `_process(delta)` regen tick |

No new files. No new scenes. No editor work required.

## Implementation steps

### Step 1 — Add relic to data/relics.json

Inside the `"common"` object, add:

```json
"common_regen": {
    "name": "Regeneration Stone",
    "tags": ["survival"],
    "effect_stat": "hp_regen",
    "effect_mult": 0.01,
    "description": "+1% HP per second"
}
```

### Step 2 — Add regen tick to StatsComponent

Add `_process(delta: float) -> void` after the existing `_on_relic_applied` method:

```gdscript
func _process(delta: float) -> void:
    if not is_player:
        return
    if not RunManager.is_run_active:
        return
    var rate: float = RelicManager.get_stat_addend("hp_regen")
    if rate <= 0.0:
        return
    if current_health >= max_health:
        return
    heal(rate * max_health * delta)
```

`heal()` already clamps to `max_health` and emits `health_changed` — no additional wiring needed.

## How to test

1. Start a run via DevPanel or TeleportDoor.
2. Use DevPanel → "Get Relic" and select Regeneration Stone (or wait for an offer at a standard room clear).
3. Take some damage, then stand still — observe HP bar slowly refilling.
4. Verify HP stops climbing at max HP.
5. End the run (cash out or die) — hub HP bar should not tick.
6. Verify a run with no regen relic shows zero passive HP gain.
