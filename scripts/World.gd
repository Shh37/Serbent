extends Node2D

@export var chunk_scene: PackedScene
@export var player: Node2D

var active_chunks = {} # Vector2i -> Chunk node
var view_distance = 2 # Number of chunks around player
var points = {} # Vector2i (global) -> Point node
var thorns = {} # Vector2i (global) -> Thorn node

func _process(_delta):
	if not player:
		return
		
	update_chunks()

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
