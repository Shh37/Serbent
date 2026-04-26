extends Node2D
class_name Thorn

var grid_pos: Vector2i

func _draw():
	var size = GameConstants.CELL_SIZE
	var rect = Rect2(0, 0, size, size)
	
	# SPEC: Use Red for danger
	var color = GameConstants.COLOR_DANGER
	
	# All elements are strictly square with borders
	draw_rect(rect, color)
	draw_rect(rect, GameConstants.COLOR_BLOCK_BORDER, false, 1.0)

func setup_local(p_local_pos: Vector2i):
	grid_pos = p_local_pos
	position = Vector2(grid_pos) * GameConstants.CELL_SIZE
	queue_redraw()
