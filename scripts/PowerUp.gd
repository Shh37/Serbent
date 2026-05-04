extends Node2D
class_name PowerUp

var type: GameConstants.PowerUpType = GameConstants.PowerUpType.GHOST
var grid_pos: Vector2i

func _draw():
	var size = GameConstants.CELL_SIZE
	var rect = Rect2(0, 0, size, size)
	
	var color = GameConstants.COLOR_POWERUP_GHOST
	match type:
		GameConstants.PowerUpType.TIME_STOP: color = GameConstants.COLOR_POWERUP_TIME
		GameConstants.PowerUpType.DOUBLE_GROWTH: color = GameConstants.COLOR_POWERUP_GROWTH

			
	draw_rect(rect, color)
	draw_rect(rect, GameConstants.COLOR_BLOCK_BORDER, false, 1.0)


func setup_local(p_local_pos: Vector2i, p_type: GameConstants.PowerUpType):
	type = p_type
	grid_pos = p_local_pos
	position = Vector2(grid_pos) * GameConstants.CELL_SIZE
	queue_redraw()
