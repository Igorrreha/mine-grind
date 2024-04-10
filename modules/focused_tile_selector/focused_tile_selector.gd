class_name FocusedTileSelector
extends Node2D


signal focused_tile_chaged(tile_coords: Vector2i)


@export var _tilemap: TileMap

var _focused_tile_coords: Vector2i

@onready var _tile_size := _tilemap.tile_set.tile_size


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var current_focused_tile_coords = _get_focused_tile_coords()
		if current_focused_tile_coords == _focused_tile_coords:
			return
		
		_focused_tile_coords = current_focused_tile_coords
		focused_tile_chaged.emit(_focused_tile_coords)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(_focused_tile_coords * _tile_size
		+ Vector2i(_tilemap.position), _tile_size), Color.RED)


func _get_focused_tile_coords() -> Vector2i:
	var mouse_pos = get_viewport().get_mouse_position()
	var view_offset = _tilemap.get_canvas_transform().origin
	var tile_pos = _tilemap.local_to_map(_tilemap.to_local(mouse_pos - view_offset))
	return tile_pos
