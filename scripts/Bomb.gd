extends Node2D
class_name Bomb

var center_grid_pos: Vector2i
var warning_time = 2.0
var active_time = 0.5
var timer = 0.0
var is_active = false
var flicker_speed = 0.1
var flicker_timer = 0.0
var show_warning = true

func setup(p_center_grid_pos: Vector2i):
	center_grid_pos = p_center_grid_pos
	timer = warning_time
	queue_redraw()

func _process(delta):
	timer -= delta
	
	if not is_active:
		flicker_timer += delta
		if flicker_timer >= flicker_speed:
			flicker_timer = 0.0
			show_warning = !show_warning
			queue_redraw()
			
		if timer <= 0:
			activate_bomb()
	else:
		if timer <= 0:
			deactivate_bomb()

func activate_bomb():
	is_active = true
	timer = active_time
	show_warning = true
	queue_redraw()
	
	# Check collision immediately when activated
	check_collision()

func deactivate_bomb():
	# Bomb finished, remove it
	var world = get_parent()
	if world.has_method("unregister_bomb"):
		world.unregister_bomb(self)
	queue_free()

func check_collision():
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	if snake and snake.has_method("cut_snake"):
		var body = snake.body
		var half_size = GameConstants.BOMB_SIZE / 2
		
		# Check if any segment is within the explosion range
		for i in range(body.size()):
			var pos = body[i]
			if abs(pos.x - center_grid_pos.x) <= half_size and \
			   abs(pos.y - center_grid_pos.y) <= half_size:
				snake.cut_snake(i)
				break

func _draw():
	var cell_size = GameConstants.CELL_SIZE
	var color = GameConstants.COLOR_DANGER
	var half_size = GameConstants.BOMB_SIZE / 2
	var size = GameConstants.BOMB_SIZE
	
	var rect = Rect2(
		Vector2(center_grid_pos - Vector2i(half_size, half_size)) * cell_size,
		Vector2(size, size) * cell_size
	)
	
	if is_active:
		# Draw the actual explosion
		draw_rect(rect, color)
	elif show_warning:
		# Draw warning area (faint red)
		var warning_color = color
		warning_color.a = 0.2
		draw_rect(rect, warning_color)
