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
	FileAccess\
		.open(_get_save_path(region.id), FileAccess.WRITE)\
		.store_var({
			"id": region.id,
			"color": region.color.to_html(),
		})


static func load_from_save(id: int) -> WorldSpaceChunkMapRegion:
	var save = FileAccess\
		.open(_get_save_path(id), FileAccess.READ)\
		.get_var(true)
	
	var loaded_region = WorldSpaceChunkMapRegion.new()
	loaded_region.id = id
	loaded_region.color = Color(save.color)
	
	return loaded_region


static func _get_save_path(id: int) -> String:
	return "user://world_space/chunk/map/region/%s" % id
#endregion


func _init() -> void:
	id = randi()
