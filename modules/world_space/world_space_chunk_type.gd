class_name WorldSpaceChunkType
extends Resource


static var _items_by_id: Dictionary#[int, WorldSpaceChunkType]

var id: int:
	set(v):
		_items_by_id.erase(v)
		id = v
		_items_by_id[id] = self


#region Static methods
static func save(object_to_save: WorldSpaceChunkType) -> void:
	var save_path = _get_save_path(object_to_save.id)
	var save_dir_path = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(save_dir_path):
		DirAccess.make_dir_recursive_absolute(save_dir_path)
	
	FileAccess.open(save_path, FileAccess.WRITE).store_var({
		"id": object_to_save.id,
	})


static func load_from_save(object_id: int) -> WorldSpaceChunkType:
	if _items_by_id.has(object_id):
		return _items_by_id[object_id]
	
	var save_data = FileAccess\
		.open(_get_save_path(object_id), FileAccess.READ)\
		.get_var(true)
	
	var loaded_object = WorldSpaceChunkType.new()
	loaded_object.id = save_data.id
	
	_items_by_id[object_id] = loaded_object
	
	return loaded_object


static func _get_save_path(object_id: int) -> String:
	return "user://world_space/chunk/type/%s" % object_id
#endregion


func _init() -> void:
	id = randi()
