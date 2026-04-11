extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")
const EnemyProjectile = preload("res://scenes/combat/enemies/EnemyProjectile.gd")


# --- T008: EnemyData.is_ranged_attacker threshold tests ---

func test_is_ranged_attacker_returns_false_at_exactly_40() -> void:
	assert_false(EnemyData.is_ranged_attacker(40.0, 40.0))


func test_is_ranged_attacker_returns_false_below_40() -> void:
	assert_false(EnemyData.is_ranged_attacker(20.0, 40.0))


func test_is_ranged_attacker_returns_true_above_40() -> void:
	assert_true(EnemyData.is_ranged_attacker(80.0, 40.0))


func test_is_ranged_attacker_returns_true_at_41() -> void:
	assert_true(EnemyData.is_ranged_attacker(41.0, 40.0))


func test_is_ranged_attacker_custom_threshold_returns_false() -> void:
	# threshold 100, range 80 → false
	assert_false(EnemyData.is_ranged_attacker(80.0, 100.0))


func test_is_ranged_attacker_custom_threshold_returns_true() -> void:
	# threshold 100, range 101 → true
	assert_true(EnemyData.is_ranged_attacker(101.0, 100.0))


# --- T009: EnemyProjectile direction-lock tests ---

func test_projectile_stores_right_direction() -> void:
	var p := EnemyProjectile.new()
	# Wire a stub hit_area to avoid null access in setup
	var area := Area2D.new()
	p._hit_area = area
	p.setup(Vector2.RIGHT, 10.0, 400.0, 1200.0)
	assert_eq(p._direction, Vector2.RIGHT)
	p.free()
	area.free()


func test_projectile_normalizes_direction() -> void:
	var p := EnemyProjectile.new()
	var area := Area2D.new()
	p._hit_area = area
	p.setup(Vector2(3.0, 4.0), 5.0, 400.0, 1200.0)
	assert_almost_eq(p._direction.x, 0.6, 0.0001)
	assert_almost_eq(p._direction.y, 0.8, 0.0001)
	p.free()
	area.free()


func test_projectile_stores_damage() -> void:
	var p := EnemyProjectile.new()
	var area := Area2D.new()
	p._hit_area = area
	p.setup(Vector2.RIGHT, 5.0, 400.0, 1200.0)
	assert_eq(p._damage, 5.0)
	p.free()
	area.free()


func test_projectile_distance_traveled_starts_at_zero() -> void:
	var p := EnemyProjectile.new()
	var area := Area2D.new()
	p._hit_area = area
	p.setup(Vector2.RIGHT, 10.0, 400.0, 1200.0)
	assert_eq(p._distance_traveled, 0.0)
	p.free()
	area.free()


# --- T010: EnemyProjectile pass-through logic tests ---

func test_projectile_on_body_entered_ignores_non_player() -> void:
	var p := EnemyProjectile.new()
	var area := Area2D.new()
	p._hit_area = area
	p.setup(Vector2.RIGHT, 10.0, 400.0, 1200.0)
	# Create a stub body NOT in "player" group
	var stub := Node2D.new()
	# Call _on_body_entered — should return early without freeing p
	p._on_body_entered(stub)
	assert_true(is_instance_valid(p), "Projectile should still be valid after hitting non-player")
	p.free()
	area.free()
	stub.free()
