extends Node2D
class_name Point

var grid_pos: Vector2i

func _draw():
	var size = GameConstants.CELL_SIZE
	var rect = Rect2(0, 0, size, size)
	
	var color = GameConstants.COLOR_POINT_NORMAL
			
	# For points, let's make them slightly smaller than the cell or change their appearance
	# But SPEC says "all elements are strictly square"
	# Maybe different border or slight inset?
	# Let's just use the color for now.
	
	draw_rect(rect, color)
	draw_rect(rect, GameConstants.COLOR_BLOCK_BORDER, false, 1.0)

func setup_local(p_local_pos: Vector2i):
	grid_pos = p_local_pos
	position = Vector2(grid_pos) * GameConstants.CELL_SIZE
	queue_redraw()
