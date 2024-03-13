class_name ChunksInRadiusActivityMaintainer
extends Node2D


@export var _world_space: WorldSpace
@export var _outer_shape: Shape2D
@export var _inner_shape: Shape2D

@export var _position_delta_to_rescan_outer: float
@export var _position_delta_to_rescan_inner: float

@export var _action: InputEventKey

var _prev_outer_scan_position: Vector2
var _prev_inner_scan_position: Vector2

var _outer_chunks: Array[WorldSpaceChunk]


func _input(event: InputEvent) -> void:
	if _action.is_match(event)\
	and event.is_pressed() == _action.pressed\
	and not event.is_echo():
		_rescan_outer()
		_rescan_inner()
		print("rescan")


func _physics_process(_delta: float) -> void:
	if _prev_outer_scan_position.distance_to(global_position) > _position_delta_to_rescan_outer:
		_rescan_outer()
	
	if _prev_inner_scan_position.distance_to(global_position) > _position_delta_to_rescan_inner:
		_rescan_inner()


func _rescan_outer() -> void:
	_outer_chunks = _world_space.get_intersecting_chunks(_outer_shape, global_transform)
	_prev_outer_scan_position = global_position


func _rescan_inner() -> void:
	for chunk: WorldSpaceChunk in _outer_chunks:
		if chunk.intersects(_inner_shape, global_transform):
			chunk.try_activate()
		else:
			chunk.try_deactivate()
	
	_prev_inner_scan_position = global_position
