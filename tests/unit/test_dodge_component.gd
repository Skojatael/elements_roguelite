extends GutTest

const DodgeComponent = preload("res://scenes/player/components/DodgeComponent.gd")

# Stubs extend real classes so static typing is satisfied.
# _ready() is overridden to prevent autoload calls.

class StubStats extends StatsComponent:
	func _ready() -> void:
		pass

class StubMovement extends MovementComponent:
	func _ready() -> void:
		pass

var _dodge: DodgeComponent
var _stats: StubStats
var _movement: StubMovement
var _body: CharacterBody2D


func before_each() -> void:
	# Parent body gives _end_dash() a valid get_parent() target.
	_body = CharacterBody2D.new()
	add_child(_body)

	_dodge = DodgeComponent.new()
	_body.add_child(_dodge)

	_stats = StubStats.new()
	_movement = StubMovement.new()
	_body.add_child(_stats)
	_body.add_child(_movement)

	# Inject stubs directly — bypasses _ready() autoload calls.
	_dodge._stats = _stats
	_dodge._movement = _movement
	_dodge._cooldown = 1.5
	_dodge._dash_distance = 300.0
	_dodge._dash_speed = _dodge._dash_distance / DodgeComponent.DASH_DURATION_SEC


func after_each() -> void:
	_body.queue_free()
	RunManager.is_run_active = false


# activate() while on cooldown must do nothing.
func test_activate_ignored_during_cooldown() -> void:
	RunManager.is_run_active = true
	_dodge._cooldown_remaining = 0.5
	_dodge._is_dashing = false
	_stats.is_invulnerable = false

	_dodge.activate()

	assert_false(_dodge._is_dashing, "Dash must not start while on cooldown")
	assert_false(_stats.is_invulnerable, "Invulnerability must not be set during cooldown")


# activate() while already dashing must do nothing (no double-dash).
func test_activate_ignored_while_dashing() -> void:
	RunManager.is_run_active = true
	_dodge._cooldown_remaining = 0.0
	_dodge._is_dashing = true
	_stats.is_invulnerable = true

	_dodge.activate()

	assert_true(_dodge._is_dashing, "Should remain dashing")


# activate() when ready: sets invulnerability and initialises dash state.
func test_activate_sets_invulnerability() -> void:
	RunManager.is_run_active = true
	_dodge._cooldown_remaining = 0.0
	_dodge._is_dashing = false

	_dodge.activate()

	assert_true(_stats.is_invulnerable, "Invulnerability must be true at dash start")
	assert_true(_dodge._is_dashing, "Dash flag must be true after activate")
	assert_eq(_dodge._dash_remaining, _dodge._dash_distance, "Full distance must remain at start")


# activate() uses last_direction from MovementComponent.
func test_activate_uses_last_direction() -> void:
	RunManager.is_run_active = true
	_movement.last_direction = Vector2(1.0, 0.0)
	_dodge._cooldown_remaining = 0.0
	_dodge._is_dashing = false

	_dodge.activate()

	assert_eq(_dodge._dash_direction, Vector2(1.0, 0.0), "Dash direction must match last_direction")


# _end_dash clears invulnerability and starts cooldown.
func test_end_dash_clears_invulnerability_and_starts_cooldown() -> void:
	_dodge._is_dashing = true
	_stats.is_invulnerable = true
	_dodge._cooldown_remaining = 0.0

	_dodge._end_dash()

	assert_false(_dodge._is_dashing, "Dash flag must clear on end")
	assert_false(_stats.is_invulnerable, "Invulnerability must clear on dash end")
	assert_eq(_dodge._cooldown_remaining, _dodge._cooldown,
		"Full cooldown must be set after dash ends")


# cooldown_changed signal emits on activate.
func test_cooldown_changed_signal_emits_on_activate() -> void:
	RunManager.is_run_active = true
	_dodge._cooldown_remaining = 0.0
	_dodge._is_dashing = false

	watch_signals(_dodge)
	_dodge.activate()

	assert_signal_emitted(_dodge, "cooldown_changed")


# activate() does nothing outside a run.
func test_activate_ignored_outside_run() -> void:
	RunManager.is_run_active = false
	_dodge._cooldown_remaining = 0.0
	_dodge._is_dashing = false

	_dodge.activate()

	assert_false(_dodge._is_dashing, "Dash must not start outside an active run")
