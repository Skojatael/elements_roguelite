extends Node

var meta_state: MetaState:
	get: return _impl.meta_state

var _impl: MetaManagerImpl = MetaManagerImpl.new()


func _ready() -> void:
	_impl.load(SaveManager)
	RunManager.run_ended.connect(func(r: RunManager.EndReason) -> void: _on_run_ended(r))


func _on_run_ended(_reason: RunManager.EndReason) -> void:
	var rate: float = ResourceManager.get_meta_config().get("shard_conversion_rate", 1.0)
	_impl.on_run_ended(RunManager.run_summary, rate, SaveManager)
