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
	spawn_points()
	queue_redraw()

func spawn_points():
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
		
		# Avoid spawning on chunk borders (optional, but looks cleaner)
		# Or just spawn anywhere.
		
		var point = Node2D.new()
		point.set_script(load("res://scripts/Point.gd"))
		add_child(point)
		# Points are children of Chunk, but Point.gd uses absolute grid pos for positioning.
		# Wait, if Point is child of Chunk, it should use local pos.
		# Let's adjust Point.gd setup to take local pos if it's a child.
		
		var type = Point.Type.NORMAL
		var r = randf()
		if r > 0.85: type = Point.Type.LARGE # 15% chance
		elif r > 0.65: type = Point.Type.MEDIUM # 20% chance
		
		point.setup_local(local_pos, type)
		
		# Register point in World for collision
		var world = get_parent()
		if world.has_method("register_point"):
			world.register_point(global_pos, point)
