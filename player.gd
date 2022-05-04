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

# Camera exports
export(float, 0.1, 1.0) var mouse_sensitivity := 0.3
export(float, -90.0, 0.0) var min_pitch := -50.0
export(float, 0.0, 90.0) var max_pitch := 50.0

# Movement State
enum MOVE {GROUND, AIR, CNT}
var move_state : int = MOVE.GROUND
# MOVEMENT DEBUG
export(NodePath) var air_color_path
export(NodePath) var ground_color_path
onready var air_color : ColorRect = get_node(air_color_path)
onready var ground_color : ColorRect = get_node(ground_color_path)
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
			air_color.color = COLOR_DEFAULT
			ground_color.color = COLOR_ON
			move_state = MOVE.GROUND
			velocity.y = 0.0
		velocity = handle_on_ground_movement(delta)
	else:
		if(move_state == MOVE.GROUND):
			air_color.color = COLOR_ON
			ground_color.color = COLOR_DEFAULT
			move_state = MOVE.AIR
		velocity = handle_in_air_movement(delta)
	
	vec_helper.transform = Transform().looking_at(-velocity, Vector3.UP).scaled(Vector3(velocity.length(), velocity.length(), velocity.length()))
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if translation.y < -125.0:
		var pos = get_parent().find_node("player_spawn").translation
		visual.transform = Transform.IDENTITY
		translation = pos
		velocity = Vector3.ZERO

func handle_on_ground_movement(delta):
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		direction -= camera_pivot.transform.basis.z
	
	if Input.is_action_pressed("move_backward"):
		direction += camera_pivot.transform.basis.z
		
	if Input.is_action_pressed("move_left"):
		direction -= camera_pivot.transform.basis.x
	
	if Input.is_action_pressed("move_right"):
		direction += camera_pivot.transform.basis.x
	
	direction = direction.normalized()
	
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

func get_input()->Vector3:
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

func handle_in_air_movement(delta):
	var max_turn = 20.0
	var max_pitch = 4.0
	
	var v = Vector3.ZERO
	var input_vec = get_input()
	visual.rotate(Vector3.UP, clamp(-input_vec.x * delta, -max_turn, max_turn))
	visual.rotation.y = fposmod(visual.rotation.y, TAU)
	var move_vec = visual.transform.basis * Vector3.FORWARD * 10.0
	v = move_vec
	
	if Input.is_action_just_pressed("jump"):
		v.y = jump_power
	else:
		v.y = velocity.y
	
	# Gravity
	v.y += -10.0 * delta
	
	return(v)  

func handle_collision():
	pass


















