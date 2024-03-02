extends Node


@export var _world_space: WorldSpace


func activate_at(position: Vector2i) -> void:
	_world_space.activate_chunks_at(position)


func deactivate_at(position: Vector2i) -> void:
	_world_space.deactivate_chunks_at(position)


func activate_intersects(rect: Rect2i) -> void:
	_world_space.activate_chunks_intersects(rect)


func deactivate_intersects(rect: Rect2i) -> void:
	_world_space.deactivate_chunks_intersects(rect)
