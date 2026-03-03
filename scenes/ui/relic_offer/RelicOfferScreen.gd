class_name RelicOfferScreen
extends Control

signal relic_picked(relic_id: String)

@export var _card_left: RelicCard
@export var _card_right: RelicCard


func _ready() -> void:
	assert(_card_left != null, "RelicOfferScreen: _card_left not assigned in Inspector")
	assert(_card_right != null, "RelicOfferScreen: _card_right not assigned in Inspector")


func setup(options: Array) -> void:
	if options.size() >= 1:
		_card_left.setup(options[0] as RelicData)
		_card_left.relic_selected.connect(func(id: String) -> void: relic_picked.emit(id))
	if options.size() >= 2:
		_card_right.setup(options[1] as RelicData)
		_card_right.relic_selected.connect(func(id: String) -> void: relic_picked.emit(id))
