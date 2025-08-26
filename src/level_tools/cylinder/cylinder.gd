@tool
extends StaticBody3D


@export_range(0.25, 50.0, 0.25) var radius: float = 5.0:
	set(value):
		radius = clampf(value, 0.25, 50.0)
		_parameter_changed()
@export_range(0.5, 100.0, 0.5) var height: float = 10.0:
	set(value):
		height = clampf(value, 0.5, 100.0)
		_parameter_changed()
@export var material: Material


@onready var collision_shape_3d = $CollisionShape3D
@onready var mesh_instance_3d = $CollisionShape3D/MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_shape_3d.shape = CylinderShape3D.new()
	collision_shape_3d.shape.radius = radius
	collision_shape_3d.shape.height = height
	mesh_instance_3d.mesh = CylinderMesh.new()
	mesh_instance_3d.mesh.top_radius = radius
	mesh_instance_3d.mesh.bottom_radius = radius
	mesh_instance_3d.mesh.height = height
	mesh_instance_3d.set_instance_shader_parameter("Radius", radius)
	mesh_instance_3d.set_instance_shader_parameter("Height", height)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _parameter_changed():
	if collision_shape_3d and mesh_instance_3d:
		collision_shape_3d.shape.radius = radius
		collision_shape_3d.shape.height = height
		mesh_instance_3d.mesh.top_radius = radius
		mesh_instance_3d.mesh.bottom_radius = radius
		mesh_instance_3d.mesh.height = height
		mesh_instance_3d.set_instance_shader_parameter("Radius", radius)
		mesh_instance_3d.set_instance_shader_parameter("Height", height)
