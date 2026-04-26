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
	var used_positions = spawn_points()
	spawn_thorns(used_positions)
	spawn_diamond_thorns(used_positions)
	queue_redraw()

func spawn_points() -> Dictionary:
	# Randomly spawn 2-4 points per chunk
	var num_points = randi_range(2, 4)
	var used_positions = {}
	
	for i in range(num_points):
		var local_pos = Vector2i(
			randi_range(0, GameConstants.CHUNK_SIZE - 1),
			randi_range(0, GameConstants.CHUNK_SIZE - 1)
		)
		
		if used_positions.has(local_pos):
			continue
		used_positions[local_pos] = true
		
		var global_pos = chunk_pos * GameConstants.CHUNK_SIZE + local_pos
		
		var point = Node2D.new()
		point.set_script(load("res://scripts/Point.gd"))
		add_child(point)
		
		var type = Point.Type.NORMAL
		var r = randf()
		if r > 0.85: type = Point.Type.LARGE # 15% chance
		elif r > 0.65: type = Point.Type.MEDIUM # 20% chance
		
		point.setup_local(local_pos, type)
		
		# Register point in World for collision
		var world = get_parent()
		if world.has_method("register_point"):
			world.register_point(global_pos, point)
	
	return used_positions

func spawn_thorns(used_positions: Dictionary):
	# Randomly spawn 3-6 thorns per chunk
	var num_thorns = randi_range(3, 6)
	
	for i in range(num_thorns):
		var local_pos = Vector2i(
			randi_range(0, GameConstants.CHUNK_SIZE - 1),
			randi_range(0, GameConstants.CHUNK_SIZE - 1)
		)
		
		if used_positions.has(local_pos):
			continue
		used_positions[local_pos] = true
		
		var global_pos = chunk_pos * GameConstants.CHUNK_SIZE + local_pos
		
		var thorn = Node2D.new()
		thorn.set_script(load("res://scripts/Thorn.gd"))
		add_child(thorn)
		
		thorn.setup_local(local_pos)
		
		# Register thorn in World for collision
		var world = get_parent()
		if world.has_method("register_thorn"):
			world.register_thorn(global_pos, thorn)

func spawn_diamond_thorns(used_positions: Dictionary):
	# Chance to spawn 1-2 diamond clusters in this chunk
	var num_clusters = 0
	if randf() < 0.8: num_clusters += 1
	if randf() < 0.4: num_clusters += 1
	
	for c in range(num_clusters):
		var center = Vector2i(
			randi_range(2, GameConstants.CHUNK_SIZE - 3),
			randi_range(2, GameConstants.CHUNK_SIZE - 3)
		)
		
		var radius = randi_range(1, 2)
		var offsets = get_diamond_offsets(radius)
		
		for offset in offsets:
			var local_pos = center + offset
			
			# Boundary check
			if local_pos.x < 0 or local_pos.x >= GameConstants.CHUNK_SIZE or \
			   local_pos.y < 0 or local_pos.y >= GameConstants.CHUNK_SIZE:
				continue
				
			if used_positions.has(local_pos):
				continue
			used_positions[local_pos] = true
			
			var global_pos = chunk_pos * GameConstants.CHUNK_SIZE + local_pos
			
			var thorn = Node2D.new()
			thorn.set_script(load("res://scripts/Thorn.gd"))
			add_child(thorn)
			
			thorn.setup_local(local_pos)
			
			var world = get_parent()
			if world.has_method("register_thorn"):
				world.register_thorn(global_pos, thorn)

func get_diamond_offsets(radius: int) -> Array:
	var offsets = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if abs(x) + abs(y) <= radius:
				offsets.append(Vector2i(x, y))
	return offsets
