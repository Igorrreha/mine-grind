class_name WorldSpaceChunkMap
extends Resource


static var void_region := \
	load("res://modules/world_space/void_region.tres") as WorldSpaceChunkMapRegion

static var _items_by_id: Dictionary#[int, WorldSpaceChunkMap]


var id: int:
	set(v):
		_items_by_id.erase(v)
		id = v
		_items_by_id[id] = self

var image: Image
var regions: Array[WorldSpaceChunkMapRegion]

var _regions_by_color: Dictionary


#region Static methods
static func create(size: Vector2i,
	regions: Array[WorldSpaceChunkMapRegion]) -> WorldSpaceChunkMap:
	
	var new_map := WorldSpaceChunkMap.new()
	new_map.image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	new_map.regions = regions
	new_map.id = randi()
	
	return new_map


static func create_from(map: WorldSpaceChunkMap,
	extracting_regions: Array[WorldSpaceChunkMapRegion],
	collapse_regions_to: WorldSpaceChunkMapRegion = null) -> WorldSpaceChunkMap:
	
	var collapse_regions := collapse_regions_to != null
	var image_data: PackedByteArray
	var image = map.image
	
	for y in image.get_height():
		for x in image.get_width():
			var pixel_color = image.get_pixel(x, y)
			var result_color = void_region.color
			
			for region in extracting_regions:
				if region.color == pixel_color:
					result_color = collapse_regions_to if collapse_regions\
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
	
	new_map.image = Image.create_from_data(image.get_width(), image.get_height(),
		false, image.get_format(), image_data)
	
	new_map.id = randi()
	
	return new_map


static func save(map: WorldSpaceChunkMap) -> void:
	FileAccess\
		.open(_get_save_path(map.id), FileAccess.WRITE)\
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


static func load_from_save(id: int) -> WorldSpaceChunkMap:
	var save = FileAccess\
		.open(_get_save_path(id), FileAccess.READ)\
		.get_var(true)
	
	var loaded_object = WorldSpaceChunkMap.new()
	loaded_object.id = save.id
	loaded_object.regions.assign(save.regions_ids.map(func(region_id: int):
		return WorldSpaceChunkMapRegion.load_from_save(region_id)))
	
	var image = Image.create_from_data(save.image_width, save.image_height, false,
		Image.FORMAT_RGBA8, save.image_data)
	loaded_object.image = image
	
	return loaded_object


static func _get_save_path(id: int) -> String:
	return "user://world_space/chunk/map/%s" % id
#endregion


func _init() -> void:
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
