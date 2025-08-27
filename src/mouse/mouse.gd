extends CharacterBody3D
class_name Mouse


const MOUSE_SENS: float = 0.003
const MAX_SPEED: float = 20.0
const JUMP_STRENGTH: float = 13.0
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
var jumped_off_wall := false
var can_take_cookie := false:
	set(value):
		can_take_cookie = value
		if label_take_cookie:
			label_take_cookie.visible = value
var takeable_cookie: Cookie
var held_cookie: Cookie:
	set(value):
		held_cookie = value
		if held_cookie:
			cookie_slowdown = 1.0 - (held_cookie.completeness * 0.8)
		else:
			cookie_slowdown = 1.0
var cookie_slowdown: float = 1.0


@onready var turnable: Node3D = $Turnable
@onready var cam_h: Node3D = $CamH
@onready var cam_v: Node3D = $CamH/CamV
@onready var cam_arm: SpringArm3D = $CamH/CamV/CamArm
@onready var cam_target: Node3D = $CamH/CamV/CamArm/CamTarget
@onready var ray_cast_3d: ShapeCast3D = $RayCast3D
@onready var ray_cast_3d_front: ShapeCast3D = $Turnable/RayCast3DFront
@onready var ray_cast_3d_corner: ShapeCast3D = $Turnable/RayCast3DCorner
@onready var ray_cast_3d_back: ShapeCast3D = $Turnable/RayCast3DBack
@onready var ray_cast_3d_corner_back: ShapeCast3D = $Turnable/RayCast3DCornerBack
@onready var label_take_cookie: Label = $Control/MarginContainer/LabelTakeCookie
@onready var cookie_spot: Node3D = $Turnable/CookieSpot


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rot_h -= event.relative.x * MOUSE_SENS
		rot_v -= event.relative.y * MOUSE_SENS
	if event.is_action_pressed("grab"):
		if held_cookie:
			held_cookie.held = false
			held_cookie.apply_central_impulse(get_real_velocity() * get_physics_process_delta_time())
			held_cookie.apply_central_impulse(Vector3.UP * 10.0)
			held_cookie.apply_central_impulse(-turnable.global_basis.z * 10.0 * cookie_slowdown)
			held_cookie = null
		elif takeable_cookie:
			held_cookie = takeable_cookie
			takeable_cookie = null
			held_cookie.held = true
			can_take_cookie = false


func _process(delta: float) -> void:
	cam_h.rotation.y = rot_h
	cam_v.rotation.x = rot_v
	
	if held_cookie:
		held_cookie.global_transform = cookie_spot.global_transform


func _physics_process(delta: float) -> void:
	var move_accel: float
	var surface_normal: Vector3
	var is_on_surface: bool = (is_on_wall() or is_on_floor())
	var going_over_edge := false
	
	if not is_on_surface:
		if climbing and not jumped_off_wall:
			if ray_cast_3d.is_colliding():
				var norm = ray_cast_3d.get_collision_normal(0)
				if ray_cast_3d_corner.is_colliding() and not ray_cast_3d_front.is_colliding():
					norm = norm.slerp(ray_cast_3d_corner.get_collision_normal(0), 0.5).normalized()
				velocity *= 0.9
				velocity -= ((norm * 2.0) + get_real_velocity().normalized()) * 2.0
				surface_normal = norm
			elif ray_cast_3d_corner.is_colliding():
				var norm = ray_cast_3d_corner.get_collision_normal(0)
				if ray_cast_3d_back.is_colliding():
					norm = norm.slerp(ray_cast_3d_back.get_collision_normal(0), 0.5).normalized()
				elif ray_cast_3d_corner_back.is_colliding():
					norm = norm.slerp(ray_cast_3d_corner_back.get_collision_normal(0), 0.5).normalized()
				velocity *= 0.9
				velocity -= ((norm * 2.0) + get_real_velocity().normalized()) * 2.0
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
		if jumped_off_wall:
			jumped_off_wall = false
		move_accel = ACCEL
		if is_on_floor():
			surface_normal = get_floor_normal()
			#if ray_cast_3d_corner.is_colliding() and not ray_cast_3d_front.is_colliding():
				#going_over_edge = true
				#surface_normal = surface_normal.slerp(ray_cast_3d_corner.get_collision_normal(0), 0.5).normalized()
			climbing = false
		else:
			climbing = true
			surface_normal = get_wall_normal()
			if ray_cast_3d_corner.is_colliding() and not ray_cast_3d_front.is_colliding():
				surface_normal = surface_normal.slerp(ray_cast_3d_corner.get_collision_normal(0), 0.5).normalized()
				#velocity *= 0.75
		if Input.is_action_just_pressed("jump"):
			if surface_normal.is_equal_approx(Vector3.UP):
				velocity += surface_normal * JUMP_STRENGTH * cookie_slowdown
			else:
				velocity += surface_normal.slerp(Vector3.UP, 0.2) * JUMP_STRENGTH * cookie_slowdown
			if climbing:
				jumped_off_wall = true
			climbing = false
	
	var input_dir := Input.get_vector("left", "right", "fwd", "back")
	var move_dir := cam_h.global_basis * Vector3(input_dir.x, 0.0, input_dir.y)
	var look_basis: Basis
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
			velocity.x = lerpf(velocity.x, move_dir.x * MAX_SPEED * cookie_slowdown, move_accel * delta)
			velocity.z = lerpf(velocity.z, move_dir.z * MAX_SPEED * cookie_slowdown, move_accel * delta)
			turnable.global_basis = lerp(turnable.global_basis, look_basis.rotated(look_basis.y, PI).orthonormalized(), 0.3)
		else:
			velocity.x = lerpf(velocity.x, wall_climb_dir.x * MAX_SPEED * cookie_slowdown * 0.7, move_accel * delta)
			velocity.z = lerpf(velocity.z, wall_climb_dir.z * MAX_SPEED * cookie_slowdown * 0.7, move_accel * delta)
			velocity.y = lerpf(velocity.y, wall_climb_dir.y * MAX_SPEED * cookie_slowdown * 0.7, move_accel * delta)
			wall_model_rotation = atan2(input_dir.y, input_dir.x)
			turnable.global_basis = Basis(lerp(turnable.global_basis.get_rotation_quaternion(),
									wall_climb_basis.rotated(surface_normal, PI + wall_model_rotation + (PI/2.0))\
										.rotated(wall_climb_basis.z, PI)\
										.get_rotation_quaternion(),
									0.3))
	else:
		if not climbing:
			velocity.x = lerpf(velocity.x, 0.0, move_accel * delta)
			velocity.z = lerpf(velocity.z, 0.0, move_accel * delta)
			look_basis = Basis(surface_normal.cross(last_move_dir.normalized()), surface_normal, last_move_dir.normalized()).orthonormalized()
			turnable.global_basis = lerp(turnable.global_basis, look_basis.rotated(look_basis.y, PI).orthonormalized(), 0.3)
		else:
			velocity.x = lerpf(velocity.x, 0.0, move_accel * delta)
			velocity.z = lerpf(velocity.z, 0.0, move_accel * delta)
			velocity.y = lerpf(velocity.y, 0.0, move_accel * delta)
			turnable.global_basis = Basis(lerp(turnable.global_basis.get_rotation_quaternion(),
									wall_climb_basis.rotated(surface_normal, PI + wall_model_rotation + (PI/2.0))\
										.rotated(wall_climb_basis.z, PI)\
										.get_rotation_quaternion(),
									0.3))
	
	move_and_slide()
