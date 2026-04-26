extends Node2D

@export var chunk_scene: PackedScene
@export var player: Node2D

var active_chunks = {} # Vector2i -> Chunk node
var view_distance = 2 # Number of chunks around player
var points = {} # Vector2i (global) -> Point node
var thorns = {} # Vector2i (global) -> Thorn node
var active_beams = [] # Array of Beam nodes
var beam_timer = 0.0
var next_beam_time = 3.0 # First beam after 3 seconds

func _process(_delta):
	if not player:
		return
		
	
	update_chunks()
	update_beam_spawning(_delta)

func update_beam_spawning(delta):
	beam_timer += delta
	if beam_timer >= next_beam_time:
		beam_timer = 0.0
		next_beam_time = randf_range(4.0, 8.0) # Spawn every 4-8 seconds
		spawn_random_beam()

func spawn_random_beam():
	if not player:
		return
		
	# Pick a global grid index near the player
	var player_grid_pos = Vector2i(player.position / GameConstants.CELL_SIZE)
	var offset = randi_range(-8, 8) # Within 8 cells of player
	
	var beam = Node2D.new()
	beam.set_script(load("res://scripts/Beam.gd"))
	add_child(beam)
	
	var orientation = Beam.Orientation.HORIZONTAL if randf() > 0.5 else Beam.Orientation.VERTICAL
	var global_index = (player_grid_pos.y if orientation == Beam.Orientation.HORIZONTAL else player_grid_pos.x) + offset
	
	beam.setup(orientation, global_index)
	register_beam(beam)

func register_point(global_pos: Vector2i, point_node: Node):
	points[global_pos] = point_node

func collect_point(global_pos: Vector2i) -> Node:
	if points.has(global_pos):
		var p = points[global_pos]
		points.erase(global_pos)
		p.queue_free()
		return p
	return null

func register_thorn(global_pos: Vector2i, thorn_node: Node):
	thorns[global_pos] = thorn_node

func has_thorn(global_pos: Vector2i) -> bool:
	return thorns.has(global_pos)

func register_beam(beam_node: Node):
	active_beams.append(beam_node)

func unregister_beam(beam_node: Node):
	active_beams.erase(beam_node)

func check_beam_collision(snake: Node):
	for beam in active_beams:
		if beam.is_active:
			var body = snake.body
			var pos = body[0] # Head
			
			if beam.orientation == Beam.Orientation.HORIZONTAL:
				if pos.y == beam.global_grid_index:
					snake.cut_snake(1)
			else:
				if pos.x == beam.global_grid_index:
					snake.cut_snake(1)

func update_chunks():
	var player_grid_pos = Vector2i(
		floor(player.position.x / GameConstants.CHUNK_PIXEL_SIZE),
		floor(player.position.y / GameConstants.CHUNK_PIXEL_SIZE)
	)
	
	var needed_chunks = []
	for x in range(-view_distance, view_distance + 1):
		for y in range(-view_distance, view_distance + 1):
			needed_chunks.append(player_grid_pos + Vector2i(x, y))
			
	# Spawn new chunks
	for cpos in needed_chunks:
		if not active_chunks.has(cpos):
			spawn_chunk(cpos)
			
	# Remove old chunks
	var to_remove = []
	for cpos in active_chunks.keys():
		if cpos not in needed_chunks:
			to_remove.append(cpos)
			
	for cpos in to_remove:
		remove_points_in_chunk(cpos)
		remove_thorns_in_chunk(cpos)
		active_chunks[cpos].queue_free()
		active_chunks.erase(cpos)

func remove_points_in_chunk(cpos: Vector2i):
	var chunk_start = cpos * GameConstants.CHUNK_SIZE
	var chunk_end = chunk_start + Vector2i(GameConstants.CHUNK_SIZE, GameConstants.CHUNK_SIZE)
	
	var to_erase = []
	for ppos in points.keys():
		if ppos.x >= chunk_start.x and ppos.x < chunk_end.x and \
		   ppos.y >= chunk_start.y and ppos.y < chunk_end.y:
			to_erase.append(ppos)
			
	for ppos in to_erase:
		points.erase(ppos)

func remove_thorns_in_chunk(cpos: Vector2i):
	var chunk_start = cpos * GameConstants.CHUNK_SIZE
	var chunk_end = chunk_start + Vector2i(GameConstants.CHUNK_SIZE, GameConstants.CHUNK_SIZE)
	
	var to_erase = []
	for tpos in thorns.keys():
		if tpos.x >= chunk_start.x and tpos.x < chunk_end.x and \
		   tpos.y >= chunk_start.y and tpos.y < chunk_end.y:
			to_erase.append(tpos)
			
	for tpos in to_erase:
		thorns.erase(tpos)

func spawn_chunk(cpos: Vector2i):
	var chunk = Node2D.new()
	chunk.set_script(load("res://scripts/Chunk.gd"))
	add_child(chunk)
	chunk.setup(cpos)
	active_chunks[cpos] = chunk
