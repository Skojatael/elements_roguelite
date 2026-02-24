class_name SpawnContext
extends RefCounted

var parent: Node
var position: Vector2


static func create(p_parent: Node, p_position: Vector2) -> SpawnContext:
	var ctx := SpawnContext.new()
	ctx.parent = p_parent
	ctx.position = p_position
	return ctx
