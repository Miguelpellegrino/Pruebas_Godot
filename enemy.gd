extends CharacterBody3D

@export var speed = 3.0
@export var health = 20.0

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
		direction.y = 0 # Keep movement on horizontal plane
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# Look at player (smoothly)
		if direction.length() > 0.1:
			var target_basis = Basis.looking_at(direction)
			basis = basis.slerp(target_basis, 0.1)
	
	move_and_slide()

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	# You could add effects here
	queue_free()
