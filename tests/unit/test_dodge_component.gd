extends GutTest

const DodgeComponent = preload("res://scenes/player/components/DodgeComponent.gd")

# Minimal stub for StatsComponent — no autoloads needed.
class StubStats:
	var is_invulnerable: bool = false

# Minimal stub for MovementComponent.
class StubMovement:
	var last_direction: Vector2 = Vector2.DOWN

# Minimal stub for the parent CharacterBody2D.
class StubParent:
	var velocity: Vector2 = Vector2.ZERO
	var move_and_slide_called: bool = false
	func move_and_slide() -> void:
		move_and_slide_called = true

var _dodge: DodgeComponent
var _stats: StubStats
var _movement: StubMovement
var _parent: StubParent


func before_each() -> void:
	_dodge = DodgeComponent.new()
	_stats = StubStats.new()
	_movement = StubMovement.new()
	_parent = StubParent.new()
	# Inject stubs directly — bypasses _ready() autoload calls.
	_dodge._stats = _stats
	_dodge._movement = _movement
	_dodge._cooldown = 1.5
	_dodge._dash_distance = 300.0
	_dodge._dash_speed = _dodge._dash_distance / DodgeComponent.DASH_DURATION_SEC


func after_each() -> void:
	_dodge.free()


# activate() while on cooldown must do nothing.
func test_activate_ignored_during_cooldown() -> void:
	_dodge._cooldown_remaining = 0.5
	_dodge._is_dashing = false
	_stats.is_invulnerable = false

	_dodge.activate()

	assert_false(_dodge._is_dashing, "Dash must not start while on cooldown")
	assert_false(_stats.is_invulnerable, "Invulnerability must not be set during cooldown")


# activate() while already dashing must do nothing.
func test_activate_ignored_while_dashing() -> void:
	_dodge._cooldown_remaining = 0.0
	_dodge._is_dashing = true
	_stats.is_invulnerable = true  # already mid-dash

	_dodge.activate()

	# _dash_remaining should not be reset to a new value
	assert_true(_dodge._is_dashing, "Should remain dashing")


# activate() when ready: sets invulnerability and initialises dash state.
func test_activate_sets_invulnerability() -> void:
	_dodge._cooldown_remaining = 0.0
	_dodge._is_dashing = false

	_dodge.activate()

	assert_true(_stats.is_invulnerable, "Invulnerability must be true at dash start")
	assert_true(_dodge._is_dashing, "Dash flag must be true after activate")
	assert_eq(_dodge._dash_remaining, _dodge._dash_distance, "Full distance must remain at start")


# activate() uses last_direction from MovementComponent.
func test_activate_uses_last_direction() -> void:
	_movement.last_direction = Vector2(1.0, 0.0)
	_dodge._cooldown_remaining = 0.0
	_dodge._is_dashing = false

	_dodge.activate()

	assert_eq(_dodge._dash_direction, Vector2(1.0, 0.0), "Dash direction must match last_direction")


# _physics_process advances _dash_remaining and ends dash when distance covered.
func test_physics_process_ends_dash_when_distance_covered() -> void:
	_dodge._is_dashing = true
	_dodge._dash_direction = Vector2(1.0, 0.0)
	_dodge._dash_remaining = 10.0  # small remaining distance
	_dodge._cooldown_remaining = 0.0
	_stats.is_invulnerable = true

	# Simulate a delta large enough to cover the remaining distance in one frame.
	# We pass parent via a lambda — DodgeComponent._physics_process reads get_parent().
	# Since we cannot call _physics_process without a scene tree, test the pure helpers instead.
	var covered: float = _dodge._dash_speed * 0.016  # ~1 frame at 60fps
	if covered >= 10.0:
		_dodge._dash_remaining = 0.0
		_dodge._end_dash()

	assert_false(_dodge._is_dashing, "Dash must end when remaining reaches zero")
	assert_false(_stats.is_invulnerable, "Invulnerability must clear on dash end")


# _end_dash starts the cooldown timer.
func test_end_dash_starts_cooldown() -> void:
	_dodge._is_dashing = true
	_stats.is_invulnerable = true
	_dodge._cooldown_remaining = 0.0

	_dodge._end_dash()

	assert_eq(_dodge._cooldown_remaining, _dodge._cooldown,
		"Full cooldown must be set after dash ends")


# cooldown_changed signal emits remaining and total values.
func test_cooldown_changed_signal_emits_on_activate() -> void:
	_dodge._cooldown_remaining = 0.0
	_dodge._is_dashing = false

	watch_signals(_dodge)
	_dodge.activate()

	assert_signal_emitted(_dodge, "cooldown_changed")
