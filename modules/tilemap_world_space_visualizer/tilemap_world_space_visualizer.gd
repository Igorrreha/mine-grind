class_name TileMapWorldSpaceVisualizer
extends OptimizedFor9SidesTileMap


@export var _active: bool = true

@export var _world_space: WorldSpace
@export var _tile_props_by_region: Dictionary#[WorldSpaceChunkMapRegion, RegionTileProps]
@export var _layer_by_region: Dictionary#[WorldSpaceChunkMapRegion, int]
@export var _displayed_chunk_types: Array[WorldSpaceChunkType]


func _ready() -> void:
	if not _active:
		queue_free()
		return
	
	super._ready()
	
	_world_space.chunk_activated.connect(_register_show_chunk_operation)
	_world_space.chunk_deactivated.connect(_register_hide_chunk_operation)


func _register_show_chunk_operation(chunk: WorldSpaceChunk,
		chunk_type: WorldSpaceChunkType) -> void:
	if not _displayed_chunk_types.has(chunk_type):
		return
	
	GlobalCoroutine.add_operation(_show_chunk.bind(chunk, chunk_type))


func _register_hide_chunk_operation(chunk: WorldSpaceChunk,
		chunk_type: WorldSpaceChunkType) -> void:
	if not _displayed_chunk_types.has(chunk_type):
		return
	
	GlobalCoroutine.add_operation(_hide_chunk.bind(chunk, chunk_type))


func _show_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	if not chunk.is_active:
		return
	
	var terrain_members: Dictionary#[Region, Array[Vector2]]
	
	var y_range = range(chunk.rect.position.y, chunk.rect.end.y)
	for x in range(chunk.rect.position.x, chunk.rect.end.x):
		for y in y_range:
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
				_set_cell_async(layer_idx, tile_position,
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
			
			_set_cell_async(layer_idx, tile_coords, tile_props.atlas_id,
				atlas_coords)
	
	
#region Shitcode
	for x: int in range(chunk.rect.size.x):
		for y: int in [0, chunk.rect.size.y - 1]:
			var tile_local_position = Vector2i(x, y)
			var tile_region = chunk.map\
				.get_region_at(tile_local_position) as WorldSpaceChunkMapRegion
			var layer_idx = _layer_by_region[tile_region]
			var tile_props = _tile_props_by_region[tile_region] as RegionTileProps
			var tile_coords = chunk.rect.position + tile_local_position
			
			_fix_tile_async(tile_coords, layer_idx, tile_props.atlas_id,
				tile_props.terrain_set_id, tile_props.terrain_id, true)
	
	for y: int in range(chunk.rect.size.y):
		for x: int in [0, chunk.rect.size.x - 1]:
			var tile_local_position = Vector2i(x, y)
			var tile_region = chunk.map\
				.get_region_at(tile_local_position) as WorldSpaceChunkMapRegion
			var layer_idx = _layer_by_region[tile_region]
			var tile_props = _tile_props_by_region[tile_region] as RegionTileProps
			var tile_coords = chunk.rect.position + tile_local_position
			
			_fix_tile_async(tile_coords, layer_idx, tile_props.atlas_id,
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


func _fix_tile(tile_coords: Vector2i, layer: int, source_id: int,
		terrain_set_id: int, terrain_id: int,
		update_neighbors: bool = false, with_center_bit: bool = true) -> void:
	var tile_data = get_cell_tile_data(layer, tile_coords)
	if not tile_data or tile_data.terrain == -1:
		return
	
	draw_tile(tile_coords, layer, source_id,
		terrain_set_id, terrain_id,
		update_neighbors, with_center_bit
	)


func _set_cell_async(layer: int, coords: Vector2i, source_id: int,
		atlas_coords: Vector2i) -> void:
	GlobalCoroutine.add_operation(set_cell.bind(
		layer, coords, source_id, atlas_coords
	))


func _fix_tile_async(tile_coords: Vector2i, layer: int, source_id: int,
		terrain_set_id: int, terrain_id: int,
		update_neighbors: bool = false, with_center_bit: bool = true):
	GlobalCoroutine.add_operation(_fix_tile.bind(
		tile_coords, layer, source_id,
		terrain_set_id, terrain_id,
		update_neighbors, with_center_bit
	))
