extends Node2D

var chunk_pos: Vector2i # In chunk units

func _ready():
	z_index = -1 # Draw below snake

func _draw():
	var size = GameConstants.CHUNK_PIXEL_SIZE
	
	# Background
	draw_rect(Rect2(0, 0, size, size), GameConstants.COLOR_BG)
	
	# Grid lines (Block borders)
	for i in range(GameConstants.CHUNK_SIZE + 1):
		var pos = i * GameConstants.CELL_SIZE
		# Vertical
		draw_line(Vector2(pos, 0), Vector2(pos, size), GameConstants.COLOR_BLOCK_BORDER, 1.0)
		# Horizontal
		draw_line(Vector2(0, pos), Vector2(size, pos), GameConstants.COLOR_BLOCK_BORDER, 1.0)
	
	# Chunk border (Thicker)
	draw_rect(Rect2(0, 0, size, size), GameConstants.COLOR_CHUNK_BORDER, false, 4.0)

func setup(p_chunk_pos: Vector2i):
	chunk_pos = p_chunk_pos
	position = Vector2(chunk_pos) * GameConstants.CHUNK_PIXEL_SIZE
	var used_positions = {}
	
	# Order: Clusters -> Points -> Single Thorns
	spawn_cluster_thorns(used_positions)
	spawn_points(used_positions)
	spawn_thorns(used_positions)
	
	queue_redraw()

func is_pos_safe(pos: Vector2i, used_positions: Dictionary, min_dist: int) -> bool:
	for dx in range(-min_dist, min_dist + 1):
		for dy in range(-min_dist, min_dist + 1):
			if used_positions.has(pos + Vector2i(dx, dy)):
				return false
	return true

func spawn_points(used_positions: Dictionary):
	# Randomly spawn 2-4 points per chunk
	var num_points = randi_range(2, 4)
	
	for i in range(num_points):
		var attempts = 0
		while attempts < 20:
			var local_pos = Vector2i(
				randi_range(1, GameConstants.CHUNK_SIZE - 2),
				randi_range(1, GameConstants.CHUNK_SIZE - 2)
			)
			
			if is_pos_safe(local_pos, used_positions, 2):
				used_positions[local_pos] = true
				var global_pos = chunk_pos * GameConstants.CHUNK_SIZE + local_pos
				
				var point = Node2D.new()
				point.set_script(load("res://scripts/Point.gd"))
				add_child(point)
				
				var type = Point.Type.NORMAL
				var r = randf()
				if r > 0.85: type = Point.Type.LARGE
				elif r > 0.65: type = Point.Type.MEDIUM
				
				point.setup_local(local_pos, type)
				
				var world = get_parent()
				if world.has_method("register_point"):
					world.register_point(global_pos, point)
				break
			attempts += 1

func spawn_thorns(used_positions: Dictionary):
	# Randomly spawn 3-5 single thorns per chunk
	var num_thorns = randi_range(3, 5)
	
	for i in range(num_thorns):
		var attempts = 0
		while attempts < 20:
			var local_pos = Vector2i(
				randi_range(1, GameConstants.CHUNK_SIZE - 2),
				randi_range(1, GameConstants.CHUNK_SIZE - 2)
			)
			
			if is_pos_safe(local_pos, used_positions, 1):
				used_positions[local_pos] = true
				var global_pos = chunk_pos * GameConstants.CHUNK_SIZE + local_pos
				
				var thorn = Node2D.new()
				thorn.set_script(load("res://scripts/Thorn.gd"))
				add_child(thorn)
				
				thorn.setup_local(local_pos)
				
				var world = get_parent()
				if world.has_method("register_thorn"):
					world.register_thorn(global_pos, thorn)
				break
			attempts += 1

func spawn_cluster_thorns(used_positions: Dictionary):
	# Chance to spawn 1-2 thorn clusters in this chunk
	var num_clusters = 0
	var r_cluster = randf()
	if r_cluster > 0.8: num_clusters = 2
	elif r_cluster > 0.4: num_clusters = 1
	
	for i in range(num_clusters):
		var attempts = 0
		while attempts < 20:
			var center = Vector2i(
				randi_range(2, GameConstants.CHUNK_SIZE - 3),
				randi_range(2, GameConstants.CHUNK_SIZE - 3)
			)
			
			var offsets = []
			var type_r = randf()
			if type_r > 0.7:
				# 5x5 Cross (hollow center)
				offsets = get_cross_offsets(2, true)
			else:
				# Diamond (hollow)
				var radius = randi_range(1, 2)
				offsets = get_diamond_offsets(radius, true)
			
			# Check if any offset is blocked
			var can_place = true
			for offset in offsets:
				if not is_pos_safe(center + offset, used_positions, 1):
					can_place = false
					break
			
			if can_place:
				for offset in offsets:
					var local_pos = center + offset
					used_positions[local_pos] = true
					
					var global_pos = chunk_pos * GameConstants.CHUNK_SIZE + local_pos
					
					var thorn = Node2D.new()
					thorn.set_script(load("res://scripts/Thorn.gd"))
					add_child(thorn)
					
					thorn.setup_local(local_pos)
					
					var world = get_parent()
					if world.has_method("register_thorn"):
						world.register_thorn(global_pos, thorn)
				break
			attempts += 1

func get_diamond_offsets(radius: int, hollow: bool = false) -> Array:
	var offsets = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var dist = abs(x) + abs(y)
			if hollow:
				if dist == radius:
					offsets.append(Vector2i(x, y))
			else:
				if dist <= radius:
					offsets.append(Vector2i(x, y))
	return offsets

func get_cross_offsets(radius: int, hollow: bool = false) -> Array:
	var offsets = []
	for i in range(-radius, radius + 1):
		if i == 0:
			if not hollow:
				offsets.append(Vector2i(0, 0))
			continue
		offsets.append(Vector2i(i, 0))
		offsets.append(Vector2i(0, i))
	return offsets

func _exit_tree():
	pass
