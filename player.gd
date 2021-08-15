extends KinematicBody

# Parameter exports
export var gravity : float = 0.98

# On Ground exports
export var speed : float = 1
export var acceleration : float = 1
export var jump_power : float = 1

# In Air exports
export var thrust_power : float = 1
export var drag_coef : float = 1
export var lift_coef : float = 1
export var mass : float = 1

# Camera exports
export(float, 0.1, 1.0) var mouse_sensitivity := 0.3
export(float, -90.0, 0.0) var min_pitch := -50.0
export(float, 0.0, 90.0) var max_pitch := 50.0

# On Ground
var velocity : Vector3
var y_velocity : float

# In Air
var lift := 0.0
var drag := 0.0
var thrust := 0.0
var weight := 0.0

# Camera
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
			camera_pivot.rotation_degrees.y -= event.relative.x * mouse_sensitivity
			camera_pivot.rotation_degrees.x -= event.relative.y * mouse_sensitivity
			camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, min_pitch, max_pitch)

func _physics_process(delta):
	handle_movement(delta)

func handle_movement(delta):
	var direction = Vector3()
	
	if Input.is_action_pressed("move_forward"):
		direction -= camera_pivot.transform.basis.z
	
	if Input.is_action_pressed("move_backward"):
		direction += camera_pivot.transform.basis.z
		
	if Input.is_action_pressed("move_left"):
		direction -= camera_pivot.transform.basis.x
	
	if Input.is_action_pressed("move_right"):
		direction += camera_pivot.transform.basis.x
	
	direction = direction.normalized()
	
	if is_on_floor():
		velocity = handle_on_ground_movement(direction, delta)
	else:
		velocity = handle_in_air_movement(direction, delta)
	
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if translation.y < -125.0:
		var pos = get_parent().find_node("player_spawn").translation
		translation = pos
		velocity = Vector3.ZERO

func handle_on_ground_movement(direction, delta):
	var v = velocity
	
	v = v.linear_interpolate(direction * speed, acceleration * delta)
	y_velocity = -0.01
	
	if Input.is_action_just_pressed("jump"):
		y_velocity = jump_power
		
	v.y = y_velocity
	
	return(v)

func handle_in_air_movement(direction, delta):
	var v = velocity
	var use_wings : bool = Input.is_action_pressed("jump")
	
	print("s: %f h: %f" % [-v.z, translation.y])
	
	var weight_force = mass * gravity
	var lift_force = lift_coef * abs(v.z * v.z)
	
	var drag_force = drag_coef * abs(v.z * v.z)
	var thrust_force = 0.0
	if use_wings:
		thrust_force = thrust_power
	
	# Gravity: v(t) = a*t + v0
	var vert_accel = (lift_force - weight_force) / mass
	v.y = vert_accel * delta + v.y
	
	# Thrust/Drag
	var trajectory_accel = (thrust_force - drag_force) / mass
	v.z = -trajectory_accel * delta + v.z
	
	return(v)  

