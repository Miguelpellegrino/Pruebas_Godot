extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 10.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.003

@export var max_stamina = 100.0
@export var stamina_drain_rate = 30.0
@export var stamina_regen_rate = 20.0

@export var projectile_scene: PackedScene = preload("res://projectile.tscn")
@export var shoot_cooldown = 0.2
var last_shoot_time = 0.0

var current_stamina = 100.0
var is_sprinting = false
var has_key = false

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var stamina_bar = $CanvasLayer/Control/ProgressBar
@onready var muzzle = $CameraPivot/Muzzle
@onready var win_screen = $CanvasLayer/WinScreen
@onready var restart_button = $CanvasLayer/WinScreen/RestartButton
@onready var key_indicator = $CanvasLayer/Control/KeyIndicator
@onready var message_label = $CanvasLayer/MessageLabel

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_input_map()
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _setup_input_map():
	var inputs = {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"jump": KEY_SPACE,
		"sprint": KEY_SHIFT
	}
	
	for action in inputs:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event = InputEventKey.new()
			event.physical_keycode = inputs[action]
			InputMap.action_add_event(action, event)

func _input(event):
	if win_screen.visible:
		return
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Horizontal rotation (rotate character)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical rotation (rotate pivot/head)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			shoot()

func shoot():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_shoot_time < shoot_cooldown:
		return
	
	last_shoot_time = current_time
	
	# Instance the projectile
	var p = projectile_scene.instantiate()
	get_tree().root.add_child(p)
	
	# Positioning: Spawn at Muzzle location.
	p.global_position = muzzle.global_position
	
	# Direction: Same as camera looking direction.
	p.look_at(camera.global_position - camera.global_transform.basis.z * 100.0)

func collect_key():
	has_key = true
	key_indicator.visible = true
	display_message("¡LLAVE ENCONTRADA! Busca la salida.")

func display_message(text: String):
	message_label.text = text
	# Clear message after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if message_label.text == text:
		message_label.text = ""

func win():
	if not has_key:
		display_message("NECESITAS LA LLAVE PARA SALIR")
		return
		
	win_screen.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get movement speed logic
	var current_speed = walk_speed
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor() and current_stamina > 0 and input_dir.length() > 0
	
	if is_sprinting:
		current_speed = sprint_speed
		current_stamina -= stamina_drain_rate * delta
	else:
		current_stamina += stamina_regen_rate * delta
	
	current_stamina = clamp(current_stamina, 0, max_stamina)
	stamina_bar.value = current_stamina

	# Get the input direction and handle the movement/deceleration.
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
