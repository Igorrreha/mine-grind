class_name SurfaceGenerator
extends Node


@export var _world_space: WorldSpace
@export var _chunk_type: WorldSpaceChunkType
@export var _grid_size: Vector2i

@export_group("Regions")
@export var _regions: Array[WorldSpaceChunkMapRegion]
@export var _regions_distribution: Curve


func generate_at(point: Vector2i) -> void:
	if _world_space.has_chunk_of_type_at(_chunk_type, point):
		return
	
	var new_chunk = WorldSpaceChunk.new()
	new_chunk.rect = Rect2i((point / _grid_size) * _grid_size, _grid_size)
	new_chunk.map = generate_map(new_chunk.rect)
	
	_world_space.append_chunk(new_chunk, _chunk_type)


func generate_map(rect: Rect2i) -> WorldSpaceChunkMap:
	var map := WorldSpaceChunkMap.create(rect.size, _regions)
	var image_data: PackedByteArray
	
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var world_point = Vector2i(x, y)
			var height = _world_space.get_prop_value_at("height", world_point)
			var region_idx = floori(_regions_distribution.sample_baked(height))
			
			map.set_region_at(_regions[region_idx], world_point - rect.position)
	
	return map
