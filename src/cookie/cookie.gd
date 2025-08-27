extends RigidBody3D
class_name Cookie


var completeness: float = 1.0:
	set(value):
		completeness = value
		make_mesh()
var held := false:
	set(value):
		held = value
		if held and takeable:
			takeable = false
		freeze = held
		set_collision_layer_value(1, not held)
		set_collision_layer_value(2, not held)
		if not held:
			var obods := area_3d.get_overlapping_bodies()
			for bod in obods:
				if bod.is_in_group("mouse"):
					bod.can_take_cookie = true
					bod.takeable_cookie = self
					takeable = true
var takeable := false:
	set(value):
		takeable = value
		if outline:
			outline.visible = takeable


@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var area_3d: Area3D = $Area3D
@onready var outline: MeshInstance3D = $MeshInstance3D/Outline


func make_mesh() -> void:
	var cookie_mesh: CylinderMesh = mesh_instance_3d.mesh
	cookie_mesh.top_radius = sqrt(completeness) * 3.0
	cookie_mesh.bottom_radius = sqrt(completeness) * 3.0


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not held:
		if body.is_in_group("mouse"):
			body.can_take_cookie = true
			body.takeable_cookie = self
			takeable = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if not held:
		if body.is_in_group("mouse"):
			body.can_take_cookie = false
			body.takeable_cookie = null
			takeable = false
