extends RigidBody3D

@export var explosion_damage = 50.0
@export var explosion_radius = 5.0
@export var fuse_time = 2.0

func _ready():
	await get_tree().create_timer(fuse_time).timeout
	explode()

func explode():
	# Find enemies near explosion
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= explosion_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(explosion_damage)
					
	# Also damage doors
	var doors = get_tree().get_nodes_in_group("door") # Need to add doors to group
	for door in doors:
		if is_instance_valid(door):
			var dist = global_position.distance_to(door.global_position)
			if dist <= explosion_radius:
				if door.has_method("take_damage"):
					door.take_damage(explosion_damage)
					
	# Visual/Queue free
	# Could add a particle effect node here later
	queue_free()
