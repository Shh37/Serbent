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
	queue_redraw()
