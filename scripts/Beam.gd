extends Node2D
class_name Beam

enum Orientation { HORIZONTAL, VERTICAL }

var orientation: Orientation
var global_grid_index: int
var warning_time = 2.0
var active_time = 0.5
var timer = 0.0
var is_active = false
var flicker_timer = 0.0
var show_warning = true
var thickness = 1

func get_current_flicker_speed() -> float:
	return lerp(0.04, 0.2, clamp(timer / warning_time, 0.0, 1.0))
var zigzag_amplitude = 0

func setup(p_orientation: Orientation, p_index: int, p_thickness: int = 1, p_zigzag_amplitude: int = 0):
	orientation = p_orientation
	global_grid_index = p_index
	thickness = p_thickness
	zigzag_amplitude = p_zigzag_amplitude
	timer = warning_time
	queue_redraw()

func _process(delta):
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake") if world else null
	if snake and snake.is_reversing:
		return  # Pause countdown during reverse animation
	
	timer -= delta
	
	if not is_active:
		flicker_timer += delta
		var current_flicker_speed = get_current_flicker_speed()
		if flicker_timer >= current_flicker_speed:
			flicker_timer = 0.0
			show_warning = !show_warning
			queue_redraw()
			
		if timer <= 0:
			activate_beam()
	else:
		queue_redraw()
		if timer <= 0:
			deactivate_beam()

func activate_beam():
	is_active = true
	timer = active_time
	show_warning = true
	queue_redraw()
	check_collision()

func deactivate_beam():
	var world = get_parent()
	if world.has_method("unregister_beam"):
		world.unregister_beam(self)
	queue_free()

func get_zigzag_offset(pos_along_beam: int) -> int:
	if zigzag_amplitude == 0: return 0
	
	if zigzag_amplitude == 1:
		# 1 step Up, 1 step Down (Period 2)
		var p = pos_along_beam % 2
		if p < 0: p += 2
		return p # 0 or 1
	elif zigzag_amplitude == 2:
		# 2 steps Up, 2 steps Down (Period 4)
		var p = pos_along_beam % 4
		if p < 0: p += 4
		var seq = [0, 1, 2, 1]
		return seq[p] - 1
	elif zigzag_amplitude == 3:
		# 3 steps Up, 3 steps Down (Period 6)
		var p = pos_along_beam % 6
		if p < 0: p += 6
		var seq = [0, 1, 2, 3, 2, 1]
		return seq[p] - 1
		
	return 0

func is_on_beam(grid_pos: Vector2i) -> bool:
	if orientation == Orientation.HORIZONTAL:
		var z_offset = get_zigzag_offset(grid_pos.x)
		return abs(grid_pos.y - (global_grid_index + z_offset)) <= thickness / 2
	else:
		var z_offset = get_zigzag_offset(grid_pos.y)
		return abs(grid_pos.x - (global_grid_index + z_offset)) <= thickness / 2

func check_collision():
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	if snake and snake.has_method("cut_snake"):
		var body = snake.body
		var hit_indices = []
		for i in range(body.size()):
			if is_on_beam(body[i]):
				hit_indices.append(i)
		
		if not hit_indices.is_empty():
			snake.cut_snake(hit_indices[0])

func _draw():
	var cell_size = GameConstants.CELL_SIZE
	var color = GameConstants.COLOR_DANGER
	
	var draw_color = color
	if is_active:
		var flash_ratio = clamp(timer / active_time, 0.0, 1.0)
		var boost = flash_ratio * 1.5
		draw_color = Color(color.r + boost, color.g + boost * 0.2, color.b + boost * 0.2)
		draw_color.a = flash_ratio
	else:
		draw_color.a = 0.5 if show_warning else 0.15
		
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	var center_grid = Vector2i(snake.position / cell_size) if snake else Vector2i.ZERO
	
	var range_val = 40
	for i in range(-range_val, range_val):
		var pos_along = (center_grid.x if orientation == Orientation.HORIZONTAL else center_grid.y) + i
		var z_offset = get_zigzag_offset(pos_along)
		
		for t_offset in range(-thickness / 2, thickness / 2 + 1):
			var rect: Rect2
			if orientation == Orientation.HORIZONTAL:
				var grid_y = global_grid_index + z_offset + t_offset
				rect = Rect2(pos_along * cell_size, grid_y * cell_size, cell_size, cell_size)
			else:
				var grid_x = global_grid_index + z_offset + t_offset
				rect = Rect2(grid_x * cell_size, pos_along * cell_size, cell_size, cell_size)
			
			draw_rect(rect, draw_color)
