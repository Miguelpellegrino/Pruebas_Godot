extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 10.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.003

@export var max_stamina = 100.0
@export var stamina_drain_rate = 30.0
@export var stamina_regen_rate = 20.0

@export var projectile_scene: PackedScene = preload("res://projectile.tscn")
@export var grenade_scene: PackedScene = preload("res://grenade.tscn")
@export var shoot_cooldown = 0.2
var last_shoot_time = 0.0

# Permanent Power-ups
var has_rapid_fire = false
var has_shotgun = false
var has_grenades = false
var has_slow_bullets = false

var current_stamina = 100.0
var is_sprinting = false
var has_key = false
var gold_count = 0

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var stamina_bar = $CanvasLayer/Control/ProgressBar
@onready var muzzle = $CameraPivot/Muzzle
@onready var win_screen = $CanvasLayer/WinScreen
@onready var restart_button = $CanvasLayer/WinScreen/RestartButton
@onready var key_indicator = $CanvasLayer/Control/KeyIndicator
@onready var message_label = $CanvasLayer/MessageLabel
@onready var gold_label = $CanvasLayer/Control/GoldLabel

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_input_map()
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	_update_gold_ui()
	
	restart_button.pressed.connect(_on_restart_pressed)

func add_gold(amount):
	gold_count += amount
	_update_gold_ui()

func apply_power_up(type):
	match type:
		0: # RAPID_FIRE
			has_rapid_fire = true
			display_message("🔥 ¡DISPARO RÁPIDO PERMANENTE!")
		1: # SHOTGUN
			has_shotgun = true
			display_message("🧹 ¡ESCOPETA PERMANENTE!")
		2: # GRENADE
			has_grenades = true
			display_message("💣 ¡GRANADAS PERMANENTES!")
		3: # SLOW_BULLETS
			has_slow_bullets = true
			display_message("❄️ ¡BALAS DE HIELO PERMANENTES!")

func _update_gold_ui():
	gold_label.text = "ORO: " + str(gold_count)

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
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if has_grenades:
				throw_grenade()

func shoot():
	var current_time = Time.get_ticks_msec() / 1000.0
	var effective_cooldown = shoot_cooldown
	if has_rapid_fire:
		effective_cooldown *= 0.4
		
	if current_time - last_shoot_time < effective_cooldown:
		return
	
	last_shoot_time = current_time
	
	if has_shotgun:
		# Shotgun: 3 projectiles in a fan
		for i in range(-1, 2):
			_spawn_projectile(i * 0.15)
	else:
		_spawn_projectile(0)

func _spawn_projectile(angle_offset):
	var p = projectile_scene.instantiate()
	get_tree().root.add_child(p)
	p.global_position = muzzle.global_position
	
	if has_slow_bullets:
		p.is_slow = true
	
	# Rotate basis for spread
	var target_dir = - camera.global_transform.basis.z
	if angle_offset != 0:
		target_dir = target_dir.rotated(Vector3.UP, angle_offset)
	
	p.look_at(camera.global_position + target_dir * 100.0)

func throw_grenade():
	var g = grenade_scene.instantiate()
	get_tree().root.add_child(g)
	g.global_position = muzzle.global_position
	
	# Apply impulse in looking direction
	var direction = - camera.global_transform.basis.z + Vector3.UP * 0.5
	g.apply_central_impulse(direction.normalized() * 15.0)

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
