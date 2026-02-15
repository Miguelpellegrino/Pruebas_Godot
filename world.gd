extends Node3D

@onready var world_generator = $WorldGenerator
@onready var player = $Player

func _ready():
	# Seed the random number generator for different results each time
	randomize()
	
	# The generator script handles generation in its _ready()
	# We just need to position the player after it's done.
	# Since child _ready runs first, we can access the data now.
	player.global_position = world_generator.get_spawn_position()
