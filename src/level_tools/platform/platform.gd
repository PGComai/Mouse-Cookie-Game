@tool
extends StaticBody3D


@export var size := Vector3(20.0, 1.0, 20.0):
	set(value):
		size = value.clamp(Vector3(0.1, 0.1, 0.1), Vector3(1000.0, 1000.0, 1000.0))
		_parameter_changed()
@export var _material: Material


var slowly_rotating := false


@onready var collision_shape_3d = $CollisionShape3D
@onready var mesh_instance_3d = $CollisionShape3D/MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	collision_shape_3d.shape = BoxShape3D.new()
	collision_shape_3d.shape.size = size
	mesh_instance_3d.mesh = BoxMesh.new()
	mesh_instance_3d.mesh.size = size
	if _material:
		mesh_instance_3d.set_surface_override_material(0, _material)
	#mesh_instance_3d.set_instance_shader_parameter("Extents", size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _parameter_changed():
	if collision_shape_3d and mesh_instance_3d:
		collision_shape_3d.shape.size = size
		mesh_instance_3d.mesh.size = size
		#mesh_instance_3d.set_instance_shader_parameter("Extents", size)


func smooth_rotation(delta: float):
	if slowly_rotating:
		pass
