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
enum AIR {DIVE, FLAP, CNT}
var move_state : int = MOVE.GROUND
var air_state : int = AIR.DIVE
var flap_threshold : float = 1.0
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
	main.find_node("flap_threshold_label").text = str(flap_threshold)
	main.find_node("air_color").color = COLOR_ON if move_state == MOVE.AIR else COLOR_DEFAULT
	main.find_node("ground_color").color = COLOR_ON if move_state == MOVE.GROUND else COLOR_DEFAULT
	main.find_node("air_state_dive_color").color = COLOR_ON if air_state == AIR.DIVE else COLOR_DEFAULT
	main.find_node("air_state_flap_color").color = COLOR_ON if air_state == AIR.FLAP else COLOR_DEFAULT
	
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

func handle_movement(delta):
#	var test_string := get_tree().get_root().find_node("test_string") as Label
	if is_on_floor():
		if(move_state == MOVE.AIR):
			move_state = MOVE.GROUND
			velocity.y = 0.0
		velocity = handle_on_ground_movement(delta)
	else:
		if(move_state == MOVE.GROUND):
			move_state = MOVE.AIR
		velocity = handle_in_air_movement(delta)
	
	print(str(abs(velocity.dot(Vector3.DOWN))))
	if velocity.dot(Vector3.DOWN) < 3.0:
		vec_helper.transform = Transform.IDENTITY.looking_at(velocity, Vector3.UP).scaled(Vector3.ONE * max(0.9, velocity.length()))
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if translation.y < -125.0:
		var pos = get_parent().find_node("player_spawn").translation
		visual.transform = Transform.IDENTITY
		translation = pos
		velocity = Vector3.ZERO

func handle_on_ground_movement(delta):
	var direction = get_input_vec3_camera_aligned().normalized()
	
	var v := velocity
	
	v = v.linear_interpolate(direction * speed, acceleration * delta)
	v.y = -0.01
	
#	if v.length_squared() > 0.25:
#		visual.rotation.y = lerp_angle(visual.rotation.y, look_dir, 1.0 * delta)
	visual.transform = visual.transform.interpolate_with(Transform(camera_pivot.transform.basis), 5.0 * delta).scaled(Vector3.ONE)
	visual.transform = Transform.IDENTITY.rotated(Vector3.UP, visual.get_rotation().y)
	
	if Input.is_action_just_pressed("jump"):
		v.y = jump_power
	
	return(v)

func get_input_vec3_ones()->Vector3:
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		direction.z += -1.0
	
	if Input.is_action_pressed("move_backward"):
		direction.z += 1.0
		
	if Input.is_action_pressed("move_left"):
		direction.x += -1.0
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1.0
		
	return(direction)

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

func handle_in_air_movement(delta):
	var max_turn = 20.0
	var max_pitch = deg2rad(20.0)
	
	var v = Vector3.ZERO
	var input_vec = get_input_vec3_camera_aligned()
	visual.rotate(Vector3.UP, clamp(-input_vec.x * delta, -max_turn, max_turn))
	visual.rotation.y = fposmod(visual.rotation.y, TAU)
	visual.rotation.z = lerp(visual.rotation.z, max_pitch * -input_vec.x, 2.0 * delta)
	
	v = velocity
	
	if Input.is_action_just_pressed("jump"):
		if air_state == AIR.DIVE:
			air_state = AIR.FLAP
			flap_threshold = abs(v.y) + flap_power
		elif air_state == AIR.FLAP:
			flap_threshold += flap_power
		flap_threshold = clamp(flap_threshold, 1.0, max_flap)
	
	if air_state == AIR.FLAP:
		v.y = lerp(v.y, flap_threshold, 10.0*delta)
		if v.y >= flap_threshold - 0.001:
			air_state = AIR.DIVE
	elif air_state == AIR.DIVE:
		flap_threshold = lerp(flap_threshold, 1.0, 2.0*delta)
		# Gravity
		v.y += -10.0 * delta
	
	return(v)  

func handle_collision():
	pass


















