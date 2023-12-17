extends CharacterBody3D

# Exported Variables
@export var sprint_enabled: bool = true
@export var base_speed: float = 4
@export var sprint_speed: float = 7
@export var jump_velocity: float = 4.0
@export var sensitivity: float = 0.1
@export var accel: float = 2


# Member Variables
var speed: float = base_speed
var state: String = "normal"  # normal, sprinting, crouching
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var antiJordan: float = 8.0

var camera_fov_extents: Array[float] = [85.0, 90.0]  # index 0 is normal, index 1 is sprinting

var base_player_y_scale: float = 1.0
var base_stick_y_pos: float = -0.165

var stickTwist: float = 0
var stickDeke: float = 0
var dekeReachLeft: float = -.6
var dekeReachRight: float = -dekeReachLeft

var stickReach: float = 0
var reachReachFront: float = .5
var reachReachBack: float = 0


# Node References
@onready var parts: Dictionary = {
	"head": $head,
	"camera": $head/camera,
	"camera_animation": $head/camera/camera_animation,
	"body": $body,
	"collision": $"collision body",
	"stick": $stick
}
@onready var world: SceneTree = get_tree()

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	parts["camera"].current = true
	
	
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	handle_jump()
	apply_gravity(delta)
	move_character(delta)
	handle_movement_input(delta)
	handle_stick_raise()
	handle_twerk()
	update_camera(delta)

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			sensitivity = .01
			
			stickTwist -= event.relative.x * .075
			stickTwist = clamp(stickTwist, -20, 200)
			stickDeke -= event.relative.x * .0005
			stickDeke = clamp(stickDeke, dekeReachLeft, dekeReachRight)
			stickReach -= event.relative.y * .001
			stickReach = clamp(stickReach, reachReachBack, reachReachFront)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			sensitivity = .01
			
			stickTwist -= event.relative.x * .075
			stickTwist = clamp(stickTwist, -20, 200)
			
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			sensitivity = .01
			
			stickDeke -= event.relative.x * .0005
			stickReach -= event.relative.y * .001
			stickDeke = clamp(stickDeke, dekeReachLeft, dekeReachRight)
			stickReach = clamp(stickReach, reachReachBack, reachReachFront)
	
		else:
			sensitivity = .1
			
		parts["stick"].rotation_degrees.y = parts["head"].rotation_degrees.y - 90 + stickTwist
		
		parts["stick"].transform.origin.x = (.3) * cos(deg_to_rad(parts["head"].rotation_degrees.y + 90)) - (stickDeke) * cos(deg_to_rad(parts["head"].rotation_degrees.y)) - (stickReach) * sin(deg_to_rad(parts["head"].rotation_degrees.y))
		parts["stick"].transform.origin.z = (.3) * sin(deg_to_rad(parts["head"].rotation_degrees.y - 90)) + (stickDeke) * sin(deg_to_rad(parts["head"].rotation_degrees.y)) - (stickReach) * cos(deg_to_rad(parts["head"].rotation_degrees.y))

		handle_mouse_movement(event)

# Movement Logic
func handle_movement_input(delta: float) -> void:
	if Input.is_action_pressed("move_sprint") and sprint_enabled:
		enter_sprint_state(delta)
	if !Input.is_action_pressed("move_sprint") and sprint_enabled:
		enter_normal_state(delta)

func enter_sprint_state(delta: float) -> void:
	state = "sprinting"
	speed = sprint_speed
	parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[1], 10 * delta)

func enter_normal_state(delta: float) -> void:
	state = "normal"
	speed = base_speed

# Camera Logic
func update_camera(delta: float) -> void:
	match state:
		"sprinting":
			parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[1], 10 * delta)
		"normal":
			parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[0], 10 * delta)

# Physics Logic
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_jump() -> void:
	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity.y += jump_velocity
		
func handle_stick_raise() -> void:
	if Input.is_key_pressed(KEY_ALT) and is_on_floor():
		parts["stick"].transform.origin.y = base_stick_y_pos + .3
	else:
		parts["stick"].transform.origin.y = base_stick_y_pos
	

func move_character(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector2 = input_dir.normalized().rotated(-parts["head"].rotation.y)
	if is_on_floor():
		velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.y * speed, accel * delta)
	move_and_slide()
	var lastX = transform.origin.x
	var lastZ = transform.origin.z
	
	
# Input Handling
func handle_mouse_movement(event: InputEventMouseMotion) -> void:
	if !world.paused:
		parts["head"].rotation_degrees.y -= event.relative.x * sensitivity
		parts["body"].rotation_degrees.y -= event.relative.x * sensitivity
		
		parts["head"].rotation_degrees.x -= event.relative.y * sensitivity
		parts["head"].rotation.x = clamp(parts["head"].rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
func handle_twerk():
	if Input.is_key_pressed(KEY_1):
		rotation_degrees.x = 90
	else:
		rotation_degrees.x = 0
