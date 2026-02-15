extends StaticBody3D

@export var health = 30.0

func _ready():
	add_to_group("door")

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	# Potential for particles or sounds here
	queue_free()
