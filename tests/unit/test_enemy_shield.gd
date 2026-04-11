extends GutTest

## Tests for the shield absorption arithmetic and stun countdown logic in Enemy.gd.
## All tests use inline helper functions — no autoloads, no Enemy node instantiation.


# --- Shield absorption helpers (mirrors take_damage interception logic) ---

## Returns {new_shield_hp, overflow} for a single hit.
func _absorb(amount: float, shield_hp: int) -> Dictionary:
	if shield_hp <= 0:
		return {"new_shield_hp": 0, "overflow": amount}
	var remaining: int = shield_hp - int(ceilf(amount))
	if remaining > 0:
		return {"new_shield_hp": remaining, "overflow": 0.0}
	# Shield depleted — overflow is the portion beyond the shield
	var overflow: float = amount - float(shield_hp)
	return {"new_shield_hp": 0, "overflow": maxf(0.0, overflow)}


# --- Absorption tests ---

func test_damage_below_shield_reduces_shield_only() -> void:
	# amount 50 < shield 100 → shield = 50, overflow = 0
	var r: Dictionary = _absorb(50.0, 100)
	assert_eq(r["new_shield_hp"], 50)
	assert_eq(r["overflow"], 0.0)


func test_damage_equals_shield_zeroes_shield_no_overflow() -> void:
	# amount 100 == shield 100 → shield = 0, overflow = 0
	var r: Dictionary = _absorb(100.0, 100)
	assert_eq(r["new_shield_hp"], 0)
	assert_eq(r["overflow"], 0.0)


func test_damage_above_shield_carries_overflow() -> void:
	# amount 150 > shield 100 → shield = 0, overflow = 50
	var r: Dictionary = _absorb(150.0, 100)
	assert_eq(r["new_shield_hp"], 0)
	assert_eq(r["overflow"], 50.0)


func test_zero_shield_hp_passes_full_damage_through() -> void:
	# shield_hp = 0 means no shield — all damage reaches regular HP
	var r: Dictionary = _absorb(80.0, 0)
	assert_eq(r["new_shield_hp"], 0)
	assert_eq(r["overflow"], 80.0)


func test_small_hit_against_large_shield() -> void:
	# amount 1 vs shield 200 → shield = 199, overflow = 0
	var r: Dictionary = _absorb(1.0, 200)
	assert_eq(r["new_shield_hp"], 199)
	assert_eq(r["overflow"], 0.0)


func test_overflow_is_never_negative() -> void:
	# amount exactly equals shield → overflow must be >= 0, not negative
	var r: Dictionary = _absorb(200.0, 200)
	assert_true(r["overflow"] >= 0.0, "overflow must not be negative")


# --- Stun countdown helpers ---

func _tick_stun(remaining: float, delta: float) -> Dictionary:
	var new_remaining: float = maxf(0.0, remaining - delta)
	var expired: bool = new_remaining <= 0.0
	return {"remaining": new_remaining, "expired": expired}


func test_stun_decrements_by_delta() -> void:
	var r: Dictionary = _tick_stun(3.0, 0.5)
	assert_eq(r["remaining"], 2.5)
	assert_false(r["expired"])


func test_stun_expires_when_timer_reaches_zero() -> void:
	var r: Dictionary = _tick_stun(0.5, 0.5)
	assert_eq(r["remaining"], 0.0)
	assert_true(r["expired"])


func test_stun_does_not_go_negative() -> void:
	var r: Dictionary = _tick_stun(0.1, 1.0)
	assert_eq(r["remaining"], 0.0)
	assert_true(r["expired"])


func test_stun_not_expired_when_time_remains() -> void:
	var r: Dictionary = _tick_stun(3.0, 0.016)
	assert_false(r["expired"])
	assert_true(r["remaining"] > 0.0)


# --- Edge case: damage while stunned passes through (shield_hp = 0 during stun) ---

func test_damage_during_stun_hits_regular_hp() -> void:
	# Stun implies shield_hp = 0 (broken) — damage goes through
	var r: Dictionary = _absorb(40.0, 0)
	assert_eq(r["overflow"], 40.0, "damage during stun should reach regular HP")
