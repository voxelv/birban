extends KinematicBody

export var speed : float = 20
export var air_speed : float = 20
export var acceleration : float = 15
export var air_acceleration : float = 5
export var gravity : float = 0.98
export var max_terminal_velocity : float = 54
export var jump_power : float = 20
export var flap_power : float = 2

export(float, 0.1, 1.0) var mouse_sensitivity := 0.3
#@export_range(-90.0, 0.0)
var min_pitch := -50.0
export(float, 0.0, 90.0) var max_pitch := 50.0

var velocity : Vector3
var y_velocity : float

var mouse_captured := false

onready var camera_pivot := find_node("camera_pivot") as Spatial
onready var camera := find_node("camera") as Camera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true
		
func _input(event):
	if event is InputEventMouseMotion:
		if mouse_captured:
			rotation_degrees.y -= event.relative.x * mouse_sensitivity
			camera_pivot.rotation_degrees.x -= event.relative.y * mouse_sensitivity
			camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, min_pitch, max_pitch)

func _physics_process(delta):
	handle_movement(delta)

func handle_movement(delta):
	var direction = Vector3()
	
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
		
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	
	direction = direction.normalized()
	
	if is_on_floor():
		velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	else:
		velocity = velocity.linear_interpolate(direction * air_speed, air_acceleration * delta)
	
	if is_on_floor():
		y_velocity = -0.01
	else:
		y_velocity = clamp(y_velocity - gravity, -max_terminal_velocity, max_terminal_velocity)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		y_velocity = jump_power
	elif Input.is_action_just_pressed("jump"):
		y_velocity = flap_power
	
	velocity.y = y_velocity
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if translation.y < -125.0:
		var pos = get_parent().find_node("player_spawn").translation
		translation = pos
		velocity = Vector3.ZERO