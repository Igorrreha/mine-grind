class_name WorldSpaceChunkMapRegion
extends Resource


static var _items_by_id: Dictionary#[int, WorldSpaceChunkMapRegion]


@export var color: Color:
	get:
		if not _color8:
			_color8 = Color8(color.r8, color.g8, color.b8, color.a8)
		
		return _color8

var id: int:
	set(v):
		_items_by_id.erase(v)
		id = v
		_items_by_id[id] = self

var _color8: Color 


#region Static methods
static func save(region: WorldSpaceChunkMapRegion) -> void:
	var save_path = _get_save_path(region.id)
	var save_dir_path = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(save_dir_path):
		DirAccess.make_dir_recursive_absolute(save_dir_path)
	
	FileAccess\
		.open(save_path, FileAccess.WRITE)\
		.store_var({
			"id": region.id,
			"color": region.color.to_html(),
		})


static func load_from_save(object_id: int) -> WorldSpaceChunkMapRegion:
	if _items_by_id.has(object_id):
		return _items_by_id[object_id]
	
	var save_data = FileAccess\
		.open(_get_save_path(object_id), FileAccess.READ)\
		.get_var(true)
	
	var loaded_region = WorldSpaceChunkMapRegion.new()
	loaded_region.id = save_data.id
	loaded_region.color = Color(save_data.color)
	
	return loaded_region


static func _get_save_path(object_id: int) -> String:
	return "user://world_space/chunk/map/region/%s" % object_id
#endregion


func _init() -> void:
	id = randi()
