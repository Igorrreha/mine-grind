@tool

class_name WorldSpace
extends Resource


signal chunk_appended(chunk: WorldSpaceChunk, type: WorldSpaceChunkType)

signal chunk_activated(chunk: WorldSpaceChunk, type: WorldSpaceChunkType)
signal chunk_deactivated(chunk: WorldSpaceChunk, type: WorldSpaceChunkType)


@export var _props: Dictionary#[String, WorldSpaceProp]
@export var _infinite: bool:
	set(v):
		_infinite = v
		notify_property_list_changed()

var _chunks: Dictionary#[WorldSpaceChunkType, Array[WorldSpaceChunk]]
var _boundaries: Rect2i
var _class_items_collection: ClassItemsCollection


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
	pass


func get_prop_value_at(prop_name: StringName, point: Vector2i) -> Variant:
	if not contains_point(point):
		push_error("Point %s is not in world space" % point)
		return null
	
	return (_props[prop_name] as WorldSpaceProp).get_value_at(point)


func contains_point(point: Vector2i) -> bool:
	return _infinite or _boundaries.has_point(point)


func append_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	if not _chunks.has(chunk_type):
		var chunks_array: Array[WorldSpaceChunk]
		_chunks[chunk_type] = chunks_array
	
	(_chunks[chunk_type] as Array[WorldSpaceChunk]).append(chunk)
	chunk_appended.emit(chunk, chunk_type)
	chunk_activated.emit(chunk, chunk_type)


func has_chunk_of_type_at(chunk_type: WorldSpaceChunkType, point: Vector2i) -> bool:
	if not _chunks.has(chunk_type):
		return false
	
	for chunk: WorldSpaceChunk in _chunks[chunk_type]:
		if chunk.rect.has_point(point):
			return true
	
	return false
