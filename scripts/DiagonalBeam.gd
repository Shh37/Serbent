extends Node2D
class_name DiagonalBeam

enum Type { FORWARD_SLASH, BACK_SLASH }

var type: Type
var offset_k: int
var warning_time = 2.0
var active_time = 0.5
var timer = 0.0
var is_active = false
var flicker_speed = 0.1
var flicker_timer = 0.0
var show_warning = true
var thickness = 1
var zigzag_amplitude = 0

func setup(p_type: Type, p_offset_k: int, p_thickness: int = 1, p_zigzag_amplitude: int = 0):
	type = p_type
	offset_k = p_offset_k
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
		if flicker_timer >= flicker_speed:
			flicker_timer = 0.0
			show_warning = !show_warning
			queue_redraw()
			
		if timer <= 0:
			activate_beam()
	else:
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
	if world.has_method("unregister_diagonal_beam"):
		world.unregister_diagonal_beam(self)
	queue_free()

func get_zigzag_offset(u: int) -> int:
	if zigzag_amplitude == 0: return 0
	
	if zigzag_amplitude == 1:
		# 1 vertical, 1 horizontal (Period 2)
		var p = u % 2
		if p < 0: p += 2
		return p # 0 or 1
	elif zigzag_amplitude == 2:
		# 2 vertical, 2 horizontal (Period 4)
		var p = u % 4
		if p < 0: p += 4
		var seq = [0, 1, 2, 1]
		return seq[p] - 1
	elif zigzag_amplitude == 3:
		# 3 vertical, 3 horizontal (Period 6)
		var p = u % 6
		if p < 0: p += 6
		var seq = [0, 1, 2, 3, 2, 1]
		return seq[p] - 1
	return 0

func is_on_beam(grid_pos: Vector2i) -> bool:
	var u: int
	var v_base: int
	if type == Type.FORWARD_SLASH:
		u = grid_pos.x - grid_pos.y
		v_base = grid_pos.x + grid_pos.y - offset_k
	else:
		u = grid_pos.x + grid_pos.y
		v_base = grid_pos.x - grid_pos.y - offset_k
		
	var z_offset = get_zigzag_offset(u)
	return abs(v_base - z_offset) <= thickness / 2

func check_collision():
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	if snake and snake.has_method("cut_snake"):
		var body = snake.body
		for i in range(body.size()):
			if is_on_beam(body[i]):
				snake.cut_snake(i)
				break

func _draw():
	var cell_size = GameConstants.CELL_SIZE
	var color = GameConstants.COLOR_DANGER
	
	if not is_active and not show_warning:
		return
		
	var draw_color = color
	if not is_active:
		draw_color.a = 0.2
		
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	var center_grid = Vector2i(snake.position / cell_size) if snake else Vector2i.ZERO
	
	var range_val = 40
	for i in range(-range_val, range_val):
		var x = center_grid.x + i
		var base_y = (offset_k - x) if type == Type.FORWARD_SLASH else (x - offset_k)
		
		# Search locally for valid y (within zigzag_amplitude and thickness bounds)
		for dy in range(-zigzag_amplitude - thickness - 2, zigzag_amplitude + thickness + 3):
			var y = base_y + dy
			if is_on_beam(Vector2i(x, y)):
				var rect = Rect2(x * cell_size, y * cell_size, cell_size, cell_size)
				draw_rect(rect, draw_color)
