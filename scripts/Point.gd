extends Node2D
class_name Point

var grid_pos: Vector2i

var flash_time = 0.0

func _process(delta):
	var snake = get_tree().root.find_child("Snake", true, false)
	if snake and snake.active_powerups.has(GameConstants.PowerUpType.DOUBLE_GROWTH):
		flash_time += delta
		queue_redraw()
	elif flash_time != 0:
		flash_time = 0.0
		queue_redraw()

func _draw():
	var size = GameConstants.CELL_SIZE
	var rect = Rect2(0, 0, size, size)
	
	var color = GameConstants.COLOR_POINT_NORMAL
	
	var snake = get_tree().root.find_child("Snake", true, false)
	if snake and snake.active_powerups.has(GameConstants.PowerUpType.DOUBLE_GROWTH):
		# Flash effect: pulse brightness AND scale
		var pulse = (sin(flash_time * 4.0) + 1.0) * 0.5 # 0.0 to 1.0
		# Moderate multiplicative boost to keep the yellow hue (high luminance)
		var boost = 1.0 + pulse * 0.8 
		color = Color(color.r * boost, color.g * boost, color.b * boost).clamp()
		
		# Expanded glow effect
		var glow_expand = pulse * size * 0.4
		var glow_rect = Rect2(-glow_expand/2, -glow_expand/2, size + glow_expand, size + glow_expand)
		var glow_color = color
		glow_color.a = 0.3 * pulse
		draw_rect(glow_rect, glow_color)
			
	draw_rect(rect, color)



	draw_rect(rect, GameConstants.COLOR_BLOCK_BORDER, false, 1.0)


func setup_local(p_local_pos: Vector2i):
	grid_pos = p_local_pos
	position = Vector2(grid_pos) * GameConstants.CELL_SIZE
	queue_redraw()

func setup_global(p_global_pos: Vector2i):
	grid_pos = p_global_pos
	position = Vector2(grid_pos) * GameConstants.CELL_SIZE
	queue_redraw()
