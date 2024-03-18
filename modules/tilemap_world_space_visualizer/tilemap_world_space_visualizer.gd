class_name TileMapWorldSpaceVisualizer
extends TileMap


@export var _active: bool = true

@export var _world_space: WorldSpace
@export var _tile_props_by_region: Dictionary#[WorldSpaceChunkMapRegion, RegionTileProps]
@export var _displayed_chunk_types: Array[WorldSpaceChunkType]


var _chunk_operations_queue: Array[Callable]
var _current_task_id: int = -1


func _ready() -> void:
	if not _active:
		queue_free()
		return
	
	_world_space.chunk_activated.connect(_register_show_chunk_operation)
	_world_space.chunk_deactivated.connect(_register_hide_chunk_operation)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			visible = !visible


func _process(_delta: float) -> void:
	if not _chunk_operations_queue.is_empty()\
	and (_current_task_id == -1 or WorkerThreadPool.is_task_completed(_current_task_id)):
		_current_task_id = WorkerThreadPool.add_task(_chunk_operations_queue.pop_front())


func _mouse_to_tile_position() -> Vector2i:
	var mouse_pos = get_viewport().get_mouse_position()
	var view_offset = get_canvas_transform().origin
	var tile_pos = local_to_map(to_local(mouse_pos - view_offset))
	return tile_pos


func _register_show_chunk_operation(chunk: WorldSpaceChunk,
		chunk_type: WorldSpaceChunkType) -> void:
	if not _displayed_chunk_types.has(chunk_type):
		return
	
	_chunk_operations_queue.append(_show_chunk.bind(chunk, chunk_type))


func _register_hide_chunk_operation(chunk: WorldSpaceChunk,
		chunk_type: WorldSpaceChunkType) -> void:
	if not _displayed_chunk_types.has(chunk_type):
		return
	
	_chunk_operations_queue.append(_hide_chunk.bind(chunk, chunk_type))


func _show_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	if not chunk.is_active:
		return
	
	var layer_idx = _displayed_chunk_types.find(chunk_type)
	var terrain_members: Dictionary
	
	for x in range(chunk.rect.position.x, chunk.rect.end.x):
		for y in range(chunk.rect.position.y, chunk.rect.end.y):
			var tile_position = Vector2i(x, y)
			var region = chunk.map.get_region_at(tile_position - chunk.rect.position)
			
			if not _tile_props_by_region.has(region):
				continue
			
			var tile_props = _tile_props_by_region[region] as RegionTileProps
			
			if tile_props.is_terrain:
				if not terrain_members.has(tile_props.terrain_id):
					terrain_members[tile_props.terrain_id] = []
				
				terrain_members[tile_props.terrain_id].append(tile_position)
			else:
				set_cell(layer_idx, tile_position,
					tile_props.atlas_id,
					tile_props.tile_coords)
	
	for terrain_set_id in terrain_members:
		var tiles_to_connect = terrain_members[terrain_set_id]
		set_cells_terrain_connect(layer_idx,
			tiles_to_connect, 0, terrain_set_id, false)


func _is_tile_in_terrain(point: Vector2i, terrain_id: int, terrain_set_id: int,
		layer_idx: int) -> bool:
	var tile_data = get_cell_tile_data(layer_idx, point)
	
	return tile_data\
		and tile_data.terrain == terrain_id\
		and tile_data.terrain_set == terrain_set_id


func _hide_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	var layer_idx = _displayed_chunk_types.find(chunk_type)
	
	for x in range(chunk.rect.position.x, chunk.rect.end.x):
		for y in range(chunk.rect.position.y, chunk.rect.end.y):
			var tile_position = Vector2i(x, y)
			erase_cell(layer_idx, tile_position)
