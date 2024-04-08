class_name OptimizedFor9SidesTileMap
extends TileMap


var _tiles: Dictionary
var _best_fit_cache: Dictionary

var _has_center_bit_layer_name: StringName = "has_center_bit"


@onready var _valid_neighbors: Array[TileSet.CellNeighbor]\
	= _get_valid_neighbors()
@onready var _valid_neighbors_without_center: Array[TileSet.CellNeighbor]\
	= _get_valid_neighbors_without_center()
@onready var _position_from_neighbors: Dictionary\
	= _get_position_from_neighbors(_valid_neighbors)


func _ready() -> void:
	_init_tiles()


func draw_tile(tile_coords: Vector2i, layer: int, source_id: int,
		terrain_set_id: int, terrain_id: int,
		update_neighbors: bool = false, with_center_bit: bool = true) -> void:
	var bitmask: int = _get_bitmask(tile_coords, with_center_bit, layer,
		terrain_set_id, terrain_id)
	
	var tile: Vector2i 
	if with_center_bit:
		tile = _get_best_fit(bitmask, terrain_set_id, terrain_id)
	else:
		var tiles_pack: TilesPack = _tiles[terrain_set_id][terrain_id]
		if not tiles_pack.without_center_bit.has(bitmask):
			erase_cell(layer, tile_coords)
			return
		
		tile = tiles_pack.without_center_bit[bitmask]
	
	set_cell(layer, tile_coords, source_id, tile)
	
	if not update_neighbors:
		return
	
	update_neighbors(tile_coords, layer, source_id, terrain_set_id, terrain_id)


func erase_tile(tile_coords: Vector2i, layer: int, source_id: int,
		terrain_set_id: int, terrain_id: int,
		update_neighbors: bool = false) -> void:
	var tile_data = get_cell_tile_data(layer, tile_coords)
	if not tile_data:
		return
	
	var has_center_bit = tile_data.get_custom_data(_has_center_bit_layer_name)
	if not has_center_bit:
		return
	
	erase_cell(layer, tile_coords)
	
	if has_center_bit:
		draw_tile(tile_coords, layer, source_id, terrain_set_id, terrain_id, false, false)
	
	if not update_neighbors:
		return
	
	update_neighbors(tile_coords, layer, source_id, terrain_set_id, terrain_id)


func draw_tiles(tiles_coords: Array[Vector2i], layer: int, source_id: int,
		terrain_set_id: int, terrain_id: int) -> void:
	var border_tiles: Array[Vector2i]
	for tile_coords in tiles_coords:
		set_cell(layer, tile_coords, source_id,
			_tiles[terrain_set_id][terrain_id].with_center_bit[0])
		
		var neighbors = _valid_neighbors.map(func(neighbor_type: TileSet.CellNeighbor):
				return get_neighbor_cell(tile_coords, neighbor_type))
		
		if neighbors.any(func(neighbor: Vector2i):
				return not tiles_coords.has(neighbor)):
			border_tiles.append(tile_coords)
	
	for tile_coords in tiles_coords:
		draw_tile(tile_coords, layer, source_id, terrain_set_id, terrain_id,
			border_tiles.has(tile_coords))


func update_neighbors(tile_coords: Vector2i, layer: int, source_id: int,
		terrain_set_id: int, terrain_id: int) -> void:
	for neighbor_position in _valid_neighbors:
		if _has_neighbor(tile_coords, neighbor_position, layer):
			draw_tile(get_neighbor_cell(tile_coords, neighbor_position), layer,
				source_id, terrain_set_id, terrain_id)
		else:
			draw_tile(get_neighbor_cell(tile_coords, neighbor_position), layer,
				source_id, terrain_set_id, terrain_id, false, false)


func get_bitmasks(tiles_coords: Array[Vector2i]) -> Dictionary:
	var bitmask_by_tile_coords: Dictionary
	for tile_coords: Vector2i in tiles_coords:
		bitmask_by_tile_coords[tile_coords] = 0
	
	var bit_idxs = range(_valid_neighbors.size())
	for tile_coords: Vector2i in tiles_coords:
		for bit_idx: int in bit_idxs:
			var neighbor_type := _valid_neighbors[bit_idx]
			var neighbor_coords: Vector2i =\
				_position_from_neighbors[neighbor_type] + tile_coords
			if not neighbor_coords in bitmask_by_tile_coords:
				continue
			
			bitmask_by_tile_coords[neighbor_coords] |= 1 << bit_idx
	
	return bitmask_by_tile_coords


func _get_brush_pattern(offset: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i]
	
	var radius = 3
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if sqrt(pow(x, 2) + pow(y, 2)) <= radius:
				points.append(Vector2i(x, y) + offset)
	
	return points


func _init_tiles() -> void:
	_tiles.clear()
	_best_fit_cache.clear()
	
	for source_idx in range(tile_set.get_source_count()):
		var source_id := tile_set.get_source_id(source_idx)
		
		for terrain_set_id in range(tile_set.get_terrain_sets_count()):
			if not terrain_set_id in _tiles:
				_tiles[terrain_set_id] = {}
				_best_fit_cache[terrain_set_id] = {}
			
			for terrain_id in range(tile_set.get_terrains_count(terrain_set_id)):
				var tiles_pack = _get_tiles_pack(source_id, terrain_set_id,
					terrain_id)
				
				if tiles_pack.is_empty():
					continue
				
				_tiles[terrain_set_id][terrain_id] = tiles_pack
				_best_fit_cache[terrain_set_id][terrain_id] = tiles_pack.duplicate()


func _get_tiles_pack(source_id: int, terrain_set_id: int,
		terrain_id: int) -> TilesPack:
	var tiles_pack := TilesPack.new()
	
	var source := tile_set.get_source(source_id) as TileSetAtlasSource
	var grid_size = source.get_atlas_grid_size()
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var tile_position = Vector2i(x, y)
			
			if not source.has_tile(tile_position):
				continue
			
			var tile_data = source.get_tile_data(tile_position, 0)
			
			if tile_data.terrain_set != terrain_set_id\
			or tile_data.terrain != terrain_id:
				continue
			
			var has_center_bit = tile_data.get_custom_data(_has_center_bit_layer_name)
			var valid_neighbors = _valid_neighbors if has_center_bit\
				else _valid_neighbors_without_center
			
			var bitmask = 0
			for bit_idx in range(valid_neighbors.size()):
				var peering_bit = tile_data\
					.get_terrain_peering_bit(valid_neighbors[bit_idx])
				if peering_bit > -1:
					bitmask |= 1 << bit_idx
			
			if has_center_bit: 
				tiles_pack.with_center_bit[bitmask] = tile_position
			else:
				tiles_pack.without_center_bit[bitmask] = tile_position
	
	return tiles_pack


func _get_best_fit(search_bitmask: int, terrain_set_id: int,
		terrain_id: int, with_center_bit: bool = true) -> Vector2i:
	var cache_tiles_pack: TilesPack = _best_fit_cache[terrain_set_id][terrain_id]
	var cache = cache_tiles_pack.with_center_bit if with_center_bit\
		else cache_tiles_pack.without_center_bit
	
	if cache.has(search_bitmask):
		return cache[search_bitmask]
	
	var tiles_pack: TilesPack = _tiles[terrain_set_id][terrain_id]
	var tiles = tiles_pack.with_center_bit if with_center_bit\
		else tiles_pack.without_center_bit
	
	if tiles_pack.with_center_bit.has(search_bitmask):
		var best_fit_tile = tiles[search_bitmask]
		cache[search_bitmask] = best_fit_tile
		return best_fit_tile
	
	#for iteration_idx in range(2):
		#var use_overconnected = iteration_idx != 0
	for depth in range(1, _valid_neighbors.size() + 1):
		var start_positions = range(depth)
		var target_positions = start_positions.map(func(x):
			return _valid_neighbors.size() - x - 1)
		var delta = _valid_neighbors.size() - depth + 1
		var shifts = start_positions.map(func(x):
			return 0)
		
		while shifts[0] < delta:
			var completed_shifts_idxs: Array
			for item_idx in range(depth - 1, -1, -1):
				if shifts[item_idx] < delta:
					shifts[item_idx] += 1
					break
				
				completed_shifts_idxs.append(item_idx)
			
			completed_shifts_idxs.reverse()
			
			for item_idx in completed_shifts_idxs:
				if not completed_shifts_idxs.has(item_idx - 1):
					shifts[item_idx - 1] += 1
				
				shifts[item_idx] = shifts[item_idx - 1] + 1
			
			var bits_to_invert: Array
			for shift_idx in range(shifts.size()):
				bits_to_invert.append(shifts[shift_idx] + shift_idx)
			
			#var skip_bitmask: bool
			#for bit_idx in bits_to_invert:
				#var search_mask_has_bit = search_bitmask & (1 << bit_idx)
				#if bool(search_mask_has_bit) != use_overconnected:
					#skip_bitmask = true
					#break
			#
			#if skip_bitmask:
				#continue
			
			var bitmask: int
			for bit_idx in range(_valid_neighbors.size()):
				var search_mask_has_bit = search_bitmask & (1 << bit_idx)
				if bits_to_invert.has(bit_idx):
					if not search_mask_has_bit:
						bitmask |= 1 << bit_idx
				
				elif search_mask_has_bit:
					bitmask |= 1 << bit_idx
			
			if tiles.has(bitmask):
				var best_fit_tile = tiles[bitmask]
				cache[bitmask] = best_fit_tile
				return best_fit_tile
	
	printerr("Can't find best fit for %s" % search_bitmask)
	return Vector2i.ZERO


func _get_valid_neighbors() -> Array[TileSet.CellNeighbor]:
	return [
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	]


func _get_valid_neighbors_without_center() -> Array[TileSet.CellNeighbor]:
	return [
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
	]


func _has_neighbor(tile_coords: Vector2i,
		neighbor_position: TileSet.CellNeighbor, layer: int) -> bool:
	var neighbor_coords = get_neighbor_cell(tile_coords, neighbor_position)
	var neighbor_data = get_cell_tile_data(layer, neighbor_coords)
	
	return neighbor_data\
		and neighbor_data.get_custom_data(_has_center_bit_layer_name)


func _get_bitmask(tile_coords: Vector2i, with_center_bit: bool,
		layer: int, terrain_set_id: int, terrain_id: int) -> int:
	var bitmask: int
	var valid_neighbors = _valid_neighbors if with_center_bit else _valid_neighbors_without_center
	for neighbor_position_idx in range(valid_neighbors.size()):
		if _has_neighbor(tile_coords, valid_neighbors[neighbor_position_idx],
				layer):
			bitmask |= 1 << neighbor_position_idx
	
	return bitmask


func _get_position_from_neighbors(
		neighbors: Array[TileSet.CellNeighbor]) -> Dictionary:
	var position_from_neighbors: Dictionary
	for neighbor_type in _valid_neighbors:
		var position_from_neighbor =\
			get_neighbor_cell(Vector2i.ZERO, neighbor_type)\
			* Vector2i(-1, -1)
		position_from_neighbors[neighbor_type] = position_from_neighbor
	return position_from_neighbors


class TilesPack:
	var with_center_bit: Dictionary#[int, Vector2i]
	var without_center_bit: Dictionary#[int, Vector2i]
	
	
	func duplicate() -> TilesPack:
		var duplicate = TilesPack.new()
		duplicate.with_center_bit = with_center_bit.duplicate()
		duplicate.without_center_bit = without_center_bit.duplicate()
		return duplicate
	
	
	func is_empty() -> bool:
		return with_center_bit.is_empty() and without_center_bit.is_empty()
