class_name WorldSpaceNoise
extends WorldSpaceProp


@export var _noise: FastNoiseLite


func get_value_at(point: Vector2i) -> float:
	return _noise.get_noise_2dv(point) / 2.0 + 0.5
