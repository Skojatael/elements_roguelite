# Interfaces: Boss Rewards (032)

---

## 1. data/enemies.json — boss base_essence

```json
"boss": [
  {
    "id": "boss",
    "max_health": 40.0,
    "damage": 5.0,
    "damage_cooldown": 2.0,
    "base_essence": 80,
    "rooms_required": 6
  }
]
```

---

## 2. RelicManagerImpl.gd — draw_boss_offer() (new method)

```gdscript
## Draws up to 3 rare relics not already held by the player.
## Draws from the full rare pool (not the deck) — boss offer is a one-time event.
## Returns empty array if rare tier has no available relics.
func draw_boss_offer() -> Array[RelicData]:
	if not _all_by_tier.has("rare"):
		return []
	var available: Array[RelicData] = []
	for r: RelicData in (_all_by_tier["rare"] as Array):
		if not active_relic_ids.has(r.id):
			available.append(r)
	available.shuffle()
	return available.slice(0, mini(3, available.size()))
```

---

## 3. RelicManager.gd (autoload) — _on_room_cleared() fix + trigger_boss_offer() (new)

```gdscript
func _on_room_cleared(room_id: String) -> void:
	if room_id == "boss_room":        # NEW — skip boss room clear
		return
	if not MetaManager.is_relic_offers_active:
		return
	# ... rest unchanged

## Draws 3 rare relics and emits relic_offer_ready. Returns true if offer was triggered.
## Returns false if no rare relics are available (caller should show victory overlay directly).
func trigger_boss_offer() -> bool:
	var options: Array[RelicData] = _impl.draw_boss_offer()
	if options.is_empty():
		print("[RelicManager] trigger_boss_offer — no rare relics available, skipping")
		return false
	print("[RelicManager] boss offer triggered — {count} rare relics".format({"count": options.size()}))
	relic_offer_ready.emit(options)
	return true
```

---

## 4. Main.gd — new field + rewritten _on_boss_room_cleared() + modified _on_relic_picked() + new _show_boss_victory_overlay()

### New field

```gdscript
var _boss_relic_pending: bool = false
```

### _on_run_started() — reset flag (add one line)

```gdscript
func _on_run_started() -> void:
	_boss_relic_pending = false          # NEW
	if _boss_victory_layer != null:
	# ... rest unchanged
```

### _on_boss_room_cleared() — rewritten

```gdscript
func _on_boss_room_cleared(_room_id: String) -> void:
	_boss_room_spawner = null
	var base: float = ResourceManager.get_enemy_base_essence("boss")
	var rooms_cleared: int = RunManager.cleared_rooms.size()
	var reward: int = floori(base * (1.0 + 0.06 * float(maxi(0, rooms_cleared - 6))))
	RunManager.add_currency(reward)
	print("[Main] boss reward — base={b} rooms_cleared={r} reward={w}".format({
		"b": base, "r": rooms_cleared, "w": reward,
	}))
	_exploration_hud.visible = false
	if RelicManager.trigger_boss_offer():
		_boss_relic_pending = true
	else:
		_show_boss_victory_overlay()
```

### _on_relic_picked() — add boss branch

```gdscript
func _on_relic_picked(relic_id: String) -> void:
	RelicManager.pick_relic(relic_id)
	_relic_offer_layer.queue_free()
	_relic_offer_layer = null
	_relic_offer_screen = null
	if _boss_relic_pending:
		_boss_relic_pending = false
		_show_boss_victory_overlay()
	else:
		_exploration_hud.visible = true
```

### _show_boss_victory_overlay() — extracted helper (new)

```gdscript
func _show_boss_victory_overlay() -> void:
	_boss_victory_layer = CanvasLayer.new()
	add_child(_boss_victory_layer)
	_boss_victory_overlay = _BOSS_VICTORY_OVERLAY_SCENE.instantiate() as BossVictoryOverlay
	_boss_victory_layer.add_child(_boss_victory_overlay)
	_boss_victory_overlay.cash_out_pressed.connect(_on_boss_cash_out_pressed)
	_boss_victory_overlay.continue_pressed.connect(_on_boss_continue_pressed)
```

---

## Signal Flow

```
Boss dies
  → RoomSpawner.room_cleared("boss_room")
  → Main._on_boss_room_cleared()
      → RunManager.add_currency(reward)        [NEW — essence award]
      → RelicManager.trigger_boss_offer()      [NEW — 3 rare relics]
          → relic_offer_ready.emit(options)
          → Main._on_relic_offer_ready()        [existing — shows RelicOfferScreen]
              _boss_relic_pending = true

Player picks relic
  → Main._on_relic_picked(relic_id)
      → RelicManager.pick_relic(relic_id)
      → frees _relic_offer_layer
      → _boss_relic_pending == true:
          → _boss_relic_pending = false
          → _show_boss_victory_overlay()        [existing overlay, new helper]

  [fallback: no rare relics available]
  → Main._on_boss_room_cleared() → trigger_boss_offer() returns false
      → _show_boss_victory_overlay() called directly
```
