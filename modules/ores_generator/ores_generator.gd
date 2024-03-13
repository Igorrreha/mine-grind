class_name OresGenerator
extends Node


@export var _world_space: WorldSpace
@export var _chunk_type: WorldSpaceChunkType
@export var _surface_chunk_type: WorldSpaceChunkType
@export var _rock_region: WorldSpaceChunkMapRegion
@export var _grid_size: Vector2i

@export_group("Regions")
@export var _regions: Array[WorldSpaceChunkMapRegion]
@export var _regions_distribution: Curve


func generate_chunks_rect(rect: Rect2) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			generate_at(Vector2i(x, y) * _grid_size)


func generate_at(point: Vector2i) -> void:
	if _world_space.has_chunk_of_type_at(_chunk_type, point):
		return
	
	var new_chunk = WorldSpaceChunk.new()
	new_chunk.rect = Rect2i((point / _grid_size) * _grid_size, _grid_size)
	new_chunk.map = _generate_map(new_chunk.rect)
	
	_world_space.append_chunk(new_chunk, _chunk_type)


func _generate_map(rect: Rect2i) -> WorldSpaceChunkMap:
	var map := WorldSpaceChunkMap.create(rect.size, _regions)
	
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var world_point = Vector2i(x, y)
			var rich = _world_space.get_prop_value_at("rich", world_point)
			
			var surface_region := _world_space.get_chunk_region_at(_surface_chunk_type, world_point)
			
			var region_idx = floori(_regions_distribution.sample_baked(rich))\
				if surface_region == _rock_region else 0
			
			map.set_region_at(_regions[region_idx], world_point - rect.position)
	
	return map
