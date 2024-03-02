@tool

class_name WorldSpace
extends Resource


signal chunk_appended(chunk: WorldSpaceChunk, type: WorldSpaceChunkType)

signal chunk_activated(chunk: WorldSpaceChunk, type: WorldSpaceChunkType)
signal chunk_deactivated(chunk: WorldSpaceChunk, type: WorldSpaceChunkType)


static var _items_by_id: Dictionary#[int, WorldSpace]

@export var _props: Dictionary#[String, WorldSpaceProp]
@export var _infinite: bool:
	set(v):
		_infinite = v
		notify_property_list_changed()

var id: int:
	set(v):
		_items_by_id.erase(v)
		id = v
		_items_by_id[id] = self

var _chunks_by_type: Dictionary#[WorldSpaceChunkType, Array[WorldSpaceChunk]]
var _chunks_by_type_ids: Dictionary#[int, Array[int]]
var _boundaries: Rect2i 

var _is_dirty: bool


#region Static methods
static func save(space: WorldSpace) -> void:
	for chunk_type in space._chunks_by_type:
		WorldSpaceChunkType.save(chunk_type)
		
		for chunk in space._chunks_by_type[chunk_type]:
			WorldSpaceChunk.save(chunk)
	
	if space._is_dirty:
		var save_path = _get_save_path(space.id)
		var save_dir_path = save_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(save_dir_path):
			DirAccess.make_dir_recursive_absolute(save_dir_path)
		
		FileAccess.open(save_path, FileAccess.WRITE).store_var({
			"id": space.id,
			"boundaries": space._boundaries,
			"chunks_by_type_ids": space._chunks_by_type_ids,
		})


static func load_from_save(object_id: int) -> WorldSpace:
	if _items_by_id.has(object_id):
		return _items_by_id[object_id]
	
	var save_data = FileAccess\
		.open(_get_save_path(object_id), FileAccess.READ)\
		.get_var(true)
	
	var loaded_object = WorldSpace.new()
	loaded_object.id = save_data.id
	loaded_object._chunks_by_type_ids = save_data.chunks_by_type_ids
	loaded_object._boundaries = save_data.boundaries
	
	return loaded_object


static func _get_save_path(object_id: int) -> String:
	return "user://world_space/%s" % object_id
#endregion


func _get_property_list() -> Array[Dictionary]:
	# By default, `_boundaries` is not visible in the editor.
	var property_usage = PROPERTY_USAGE_NO_EDITOR
	
	if not _infinite:
		property_usage = PROPERTY_USAGE_DEFAULT

	var properties: Array[Dictionary]
	properties.append({
		"name": "_boundaries",
		"type": TYPE_RECT2I,
		"usage": property_usage,
	})

	return properties


func _init() -> void:
	id = randi()


func load_content() -> void:
	for chunk_type_id in _chunks_by_type_ids:
		var chunks: Array[WorldSpaceChunk]
		_chunks_by_type[WorldSpaceChunkType.load_from_save(chunk_type_id)] = chunks
		
		for chunk_id in _chunks_by_type_ids:
			chunks.append(WorldSpaceChunk.load_from_save(chunk_id))


func get_prop_value_at(prop_name: StringName, point: Vector2i) -> Variant:
	if not contains_point(point):
		push_error("Point %s is not in world space" % point)
		return null
	
	return (_props[prop_name] as WorldSpaceProp).get_value_at(point)


func contains_point(point: Vector2i) -> bool:
	return _infinite or _boundaries.has_point(point)


func append_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	if not _chunks_by_type_ids.has(chunk_type.id):
		var chunks: Array[WorldSpaceChunk]
		_chunks_by_type[chunk_type] = chunks
		var ids: Array[int]
		_chunks_by_type_ids[chunk_type.id] = ids
	
	(_chunks_by_type[chunk_type] as Array[WorldSpaceChunk]).append(chunk)
	(_chunks_by_type_ids[chunk_type.id] as Array[int]).append(chunk.id)
	
	chunk_appended.emit(chunk, chunk_type)
	chunk_activated.emit(chunk, chunk_type)


func has_chunk_of_type_at(chunk_type: WorldSpaceChunkType, point: Vector2i) -> bool:
	if not _chunks_by_type.has(chunk_type):
		return false
	
	for chunk: WorldSpaceChunk in _chunks_by_type[chunk_type]:
		if chunk.rect.has_point(point):
			return true
	
	return false


func activate_chunks_at(point: Vector2i) -> void:
	for chunk_type in _chunks_by_type:
		for chunk: WorldSpaceChunk in _chunks_by_type[chunk_type]:
			if chunk.rect.has_point(point)\
			and chunk.try_activate():
				chunk_activated.emit(chunk, chunk_type)


func deactivate_chunks_at(point: Vector2i) -> void:
	for chunk_type in _chunks_by_type:
		for chunk: WorldSpaceChunk in _chunks_by_type[chunk_type]:
			if chunk.rect.has_point(point)\
			and chunk.try_deactivate():
				chunk_deactivated.emit(chunk, chunk_type)


func activate_chunks_intersects(rect: Rect2i) -> void:
	for chunk_type in _chunks_by_type:
		for chunk: WorldSpaceChunk in _chunks_by_type[chunk_type]:
			if chunk.rect.intersects(rect)\
			and chunk.try_activate():
				chunk_activated.emit(chunk, chunk_type)


func deactivate_chunks_intersects(rect: Rect2i) -> void:
	for chunk_type in _chunks_by_type:
		for chunk: WorldSpaceChunk in _chunks_by_type[chunk_type]:
			if chunk.rect.intersects(rect)\
			and chunk.try_deactivate():
				chunk_deactivated.emit(chunk, chunk_type)
