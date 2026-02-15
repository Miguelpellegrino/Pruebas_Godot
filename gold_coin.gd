extends Area3D

@export var value = 1
@export var attract_speed = 10.0
@export var attract_range = 5.0

var player = null
var being_collected = false

func _ready():
	# Find player
	await get_tree().create_timer(0.1).timeout
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not player: return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist < attract_range:
		being_collected = true
		
	if being_collected:
		# Move towards player "head/center"
		var target_pos = player.global_position + Vector3(0, 1.0, 0)
		global_position = global_position.move_toward(target_pos, attract_speed * delta)
		
		# If very close, collect
		if global_position.distance_to(target_pos) < 0.5:
			player.add_gold(value)
			queue_free()

	# Visual: spin the coin
	rotate_y(2.0 * delta)
