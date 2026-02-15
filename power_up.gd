extends Area3D

enum Type {RAPID_FIRE, SHOTGUN, GRENADE, SLOW_BULLETS}
@export var type: Type = Type.RAPID_FIRE
@export var attract_speed = 10.0
@export var attract_range = 6.0

var player = null
var being_collected = false

func _ready():
	# Randomize type if not set manually
	type = Type.values()[randi() % Type.size()]
	
	# Visual indication of type (colors)
	var mat = $MeshInstance3D.get_surface_override_material(0)
	var light = $OmniLight3D
	
	match type:
		Type.RAPID_FIRE:
			mat.albedo_color = Color(1, 0, 0) # Red
			light.light_color = Color(1, 0, 0)
		Type.SHOTGUN:
			mat.albedo_color = Color(0, 1, 0) # Green
			light.light_color = Color(0, 1, 0)
		Type.GRENADE:
			mat.albedo_color = Color(1, 0, 1) # Purple
			light.light_color = Color(1, 0, 1)
		Type.SLOW_BULLETS:
			mat.albedo_color = Color(0, 0.5, 1) # Blue
			light.light_color = Color(0, 0.5, 1)
			
	# Find player
	await get_tree().create_timer(0.1).timeout
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not player: return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist < attract_range:
		being_collected = true
		
	if being_collected:
		var target_pos = player.global_position + Vector3(0, 1.0, 0)
		global_position = global_position.move_toward(target_pos, attract_speed * delta)
		
		if global_position.distance_to(target_pos) < 0.5:
			player.apply_power_up(type)
			queue_free()

	# Spin and float
	rotate_y(3.0 * delta)
	position.y += sin(Time.get_ticks_msec() * 0.005) * 0.005
