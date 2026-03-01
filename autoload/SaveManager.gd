extends Node

var _impl: SaveManagerImpl = SaveManagerImpl.new()


func _ready() -> void:
	pass


func save_meta_state(state: MetaState) -> void:
	_impl.save_meta_state(state)


func load_meta_state() -> MetaState:
	return _impl.load_meta_state()
