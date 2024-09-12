extends KinematicBody

# Parameter exports
export var gravity : float = 0.98

# On Ground exports
export var speed : float = 1
export var acceleration : float = 1
export var jump_power : float = 10

# In Air exports
export var thrust_power : float = 1
export var drag_coef : float = 1
export var lift_coef : float = 1
export var mass : float = 1
export var max_flap : float = 20
export var flap_power : float = 4

# Camera exports
export(float, 0.1, 1.0) var mouse_sensitivity := 0.3
export(float, -90.0, 0.0) var min_pitch := -50.0
export(float, 0.0, 90.0) var max_pitch := 50.0

# Movement State
enum MOVE {GROUND, AIR, CNT}
var move_state : int = MOVE.GROUND
# MOVEMENT DEBUG
export(NodePath) var main_path
onready var main := get_node(main_path) as Node
const COLOR_DEFAULT := Color.dimgray
const COLOR_ON := Color.green
onready var vec_helper = find_node("vec_helper") as Spatial

# On Ground
var velocity : Vector3

# Camera
var mouse_captured := false

onready var camera_pivot := find_node("camera_pivot") as Spatial
#onready var camera := find_node("camera") as Camera
onready var visual := find_node("mesh") as Spatial

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
	
	velocity = Vector3.FORWARD * 50

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true
	main.find_node("air_color").color = COLOR_ON if move_state == MOVE.AIR else COLOR_DEFAULT
	main.find_node("ground_color").color = COLOR_ON if move_state == MOVE.GROUND else COLOR_DEFAULT
	
func _input(event):
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).button_index == BUTTON_LEFT:
			if (event as InputEventMouseButton).pressed:
				pass
	
	if event is InputEventMouseMotion:
		if mouse_captured:
			camera_pivot.rotation_degrees.y -= event.relative.x * mouse_sensitivity
			camera_pivot.rotation.y = fposmod(camera_pivot.rotation.y, TAU)
			camera_pivot.rotation_degrees.x -= event.relative.y * mouse_sensitivity
			camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, min_pitch, max_pitch)

func _physics_process(delta):
	handle_movement(delta)

func get_input_vec3_camera_aligned()->Vector3:
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		direction -= camera_pivot.transform.basis.z
	
	if Input.is_action_pressed("move_backward"):
		direction += camera_pivot.transform.basis.z
		
	if Input.is_action_pressed("move_left"):
		direction -= camera_pivot.transform.basis.x
	
	if Input.is_action_pressed("move_right"):
		direction += camera_pivot.transform.basis.x
	return(direction)

func handle_movement(delta):
	if is_on_floor():
		if(move_state == MOVE.AIR):
			move_state = MOVE.GROUND
			velocity.y = 0.0
		velocity = handle_on_ground_movement(velocity, delta)
	else:
		if(move_state == MOVE.GROUND):
			move_state = MOVE.AIR
		velocity = handle_in_air_movement(velocity, delta)
	
	update_velocity_vec_helper()
	
	if move_state == MOVE.GROUND:
		velocity = move_and_slide_with_snap(velocity, Vector3.DOWN, Vector3.UP, false, 4, 0.78, true)
	elif move_state == MOVE.AIR:
		velocity = move_and_slide(velocity, Vector3.UP, false, 4, 0.78, true)
	
	if translation.y < -125.0:
		var pos = get_parent().find_node("player_spawn").translation
		translation = pos
		visual.transform = Transform.IDENTITY
		velocity = Vector3.ZERO

func handle_on_ground_movement(v:Vector3, delta):
	var direction = get_input_vec3_camera_aligned()
	direction.y = 0.0
	direction = direction.normalized()
	
	v = v.linear_interpolate(direction * speed, acceleration * delta)
	v.y = -0.01
	
	visual.transform = visual.transform.interpolate_with(Transform(camera_pivot.transform.basis), 5.0 * delta).scaled(Vector3.ONE)
	visual.transform = Transform.IDENTITY.rotated(Vector3.UP, visual.get_rotation().y)
	
	if Input.is_action_just_pressed("jump"):
		v.y = jump_power
		move_state = MOVE.AIR
	
	return(v)

func handle_in_air_movement(v:Vector3, delta):
	var max_fly_speed = 20.0
	
	var direction = get_input_vec3_camera_aligned().normalized()
	v = v.linear_interpolate(direction * max_fly_speed, acceleration * delta)
	
	if Input.is_action_just_pressed("jump"):
		pass
	
	return(v)  

func update_velocity_vec_helper():
	var scale = range_lerp(velocity.length(), 0.01, 20.0, 0.5, 10.0)
	main.find_node("velocity").text = str(velocity.length()) + " s: " + str(scale)
#	var v = velocity.normalized()
#	var v_no_y = Vector3(v.x, 0.0, v.z).normalized()
#	vec_helper.transform = Transform.IDENTITY.rotated(
#		Vector3.UP,
#		-v_no_y.dot(Vector3.RIGHT) * (PI / 2.0)
#	).rotated(
#		Vector3.RIGHT,
##		v.dot(Vector3.UP) * (PI / 2.0)
#		0.0
#	).scaled(
#		Vector3.ONE * velocity.length()
#	)
	if(velocity.length() > 0.01):
		vec_helper.transform.basis = Basis(
			transform.basis.z.normalized().cross(velocity.normalized()).normalized(), 
			transform.basis.z.normalized().angle_to(velocity.normalized())
		).scaled(
			Vector3.ONE * scale
		)
















