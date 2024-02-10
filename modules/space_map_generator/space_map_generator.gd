@tool
extends EditorScript


func _run() -> void:
	var noise = preload("res://modules/space_map_generator/test_noise.tres")\
		.get_image()
	var noise2 = preload("res://modules/space_map_generator/test_noise2.tres")\
		.get_image()
	var gradient = preload("res://modules/space_map_generator/test_gradient.tres")\
		.get_image()
	
	var space_map = SpaceMap.new()
	space_map.map = noise
	space_map.regions.append(SpaceMapRegion.new("grass", Color8(255, 0, 0)))
	space_map.regions.append(SpaceMapRegion.new("dirt", Color8(0, 255, 0)))
	space_map.regions.append(SpaceMapRegion.new("rock", Color8(0, 0, 255)))
	
	var only_r = space_map.get_regions_space_map(["red"])
	
	var input = get_scene().get_node("HBoxContainer/1") as TextureRect
	var output = get_scene().get_node("HBoxContainer/2") as TextureRect
	
	input.texture = ImageTexture.create_from_image(only_r.image)
	output.texture = ImageTexture.create_from_image(_clip(noise2, only_r.image))


func _clip(source: Image, mask: Image) -> Image:
	var result_data: PackedByteArray
	
	var void_color = Color.TRANSPARENT
	for y in mask.get_height():
		for x in mask.get_width():
			var result_color = void_color\
				if mask.get_pixel(x, y).a == 0\
				else source.get_pixel(x, y)
			
			result_data.append(result_color.r8)
			result_data.append(result_color.g8)
			result_data.append(result_color.b8)
			result_data.append(result_color.a8)
	
	return Image.create_from_data(mask.get_width(), mask.get_height(),
		false, mask.get_format(), result_data)
