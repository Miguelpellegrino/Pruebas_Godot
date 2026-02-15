extends CharacterBody3D

@export var speed = 3.0
@export var health = 20.0

var slow_multiplier = 1.0
var slow_timer = 0.0

@export var gold_scene: PackedScene = preload("res://gold_coin.tscn")
@export var power_up_scene: PackedScene = preload("res://power_up.tscn")

var player = null

func _ready():
	add_to_group("enemy")
	# Find player (wait a bit to ensure player is in tree)
	await get_tree().create_timer(0.1).timeout
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if player:
		var direction = (player.global_position - global_position).normalized()
		direction.y = 0
		
		# Apply slow multiplier
		var current_speed = speed * slow_multiplier
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if slow_timer > 0:
			slow_timer -= delta
			if slow_timer <= 0:
				slow_multiplier = 1.0
		
		# Look at player (smoothly)
		if direction.length() > 0.1:
			var target_basis = Basis.looking_at(direction)
			basis = basis.slerp(target_basis, 0.1)
	
	move_and_slide()

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func apply_slow():
	slow_multiplier = 0.4
	slow_timer = 3.0

func die():
	# Chance of drop
	var roll = randf()
	if roll <= 0.2: # 20% total drop chance
		# 50% chance it's gold, 50% chance it's power-up
		if randf() <= 0.5:
			var gold = gold_scene.instantiate()
			get_tree().root.add_child(gold)
			gold.global_position = global_position + Vector3(0, 0.5, 0)
		else:
			var pu = power_up_scene.instantiate()
			get_tree().root.add_child(pu)
			pu.global_position = global_position + Vector3(0, 0.5, 0)
		
	queue_free()
