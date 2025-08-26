extends Camera3D


@onready var mouse: Mouse = $"../Mouse"


func _process(delta: float) -> void:
	global_transform = mouse.cam_target.global_transform
