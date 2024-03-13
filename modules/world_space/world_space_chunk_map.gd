class_name WorldSpaceChunkMap
extends Resource


static var void_region := \
	load("res://modules/world_space/void_region.tres") as WorldSpaceChunkMapRegion

static var _items_by_id: Dictionary#[int, WeakRef[WorldSpaceChunkMap]]


@export var id: int:
	set(v):
		_items_by_id.erase(v)
		id = v
		_items_by_id[id] = weakref(self)

var image: Image
var regions: Array[WorldSpaceChunkMapRegion]

var _regions_by_color: Dictionary


#region Static methods
static func create(size: Vector2i,
	source_regions: Array[WorldSpaceChunkMapRegion]) -> WorldSpaceChunkMap:
	
	var new_map := WorldSpaceChunkMap.new()
	new_map.image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	new_map.regions = source_regions
	new_map.id = randi()
	
	return new_map


static func create_from(map: WorldSpaceChunkMap,
	extracting_regions: Array[WorldSpaceChunkMapRegion],
	collapse_regions_to: WorldSpaceChunkMapRegion = null) -> WorldSpaceChunkMap:
	
	var collapse_regions := collapse_regions_to != null
	var image_data: PackedByteArray
	var source_image = map.image
	
	for y in source_image.get_height():
		for x in source_image.get_width():
			var pixel_color = source_image.get_pixel(x, y)
			var result_color = void_region.color
			
			for region in extracting_regions:
				if region.color == pixel_color:
					result_color = collapse_regions_to.color if collapse_regions\
						else pixel_color
					break
			
			image_data.append(result_color.r8)
			image_data.append(result_color.g8)
			image_data.append(result_color.b8)
			image_data.append(result_color.a8)
	
	var new_map = WorldSpaceChunkMap.new()
	if collapse_regions:
		new_map.regions.append(collapse_regions_to)
	else:
		new_map.regions = extracting_regions
	
	new_map.image = Image.create_from_data(
		source_image.get_width(), source_image.get_height(),
		false, source_image.get_format(), image_data)
	
	new_map.id = randi()
	
	return new_map


static func save(map: WorldSpaceChunkMap) -> void:
	var save_path = _get_save_path(map.id)
	var save_dir_path = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(save_dir_path):
		DirAccess.make_dir_recursive_absolute(save_dir_path)
	
	FileAccess\
		.open(save_path, FileAccess.WRITE)\
		.store_var({
			"id": map.id,
			"regions_ids": map.regions.map(func(x: WorldSpaceChunkMapRegion):
				return x.id),
			"image_data": map.image.get_data(),
			"image_width": map.image.get_width(),
			"image_height": map.image.get_height(),
		})
	
	for region in map.regions:
		WorldSpaceChunkMapRegion.save(region)


static func load_from_save(object_id: int) -> WorldSpaceChunkMap:
	if _items_by_id.has(object_id):
		var ref = _items_by_id[object_id].get_ref()
		if ref != null:
			return ref
	
	var save_data = FileAccess\
		.open(_get_save_path(object_id), FileAccess.READ)\
		.get_var(true)
	
	var loaded_object = WorldSpaceChunkMap.new()
	loaded_object.id = save_data.id
	loaded_object.regions.assign(save_data.regions_ids.map(func(region_id: int):
		return WorldSpaceChunkMapRegion.load_from_save(region_id)))
	
	var loaded_image = Image.create_from_data(
		save_data.image_width, save_data.image_height, false,
		Image.FORMAT_RGBA8, save_data.image_data)
	
	loaded_object.image = loaded_image
	
	return loaded_object


static func _get_save_path(object_id: int) -> String:
	return "user://world_space/chunk/map/%s" % object_id
#endregion


func _init() -> void:
	if id == 0:
		id = randi()


func get_region_at(position: Vector2i) -> WorldSpaceChunkMapRegion:
	var color = image.get_pixel(position.x, position.y)
	if color == void_region.color:
		return void_region
	
	if _regions_by_color.is_empty():
		for region in regions:
			_regions_by_color[region.color] = region
	
	return _regions_by_color[color]


func set_region_at(region: WorldSpaceChunkMapRegion, position: Vector2i) -> void:
	if not (void_region == region or regions.has(region)):
		regions.append(region)
		_regions_by_color[region.color] = region
	
	image.set_pixel(position.x, position.y, region.color)
