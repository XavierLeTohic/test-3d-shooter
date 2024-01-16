extends CharacterBody3D

# Player nodes

@onready var head = $neck/head 
@onready var neck = $neck 
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/Camera3D

# Speed vars

var current_speed = 5.0

const walking_speed = 5.0
const sprinting_speed = 8
const crouching_speed = 3

# States

var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

# Movement vars

var crounching_depth = -0.5

const jump_velocity = 4.5
var lerp_speed = 10

var free_look_tilt_amount = 5

# Input variables

const mouse_sensivity = 0.3
var direction = Vector3.ZERO


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event):
	
	# Mouse looking
	
	if event is InputEventMouseMotion:
		
		if free_looking:
			neck.rotate_y(-deg_to_rad(event.relative.x * mouse_sensivity))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120  ))
		else:
			rotate_y(-deg_to_rad(event.relative.x * mouse_sensivity))
		
		head.rotate_x(-deg_to_rad(event.relative.y * mouse_sensivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(89))

func _physics_process(delta):
	
	# handling movements state
	
	# Crouching
	if Input.is_action_pressed("crouch"):
		
		walking = false
		sprinting = false
		crouching = true
		
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, crounching_depth, delta * lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
	elif !ray_cast_3d.is_colliding(): 
		
		# Standing
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		
		if Input.is_action_pressed("sprint"):
			# Sprinting
			current_speed = sprinting_speed
			
			walking = false
			sprinting = true
			crouching = false
		else:
			# Walking
			current_speed = walking_speed
			
			walking = true
			sprinting = false
			crouching = false
			
	# Free look pressed
	if Input.is_action_pressed("free_look"):
		free_looking = true
		camera_3d.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed);
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta * lerp_speed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
