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
	var path = _get_save_path(object_to_save.id)
	FileAccess.open(path, FileAccess.WRITE).store_var({
		"id": object_to_save.id,
	})


static func load_from_save(id: int) -> WorldSpaceChunkType:
	var save_data = FileAccess\
		.open(_get_save_path(id), FileAccess.READ)\
		.get_var(true)
	
	var loaded_object = WorldSpaceChunkType.new()
	loaded_object.id = save_data.id
	
	_items_by_id[id] = loaded_object
	
	return loaded_object


static func _get_save_path(id: int) -> String:
	return "user://world_space/chunk/type/%s" % id
#endregion


func _init() -> void:
	id = randi()
