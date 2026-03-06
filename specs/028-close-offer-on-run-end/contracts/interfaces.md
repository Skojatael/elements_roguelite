# Contracts: Close Relic Offer on Run End

**Feature**: 028-close-offer-on-run-end
**Date**: 2026-03-03

---

## Main.gd (scenes/core/Main.gd) — MODIFIED

One guard block added to `_on_run_ended()`:

```gdscript
func _on_run_ended(_reason: RunManager.EndReason) -> void:
    if _relic_offer_layer != null:   # NEW — dismiss open offer before results screen
        _relic_offer_layer.queue_free()
        _relic_offer_layer = null
        _relic_offer_screen = null
    if is_instance_valid(_hub_room):   # existing
        _hub_room.queue_free()
        _hub_room = null
    _player.visible = false
    # ... rest unchanged
```

**Behaviour**:
- If `_relic_offer_layer` is non-null, it is freed (taking `_relic_offer_screen` with it) and both refs nulled.
- No `RelicManager.pick_relic()` call — no relic is awarded.
- If `_relic_offer_layer` is null (no offer open), the block is a no-op.
- The rest of `_on_run_ended()` (results screen creation) proceeds unchanged.

---

## All other files — UNCHANGED

`RelicManager`, `MetaManager`, `RunManager`, `GlobalSignals` — no changes.
