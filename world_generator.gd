extends Node3D

@export var floor_tile_scene: PackedScene = preload("res://floor_tile.tscn")
@export var wall_tile_scene: PackedScene = preload("res://wall_tile.tscn")
@export var enemy_scene: PackedScene = preload("res://enemy.tscn")
@export var exit_scene: PackedScene = preload("res://exit_portal.tscn")
@export var key_scene: PackedScene = preload("res://key.tscn")

@export var grid_size = 50
@export var tile_size = 4.0
@export var room_count = 15
@export var min_room_size = 4
@export var max_room_size = 10
@export var enemies_per_room = 1

var grid = []
var rooms = []

func _ready():
	generate_dungeon()

func generate_dungeon():
	# Initialize grid with walls (1)
	grid = []
	for x in range(grid_size):
		grid.append([])
		for y in range(grid_size):
			grid[x].append(1)
	
	rooms = []
	for i in range(room_count):
		var rw = randi_range(min_room_size, max_room_size)
		var rh = randi_range(min_room_size, max_room_size)
		var rx = randi_range(1, grid_size - rw - 1)
		var ry = randi_range(1, grid_size - rh - 1)
		
		var new_room = Rect2i(rx, ry, rw, rh)
		
		# For simplicity, we just carve them. Overlap is fine for roguelike "feel"
		carve_room(new_room)
		
		if rooms.size() > 0:
			var prev_room = rooms[rooms.size() - 1]
			carve_corridor(prev_room.get_center(), new_room.get_center())
		
		rooms.append(new_room)
	
	spawn_tiles()
	spawn_enemies()
	spawn_key()
	spawn_exit()

func spawn_key():
	if rooms.size() > 2:
		# Pick a random room that is not the first (player spawn) or the last (exit)
		var key_room_index = randi_range(1, rooms.size() - 2)
		var room = rooms[key_room_index]
		
		var key = key_scene.instantiate()
		add_child(key)
		
		var center = room.get_center()
		key.position = Vector3(center.x * tile_size, 0.8, center.y * tile_size)

func spawn_exit():
	if rooms.size() > 0:
		var last_room = rooms[rooms.size() - 1]
		var exit = exit_scene.instantiate()
		add_child(exit)
		
		var center = last_room.get_center()
		exit.position = Vector3(center.x * tile_size, 0.1, center.y * tile_size)

func spawn_enemies():
	# Skip the first room (index 0) where the player spawns
	for i in range(1, rooms.size()):
		var room = rooms[i]
		for j in range(enemies_per_room):
			var enemy = enemy_scene.instantiate()
			add_child(enemy)
			
			# Random position within the room
			var rx = randi_range(room.position.x, room.end.x - 1)
			var ry = randi_range(room.position.y, room.end.y - 1)
			enemy.position = Vector3(rx * tile_size, 0.5, ry * tile_size)

func carve_room(room: Rect2i):
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			grid[x][y] = 0

func carve_corridor(start: Vector2i, end: Vector2i):
	# Horizontal then Vertical
	var x = start.x
	var y = start.y
	
	while x != end.x:
		grid[x][y] = 0
		x += 1 if end.x > x else -1
	
	while y != end.y:
		grid[x][y] = 0
		y += 1 if end.y > y else -1

func spawn_tiles():
	# Clear existing (if any)
	for child in get_children():
		child.queue_free()
	
	for x in range(grid_size):
		for y in range(grid_size):
			var pos = Vector3(x * tile_size, 0, y * tile_size)
			if grid[x][y] == 0:
				var floor_tile = floor_tile_scene.instantiate()
				add_child(floor_tile)
				floor_tile.position = pos
			else:
				var wall_tile = wall_tile_scene.instantiate()
				add_child(wall_tile)
				wall_tile.position = pos

func get_spawn_position() -> Vector3:
	if rooms.size() > 0:
		var center = rooms[0].get_center()
		return Vector3(center.x * tile_size, 0.5, center.y * tile_size)
	return Vector3(0, 0.5, 0)
