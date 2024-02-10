class_name TileMapFromSpaceMapLoader
extends Node


@export var _tiles_props: Array[SpaceMapTileProps]
@export var _tilemap: TileMap

var _tile_props_by_space_map_region: Dictionary


func _ready() -> void:
	for tile_props in _tiles_props:
		_tile_props_by_space_map_region[tile_props.region_name] = tile_props


func load_map(space_map: SpaceMap) -> void:
	_tilemap.clear()
	for x in space_map.image.get_width():
		for y in space_map.image.get_height():
			var tile_position = Vector2i(x, y)
			var tile_props = get_tile_props(space_map, tile_position)
			_tilemap.set_cell(0, tile_position,
				tile_props.atlas_id,
				tile_props.atlas_coords)
			
			if tile_props.is_terrain:
				_tilemap.set_cells_terrain_connect(0, [tile_position], 0, 0)


func get_tile_props(space_map: SpaceMap, position: Vector2i) -> SpaceMapTileProps:
	var region_id = space_map.get_region_at(position.x, position.y).id
	return _tile_props_by_space_map_region[region_id]
