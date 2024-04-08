class_name TileMapWorldSpaceVisualizer
extends OptimizedFor9SidesTileMap


@export var _active: bool = true

@export var _world_space: WorldSpace
@export var _tile_props_by_region: Dictionary#[WorldSpaceChunkMapRegion, RegionTileProps]
@export var _layer_by_region: Dictionary#[WorldSpaceChunkMapRegion, int]
@export var _displayed_chunk_types: Array[WorldSpaceChunkType]


var _chunk_operations_queue: Array[Callable]
var _current_task_id: int = -1
var _task_in_process: bool
var _async_chunk_operations: bool = false
var _max_tiles_per_frame: int = 100


func _ready() -> void:
	if not _active:
		queue_free()
		return
	
	super._ready()
	
	_world_space.chunk_activated.connect(_register_show_chunk_operation)
	_world_space.chunk_deactivated.connect(_register_hide_chunk_operation)


func _process(_delta: float) -> void:
	if _task_in_process and WorkerThreadPool.is_task_completed(_current_task_id):
		_current_task_id = -1
		
		# Dumb but cheap fix
		rendering_quadrant_size = 16 if rendering_quadrant_size == 17 else 17
		
		_task_in_process = false

	if not _task_in_process\
	and not _chunk_operations_queue.is_empty():
		_current_task_id = WorkerThreadPool.add_task(_chunk_operations_queue.pop_front())
		_task_in_process = true


func _mouse_to_tile_position() -> Vector2i:
	var mouse_pos = get_viewport().get_mouse_position()
	var view_offset = get_canvas_transform().origin
	var tile_pos = local_to_map(to_local(mouse_pos - view_offset))
	return tile_pos


func _register_show_chunk_operation(chunk: WorldSpaceChunk,
		chunk_type: WorldSpaceChunkType) -> void:
	if not _displayed_chunk_types.has(chunk_type):
		return
	
	var operation = _show_chunk.bind(chunk, chunk_type)
	if _async_chunk_operations:
		_chunk_operations_queue.append(operation)
	else:
		operation.call()


func _register_hide_chunk_operation(chunk: WorldSpaceChunk,
		chunk_type: WorldSpaceChunkType) -> void:
	if not _displayed_chunk_types.has(chunk_type):
		return
	
	var operation = _hide_chunk.bind(chunk, chunk_type)
	if _async_chunk_operations:
		_chunk_operations_queue.append(operation)
	else:
		operation.call()


func _show_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	if not chunk.is_active:
		return
	
	var terrain_members: Dictionary#[Region, Array[Vector2]]
	
	for x in range(chunk.rect.position.x, chunk.rect.end.x):
		for y in range(chunk.rect.position.y, chunk.rect.end.y):
			var tile_position = Vector2i(x, y)
			
			if not chunk.is_active:
				return
			
			var region = chunk.map\
				.get_region_at(tile_position - chunk.rect.position)
			
			if not _tile_props_by_region.has(region)\
			or not _layer_by_region.has(region):
				continue
			
			var tile_props = _tile_props_by_region[region] as RegionTileProps
			
			if tile_props.is_terrain:
				if not terrain_members.has(region):
					terrain_members[region] = []
				
				terrain_members[region].append(tile_position)
			else:
				var layer_idx = _layer_by_region[region] as int
				set_cell(layer_idx, tile_position,
					tile_props.atlas_id,
					tile_props.tile_coords)
	
	if not chunk.is_active:
		return
	
	var tiles_by_layer: Dictionary#[int, Array[Vector2i]]
	for region in terrain_members:
		var layer_idx = _layer_by_region[region]
		if not tiles_by_layer.has(layer_idx):
			var new_array: Array[Vector2i]
			tiles_by_layer[layer_idx] = new_array
		
		tiles_by_layer[layer_idx].append_array(terrain_members[region])
	
	var bitmasks_by_layer: Dictionary#[int, Dictionary[Vector2i, int]]
	for layer_idx in tiles_by_layer:
		bitmasks_by_layer[layer_idx] = get_bitmasks(tiles_by_layer[layer_idx])
	
	for region: WorldSpaceChunkMapRegion in terrain_members:
		var tile_props = _tile_props_by_region[region] as RegionTileProps
		var layer_idx = _layer_by_region[region]
		var bitmasks = bitmasks_by_layer[layer_idx]
		
		for tile_coords in terrain_members[region]:
			var bitmask = bitmasks[tile_coords]
			var atlas_coords = _get_best_fit(bitmask, tile_props.terrain_set_id,
				tile_props.terrain_id)
			
			set_cell(layer_idx, tile_coords, tile_props.atlas_id, atlas_coords)
	
	
#region Shitcode
	for x in range(chunk.rect.size.x):
		for y in [0, chunk.rect.size.y - 1]:
			var tile_local_position = Vector2i(x, y)
			var tile_region = chunk.map\
				.get_region_at(tile_local_position) as WorldSpaceChunkMapRegion
			var layer_idx = _layer_by_region[tile_region]
			var tile_props = _tile_props_by_region[tile_region] as RegionTileProps
			var tile_coords = chunk.rect.position + tile_local_position
			
			var tile_data = get_cell_tile_data(layer_idx, tile_coords)
			if not tile_data or tile_data.terrain == -1:
				continue
			
			draw_tile(tile_coords, layer_idx, tile_props.atlas_id,
				tile_props.terrain_set_id, tile_props.terrain_id, true)
	
	for y in range(chunk.rect.size.y):
		for x in [0, chunk.rect.size.x - 1]:
			var tile_local_position = Vector2i(x, y)
			var tile_region = chunk.map\
				.get_region_at(tile_local_position) as WorldSpaceChunkMapRegion
			var layer_idx = _layer_by_region[tile_region]
			var tile_props = _tile_props_by_region[tile_region] as RegionTileProps
			var tile_coords = chunk.rect.position + tile_local_position
			
			var tile_data = get_cell_tile_data(layer_idx, tile_coords)
			if not tile_data or tile_data.terrain == -1:
				continue
			
			draw_tile(tile_coords, layer_idx, tile_props.atlas_id,
				tile_props.terrain_set_id, tile_props.terrain_id, true)
#endregion


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
