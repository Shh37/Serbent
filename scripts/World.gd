extends Node2D

@export var chunk_scene: PackedScene
@export var player: Node2D

var active_chunks = {} # Vector2i -> Chunk node
var view_distance = 2 # Number of chunks around player

func _process(_delta):
	if not player:
		return
		
	update_chunks()

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
		active_chunks[cpos].queue_free()
		active_chunks.erase(cpos)

func spawn_chunk(cpos: Vector2i):
	var chunk = Node2D.new()
	chunk.set_script(load("res://scripts/Chunk.gd"))
	add_child(chunk)
	chunk.setup(cpos)
	active_chunks[cpos] = chunk
