@tool
extends EditorScript


func _run() -> void:
	var tileset = load("res://modules/test/test_tileset.tres") as TileSet
	var new_source_texture = load("res://modules/test/blue_dirt_tiles_256.png")
	
	var terrain_set_id = 0
	var terrain_id = 1
	
	var custom_data = {
		"has_center_bit": true,
	}
	
	var valid_neighbors = [
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	]
	
	var new_source = TileSetAtlasSource.new()
	new_source.texture = new_source_texture
	new_source.texture_region_size = Vector2i(16, 16)
	tileset.add_source(new_source)
	
	var texture_grid_size = Vector2i(32, 8)
	var tile_size = Vector2i.ONE
	
	for y in range(texture_grid_size.y):
		for x in range(texture_grid_size.x):
			var tile_coords = Vector2i(x, y)
			var tile_idx = y * texture_grid_size.x + x
			new_source.create_tile(tile_coords, tile_size)
			
			var tile_data = new_source.get_tile_data(tile_coords, 0)
			tile_data.terrain_set = terrain_set_id
			tile_data.terrain = terrain_id
			
			for key in custom_data:
				tile_data.set_custom_data(key, custom_data[key])
			
			for neighbor_idx in range(valid_neighbors.size()):
				if not tile_idx & (1 << neighbor_idx):
					continue
				
				tile_data.set_terrain_peering_bit(valid_neighbors[neighbor_idx],
					terrain_id)
