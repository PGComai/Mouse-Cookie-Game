@tool
class_name StairMaster
extends StaticBody3D


@export var make := false:
	set(value):
		if value:
			make_stairs()
@export var step_size := Vector3(1.0, 1.0, 1.0):
	set(value):
		step_size = clamp(value, Vector3(0.5, 0.5, 0.5), Vector3(20.0, 20.0, 20.0))
@export var step_height: float = 1.0:
	set(value):
		step_height = clampf(value, -20.0, 20.0)
@export var num_steps: int = 5:
	set(value):
		num_steps = clampi(value, 1, 200)


func make_stairs():
	for child in get_children():
		child.queue_free()
	
	var new_mmi := MultiMeshInstance3D.new()
	var new_mm := MultiMesh.new()
	var stepmesh := BoxMesh.new()
	stepmesh.size = step_size
	
	new_mm.transform_format = MultiMesh.TRANSFORM_3D
	new_mm.mesh = stepmesh
	new_mm.instance_count = num_steps
	new_mm.visible_instance_count = new_mm.instance_count
	
	for i in num_steps:
		var new_step := CollisionShape3D.new()
		var new_shape := BoxShape3D.new()
		new_shape.size = step_size
		new_step.shape = new_shape
		
		add_child(new_step)
		new_step.owner = get_tree().edited_scene_root
		
		var float_i := float(i)
		
		new_step.position = Vector3(0.0,
						(float_i * step_height) + (step_size.y / 2.0),
						-float_i * step_size.z)
		new_mm.set_instance_transform(i, new_step.transform)
	
	new_mmi.multimesh = new_mm
	add_child(new_mmi)
	new_mmi.owner = get_tree().edited_scene_root
