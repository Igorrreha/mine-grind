class_name WorldSpaceChunk
extends Resource


var id: int
var rect: Rect2i
var map: WorldSpaceChunkMap:
	set(v):
		if v:
			map_id = map.id
			map = v
var map_id: int

var _is_saved: bool


static func load_from_save(id: int) -> WorldSpaceChunk:
	var save_file = FileAccess.open(_get_save_path(id), FileAccess.READ)
	var save = save_file.get_var(true)
	
	var loaded_chunk = WorldSpaceChunk.new()
	loaded_chunk.id = save.id
	loaded_chunk.rect = save.rect
	loaded_chunk.map_id = save.map_id
	return loaded_chunk


static func _get_save_path(id: int) -> String:
	return "user://world_space/chunk/%s" % id


func _init() -> void:
	id = randi()


func _is_active() -> bool:
	return map != null


func activate() -> void:
	if not _is_active():
		load_map()


func load_map() -> void:
	pass


func save() -> void:
	var path = _get_save_path(id)
	var save = {
		"id": id,
		"rect": rect,
		"map_id": map_id,
	}
	FileAccess.open(path, FileAccess.WRITE).store_var(save)

