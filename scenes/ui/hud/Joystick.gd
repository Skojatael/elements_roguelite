class_name JoystickControl
extends Control

## Maximum drag distance from base centre, in pixels.
@export var max_radius: float = 80.0

## Fraction of max_radius treated as dead zone (produces no input).
## Must be in [0.0, 0.5].
@export var dead_zone_percentage: float = 0.1

## Current normalised movement input: direction × magnitude (0.0–1.0).
## Vector2.ZERO when idle or inside dead zone.
## Read-only from outside this script.
var input_vector: Vector2 = Vector2.ZERO

var _touch_index: int = -1

@onready var _base: ColorRect = $Base
@onready var _knob: ColorRect = $Knob


func _ready() -> void:
	assert(max_radius > 0.0,
		"JoystickControl: max_radius must be greater than 0")
	assert(dead_zone_percentage >= 0.0 and dead_zone_percentage <= 0.5,
		"JoystickControl: dead_zone_percentage must be in [0.0, 0.5]")


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			# Only claim touches that start inside the joystick rect.
			if get_global_rect().has_point(event.position):
				_touch_index = event.index
				get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_index:
			# Finger lifted — reset everything.
			_touch_index = -1
			input_vector = Vector2.ZERO
			_knob.position = size / 2.0 - _knob.size / 2.0
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		if event.index != _touch_index:
			return

		# Convert from global screen position to local control position.
		var local_pos: Vector2 = event.position - get_global_rect().position
		var offset: Vector2 = local_pos - size / 2.0

		# Input clamped at max_radius.
		var input_offset: Vector2 = offset
		if input_offset.length() > max_radius:
			input_offset = input_offset.normalized() * max_radius

		# Apply radial dead zone.
		if input_offset.length() < max_radius * dead_zone_percentage:
			input_vector = Vector2.ZERO
		else:
			input_vector = input_offset.normalized()

		# Visual feedback: knob may extend beyond base edge by up to half the knob's size.
		var visual_max: float = max_radius + _knob.size.x / 2.0
		if offset.length() > visual_max:
			offset = offset.normalized() * visual_max
		_knob.position = size / 2.0 - _knob.size / 2.0 + offset
		get_viewport().set_input_as_handled()
