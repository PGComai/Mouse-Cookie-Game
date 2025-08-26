extends CharacterBody3D
class_name Mouse


const MOUSE_SENS: float = 0.003
const MAX_SPEED: float = 15.0
const JUMP_STRENGTH: float = 8.0
const ACCEL: float = 5.0
const ACCEL_AIR: float = 1.0
const GRAV_STRENGTH: float = 3.0


var rot_h: float = 0.0
var rot_v: float = -PI/4.0:
	set(value):
		rot_v = clampf(value, -PI/2.1, PI/4.0)
var climbing := false
var wall_model_rotation: float = 0.0
var last_move_dir := Vector3.FORWARD


@onready var turnable: Node3D = $Turnable
@onready var cam_h: Node3D = $CamH
@onready var cam_v: Node3D = $CamH/CamV
@onready var cam_arm: SpringArm3D = $CamH/CamV/CamArm
@onready var cam_target: Node3D = $CamH/CamV/CamArm/CamTarget
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var ray_cast_3d_front: RayCast3D = $Turnable/RayCast3DFront
@onready var ray_cast_3d_corner: RayCast3D = $Turnable/RayCast3DCorner
@onready var ray_cast_3d_back: RayCast3D = $Turnable/RayCast3DBack
@onready var ray_cast_3d_corner_back: RayCast3D = $Turnable/RayCast3DCornerBack


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rot_h -= event.relative.x * MOUSE_SENS
		rot_v -= event.relative.y * MOUSE_SENS


func _process(delta: float) -> void:
	cam_h.rotation.y = rot_h
	cam_v.rotation.x = rot_v


func _physics_process(delta: float) -> void:
	var move_accel: float
	var surface_normal: Vector3
	var is_on_surface: bool = (is_on_wall() or is_on_floor())
	var going_over_edge := false
	
	if not is_on_surface:
		if climbing:
			if ray_cast_3d.is_colliding():
				var norm = ray_cast_3d.get_collision_normal()
				if ray_cast_3d_corner.is_colliding() and not ray_cast_3d_front.is_colliding():
					norm = norm.slerp(ray_cast_3d_corner.get_collision_normal(), 0.5).normalized()
				velocity -= norm
				surface_normal = norm
			elif ray_cast_3d_corner.is_colliding():
				var norm = ray_cast_3d_corner.get_collision_normal()
				if ray_cast_3d_back.is_colliding():
					norm = norm.slerp(ray_cast_3d_back.get_collision_normal(), 0.5).normalized()
				elif ray_cast_3d_corner_back.is_colliding():
					norm = norm.slerp(ray_cast_3d_corner_back.get_collision_normal(), 0.5).normalized()
				velocity -= norm
				surface_normal = norm
			else:
				surface_normal = Vector3.UP
				climbing = false
		else:
			velocity += get_gravity() * delta * GRAV_STRENGTH
			move_accel = ACCEL_AIR
			climbing = false
			surface_normal = Vector3.UP
	else:
		move_accel = ACCEL
		if is_on_floor():
			surface_normal = get_floor_normal()
			if ray_cast_3d_corner.is_colliding() and not ray_cast_3d_front.is_colliding():
				going_over_edge = true
				surface_normal = surface_normal.slerp(ray_cast_3d_corner.get_collision_normal(), 0.5).normalized()
			climbing = false
		else:
			climbing = true
			surface_normal = get_wall_normal()
			if ray_cast_3d_corner.is_colliding() and not ray_cast_3d_front.is_colliding():
				surface_normal = surface_normal.slerp(ray_cast_3d_corner.get_collision_normal(), 0.5).normalized()
				velocity *= 0.75
		if Input.is_action_just_pressed("jump"):
			velocity += (surface_normal * JUMP_STRENGTH)
			climbing = false
	
	var input_dir := Input.get_vector("left", "right", "fwd", "back")
	var move_dir := cam_h.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	var look_basis: Basis
	var look_dir: Vector3
	var wall_climb_basis: Basis
	var wall_climb_dir: Vector3
	
	if climbing:
		ray_cast_3d.target_position = -surface_normal * 0.7
		wall_climb_basis = Basis(Vector3.DOWN.cross(surface_normal), surface_normal, Vector3.DOWN).orthonormalized()
		wall_climb_dir = wall_climb_basis * Vector3(-input_dir.x, 0.0, input_dir.y)
	else:
		look_basis = Basis(surface_normal.cross(move_dir.normalized()), surface_normal, move_dir.normalized()).orthonormalized()
		ray_cast_3d.target_position = Vector3.DOWN
	
	if move_dir:
		last_move_dir = move_dir
		if not climbing:
			velocity.x = lerpf(velocity.x, move_dir.x * MAX_SPEED, move_accel * delta)
			velocity.z = lerpf(velocity.z, move_dir.z * MAX_SPEED, move_accel * delta)
			turnable.basis = lerp(turnable.basis, look_basis.rotated(look_basis.y, PI), 0.3)
		else:
			velocity.x = lerpf(velocity.x, wall_climb_dir.x * MAX_SPEED * 0.7, move_accel * delta)
			velocity.z = lerpf(velocity.z, wall_climb_dir.z * MAX_SPEED * 0.7, move_accel * delta)
			velocity.y = lerpf(velocity.y, wall_climb_dir.y * MAX_SPEED * 0.7, move_accel * delta)
			wall_model_rotation = atan2(input_dir.y, input_dir.x)
			turnable.basis = Basis(lerp(turnable.basis.get_rotation_quaternion(),
									wall_climb_basis.rotated(surface_normal, PI + wall_model_rotation + (PI/2.0))\
										.rotated(wall_climb_basis.z, PI)\
										.get_rotation_quaternion(),
									0.3))
	else:
		if not climbing:
			velocity.x = lerpf(velocity.x, 0.0, move_accel * delta)
			velocity.z = lerpf(velocity.z, 0.0, move_accel * delta)
			look_basis = Basis(surface_normal.cross(last_move_dir.normalized()), surface_normal, last_move_dir.normalized()).orthonormalized()
			turnable.basis = lerp(turnable.basis, look_basis.rotated(look_basis.y, PI), 0.3)
		else:
			velocity.x = lerpf(velocity.x, 0.0, move_accel * delta)
			velocity.z = lerpf(velocity.z, 0.0, move_accel * delta)
			velocity.y = lerpf(velocity.y, 0.0, move_accel * delta)
			turnable.basis = Basis(lerp(turnable.basis.get_rotation_quaternion(),
									wall_climb_basis.rotated(surface_normal, PI + wall_model_rotation + (PI/2.0))\
										.rotated(wall_climb_basis.z, PI)\
										.get_rotation_quaternion(),
									0.3))
	
	move_and_slide()
