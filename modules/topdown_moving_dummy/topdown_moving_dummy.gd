extends CharacterBody2D


@export var _move_speed: float = 200


func _physics_process(_delta: float) -> void:
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = input_vector * _move_speed
	move_and_slide()
