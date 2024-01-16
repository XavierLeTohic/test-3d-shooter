extends CharacterBody3D

# Player nodes

@onready var neck = $neck 
@onready var head = $neck/head 
@onready var eyes = $neck/head/eyes

@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/eyes/Camera3D

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

# Slide vars

var sliding_timer = 0.0
var sliding_timer_max = 1.0
var sliding_vector = Vector2.ZERO
var sliding_speed = 10.0

# Head bobbings vars

const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

# Movement vars

var crounching_depth = -0.5

const jump_velocity = 4.5
var lerp_speed = 10.0

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
	# Gettign movements inputs
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# handling movements state
	
	# Crouching
	if Input.is_action_pressed("crouch"):
		
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, crounching_depth, delta * lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		# Slide begin logic
	
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			sliding_timer = sliding_timer_max
			sliding_vector = input_dir
			free_looking = true 
			print("slide begins")
		
		walking = false
		sprinting = false
		crouching = true 
		
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
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		
		if sliding:
			camera_3d.rotation.z = lerp(camera_3d.rotation.z, -deg_to_rad(7.0), delta * lerp_speed)
		else:
			camera_3d.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed);
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta * lerp_speed)
	
	# Handle sliding
	if sliding:
		sliding_timer -= delta
		
		if sliding_timer <= 0:
			sliding = 0
			free_looking = false
			print("slide ends")
			
	# Handle head bobbings
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
		
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index / 2) + 0.5 
		
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity / 2.0), delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * head_bobbing_current_intensity, delta * lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * lerp_speed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false

	# Handle the movement/deceleration.
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	
	if sliding:
		direction = (transform.basis * Vector3(sliding_vector.x, 0.0, sliding_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if sliding:
			velocity.x = direction.x * (sliding_timer + 0.1) * sliding_speed
			velocity.z = direction.z * (sliding_timer + 0.1) * sliding_speed 
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
