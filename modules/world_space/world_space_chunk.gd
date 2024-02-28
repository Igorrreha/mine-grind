class_name WorldSpaceChunk
extends Resource


static var _items_by_id: Dictionary#[int, WorldSpaceChunk]

var id: int:
	set(v):
		_items_by_id.erase(v)
		id = v
		_items_by_id[id] = self

var rect: Rect2i
var map: WorldSpaceChunkMap:
	set(v):
		if v:
			map = v
			map_id = map.id
var map_id: int

var _is_dirty: bool


#region Static methods
static func save(chunk: WorldSpaceChunk) -> void:
	var path = _get_save_path(chunk.id)
	FileAccess\
		.open(path, FileAccess.WRITE)\
		.store_var({
			"id": chunk.id,
			"rect": chunk.rect,
			"map_id": chunk.map_id,
		})


static func load_from_save(id: int) -> WorldSpaceChunk:
	var save = FileAccess\
		.open(_get_save_path(id), FileAccess.READ)\
		.get_var(true)
	
	var loaded_object = WorldSpaceChunk.new()
	loaded_object.id = save.id
	loaded_object.rect = save.rect
	loaded_object.map_id = save.map_id
	
	return loaded_object


static func _get_save_path(id: int) -> String:
	return "user://world_space/chunk/%s" % id
#endregion


func _init() -> void:
	id = randi()


func activate() -> void:
	if not _is_active():
		load_content()


func load_content() -> void:
	map = WorldSpaceChunkMap.load_from_save(map_id)


func _is_active() -> bool:
	return map != null
