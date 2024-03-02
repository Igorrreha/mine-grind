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
			map_id = v.id
		
		map = v

var map_id: int


#region Static methods
static func save(chunk: WorldSpaceChunk) -> void:
	var save_path = _get_save_path(chunk.id)
	var save_dir_path = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(save_dir_path):
		DirAccess.make_dir_recursive_absolute(save_dir_path)
	
	FileAccess\
		.open(save_path, FileAccess.WRITE)\
		.store_var({
			"id": chunk.id,
			"rect": chunk.rect,
			"map_id": chunk.map_id,
		})


static func load_from_save(object_id: int) -> WorldSpaceChunk:
	if _items_by_id.has(object_id):
		return _items_by_id[object_id]
	
	var save_data = FileAccess\
		.open(_get_save_path(object_id), FileAccess.READ)\
		.get_var(true)
	
	var loaded_object = WorldSpaceChunk.new()
	loaded_object.id = save_data.id
	loaded_object.rect = save_data.rect
	loaded_object.map_id = save_data.map_id
	
	return loaded_object


static func _get_save_path(object_id: int) -> String:
	return "user://world_space/chunk/%s" % object_id
#endregion


func _init() -> void:
	id = randi()


func try_activate() -> bool:
	if map == null:
		load_content()
		return true
	
	return false


func try_deactivate() -> bool:
	if map == null:
		return false
	
	WorldSpaceChunkMap.save(map)
	map = null
	return true


func load_content() -> void:
	map = WorldSpaceChunkMap.load_from_save(map_id)
