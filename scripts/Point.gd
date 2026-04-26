extends Node2D
class_name Point

enum Type { NORMAL, MEDIUM, LARGE }
var type: Type = Type.NORMAL
var grid_pos: Vector2i

func _draw():
	var size = GameConstants.CELL_SIZE
	var rect = Rect2(0, 0, size, size)
	
	var color = GameConstants.COLOR_POINT_NORMAL
	match type:
		Type.MEDIUM: color = GameConstants.COLOR_POINT_MEDIUM
		Type.LARGE: color = GameConstants.COLOR_POINT_LARGE
			
	# For points, let's make them slightly smaller than the cell or change their appearance
	# But SPEC says "all elements are strictly square"
	# Maybe different border or slight inset?
	# Let's just use the color for now.
	
	draw_rect(rect, color)
	draw_rect(rect, GameConstants.COLOR_BLOCK_BORDER, false, 1.0)

func setup_local(p_local_pos: Vector2i, p_type: Type):
	type = p_type
	grid_pos = p_local_pos
	position = Vector2(grid_pos) * GameConstants.CELL_SIZE
	queue_redraw()
