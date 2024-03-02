class_name TileMapWorldSpaceVisualizer
extends TileMap


@export var _world_space: WorldSpace
@export var _tile_props_by_region: Dictionary#[WorldSpaceChunkMapRegion, RegionTileProps]
@export var _displayed_chunk_types: Array[WorldSpaceChunkType]


func _ready() -> void:
	_world_space.chunk_activated.connect(_show_chunk)
	_world_space.chunk_deactivated.connect(_hide_chunk)


func _show_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	if not _displayed_chunk_types.has(chunk_type):
		return
	
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
				set_cell(0, tile_position,
					tile_props.atlas_id,
					tile_props.tile_coords)
	
	for terrain_set_id in terrain_members:
		var tiles_to_connect = terrain_members[terrain_set_id]
		
#region Fix chunk connections
		for x in range(chunk.rect.position.x, chunk.rect.end.x):
			var top_tile_position = Vector2i(x, chunk.rect.position.y - 1)
			if _is_tile_in_terrain(top_tile_position, 0, terrain_set_id):
				tiles_to_connect.append(top_tile_position)
			
			var bottom_tile_position = Vector2i(x, chunk.rect.end.y + 1)
			if _is_tile_in_terrain(bottom_tile_position, 0, terrain_set_id):
				tiles_to_connect.append(bottom_tile_position)
		
		for y in range(chunk.rect.position.y - 1, chunk.rect.end.y + 1):
			var left_tile_position = Vector2i(chunk.rect.position.x - 1, y)
			if _is_tile_in_terrain(left_tile_position, 0, terrain_set_id):
				tiles_to_connect.append(left_tile_position)
			
			var right_tile_position = Vector2i(chunk.rect.position.x + 1, y)
			if _is_tile_in_terrain(right_tile_position, 0, terrain_set_id):
				tiles_to_connect.append(right_tile_position)
#endregion
		
		set_cells_terrain_connect(0, tiles_to_connect, 0, terrain_set_id)


func _is_tile_in_terrain(point: Vector2i, terrain_id: int, terrain_set_id: int) -> bool:
	var tile_data = get_cell_tile_data(0, point)
	
	return tile_data\
		and tile_data.terrain == terrain_id\
		and tile_data.terrain_set == terrain_set_id


func _hide_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	if not _displayed_chunk_types.has(chunk_type):
		return
	
	for x in range(chunk.rect.position.x, chunk.rect.end.x):
		for y in range(chunk.rect.position.y, chunk.rect.end.y):
			var tile_position = Vector2i(x, y)
			erase_cell(0, tile_position)
