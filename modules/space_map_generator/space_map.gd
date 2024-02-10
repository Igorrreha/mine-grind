class_name SpaceMap
extends Resource


@export var texture: Texture2D
@export var image: Image
@export var regions: Array[SpaceMapRegion]

var _regions_by_color: Dictionary


func use_texture_image() -> void:
	await texture.changed
	image = texture.get_image()


func get_region_at(x: int, y: int) -> SpaceMapRegion:
	var color = image.get_pixel(x, y)
	if _regions_by_color.is_empty():
		for region in regions:
			_regions_by_color[region.color] = region
	
	return _regions_by_color[color]


func get_regions_space_map(regions_ids: Array[StringName],
		collapse_regions: bool = false) -> SpaceMap:
	var image_data: PackedByteArray
	
	var important_regions = regions.filter(func(x: SpaceMapRegion):
		return regions_ids.has(x.id))
	
	var void_color = Color.TRANSPARENT
	var collapsed_regions_color = Color.WHITE
	for y in image.get_height():
		for x in image.get_width():
			var pixel_color = image.get_pixel(x, y)
			var result_color = void_color
			for region in important_regions:
				if region.color == pixel_color:
					result_color = collapsed_regions_color if collapse_regions\
						else pixel_color
					break
			
			image_data.append(result_color.r8)
			image_data.append(result_color.g8)
			image_data.append(result_color.b8)
			image_data.append(result_color.a8)
	
	var new_map = SpaceMap.new()
	for region in regions: 
		if regions_ids.has(region.id):
			var new_region = SpaceMapRegion.new()
			new_region.id = region.id
			new_region.color = region.color
			new_map.regions.append(new_region)
	new_map.image = Image.create_from_data(image.get_width(), image.get_height(),
		false, image.get_format(), image_data)
	return new_map
