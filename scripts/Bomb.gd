extends Node2D
class_name Bomb

var center_grid_pos: Vector2i
var warning_time = 2.0
var active_time = 0.5
var timer = 0.0
var is_active = false
var flicker_timer = 0.0
var show_warning = true
var radius = 2

func get_current_flicker_speed() -> float:
	# Faster blinking as timer decreases
	return lerp(0.04, 0.2, clamp(timer / warning_time, 0.0, 1.0))

func setup(p_center_grid_pos: Vector2i, p_radius: int = 2):
	z_as_relative = false
	z_index = GameConstants.Z_INDEX_HAZARD
	center_grid_pos = p_center_grid_pos
	radius = p_radius
	timer = warning_time
	queue_redraw()

func _process(delta):
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake") if world else null
	if (snake and snake.is_reversing) or (world and world.is_time_stopped and not is_active):
		return # Pause countdown during reverse or time stop
	
	timer -= delta
	
	if not is_active:
		flicker_timer += delta
		var current_flicker_speed = get_current_flicker_speed()
		if flicker_timer >= current_flicker_speed:
			flicker_timer = 0.0
			show_warning = !show_warning
			queue_redraw()
			
		if timer <= 0:
			activate_bomb()
	else:
		queue_redraw() # Continually redraw for flash fade effect
		if timer <= 0:
			deactivate_bomb()

func activate_bomb():
	is_active = true
	timer = active_time
	show_warning = true
	queue_redraw()
	
	# Check collision immediately when activated
	if not check_collision():
		SoundManager.play_explosion()

func deactivate_bomb():
	# Bomb finished, remove it
	var world = get_parent()
	if world.has_method("unregister_bomb"):
		world.unregister_bomb(self)
	queue_free()

func check_collision() -> bool:
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	if snake and snake.has_method("cut_snake"):
		var body = snake.body
		var hit_indices = []
		
		# Check if any segment is within the diamond-shaped explosion range
		for i in range(body.size()):
			var pos = body[i]
			var dx = abs(pos.x - center_grid_pos.x)
			var dy = abs(pos.y - center_grid_pos.y)
			if dx + dy <= radius:
				hit_indices.append(i)
		
		if not hit_indices.is_empty():
			snake.cut_snake(hit_indices[0], hit_indices)
			return true
	return false

func _draw():
	var cell_size = GameConstants.CELL_SIZE
	var color = GameConstants.COLOR_DANGER
	
	var warning_color = color
	if is_active:
		var flash_ratio = clamp(timer / active_time, 0.0, 1.0)
		# Boost brightness (especially red) to create a glowing effect without turning pure white
		var boost = flash_ratio * 1.5
		warning_color = Color(color.r + boost, color.g + boost * 0.2, color.b + boost * 0.2)
		warning_color.a = flash_ratio
	else:
		# Blink between dark red (low alpha) and light red (higher alpha)
		warning_color.a = 0.5 if show_warning else 0.15
	
	if true: # Always draw during warning phase, but with alternating alpha
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if abs(x) + abs(y) <= radius:
					var draw_pos = Vector2(center_grid_pos + Vector2i(x, y)) * cell_size
					draw_rect(Rect2(draw_pos, Vector2(cell_size, cell_size)), warning_color)
					
					# Draw block border for better "blocky" look
					draw_rect(Rect2(draw_pos, Vector2(cell_size, cell_size)), GameConstants.COLOR_BLOCK_BORDER, false, 1.0)
