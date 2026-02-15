extends Node3D

@export var floor_tile_scene: PackedScene = preload("res://floor_tile.tscn")
@export var wall_tile_scene: PackedScene = preload("res://wall_tile.tscn")
@export var enemy_scene: PackedScene = preload("res://enemy.tscn")
@export var exit_scene: PackedScene = preload("res://exit_portal.tscn")
@export var key_scene: PackedScene = preload("res://key.tscn")
@export var door_scene: PackedScene = preload("res://breakable_door.tscn")

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
	spawn_doors()

func spawn_doors():
	var door_positions = []
	for x in range(1, grid_size - 1):
		for y in range(1, grid_size - 1):
			# We only place doors on corridor tiles (2)
			if grid[x][y] == 2:
				var is_near_room = false
				# Check if any neighbor is a room floor (0)
				for nx in range(x - 1, x + 2):
					for ny in range(y - 1, y + 2):
						if grid[nx][ny] == 0:
							is_near_room = true
							break
					if is_near_room: break
				
				if not is_near_room:
					continue
				
				var wall_axis = -1 # -1: None, 0: X (Horizontal pinch), 1: Y (Vertical pinch)
				
				# Detect "Wall Pinch": Walls on opposite sides?
				# If walls are at X-1 and X+1, the corridor runs Vertical (Y). 
				# Default door width is 4 (X axis), so it blocks it perfectly without rotation.
				if grid[x - 1][y] == 1 and grid[x + 1][y] == 1:
					wall_axis = 0 # Walls are in X axis
				# If walls are at Y-1 and Y+1, the corridor runs Horizontal (X).
				# We rotate 90deg so width blocks Y.
				elif grid[x][y - 1] == 1 and grid[x][y + 1] == 1:
					wall_axis = 1 # Walls are in Y axis
				
				if wall_axis != -1:
					# Proximity filter
					var too_close = false
					for dp in door_positions:
						if dp.distance_to(Vector2i(x, y)) < 3:
							too_close = true
							break
					
					if not too_close:
						var door = door_scene.instantiate()
						add_child(door)
						door.position = Vector3(x * tile_size, 0, y * tile_size)
						
						# If Walls are in Y axis, corridor is X, rotate to block.
						if wall_axis == 1:
							door.rotate_y(PI / 2)
						# Else (walls in X axis), corridor is Y, stays as is.
							
						door_positions.append(Vector2i(x, y))

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
		# Use 2 for corridors, but don't overwrite room floors (0)
		if grid[x][y] == 1:
			grid[x][y] = 2
		x += 1 if end.x > x else -1
	
	while y != end.y:
		if grid[x][y] == 1:
			grid[x][y] = 2
		y += 1 if end.y > y else -1

func spawn_tiles():
	# Clear existing (if any)
	for child in get_children():
		child.queue_free()
	
	for x in range(grid_size):
		for y in range(grid_size):
			var pos = Vector3(x * tile_size, 0, y * tile_size)
			# 0 = Room Floor, 2 = Corridor Floor
			if grid[x][y] == 0 or grid[x][y] == 2:
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
