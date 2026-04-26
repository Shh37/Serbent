extends Node2D
class_name DiagonalBeam

enum Type { FORWARD_SLASH, BACK_SLASH }

var type: Type
var offset_k: int # The k in x+y=k or x-y=k
var warning_time = 2.0
var active_time = 0.5
var timer = 0.0
var is_active = false
var flicker_speed = 0.1
var flicker_timer = 0.0
var show_warning = true

func setup(p_type: Type, p_offset_k: int):
	type = p_type
	offset_k = p_offset_k
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
			activate_beam()
	else:
		if timer <= 0:
			deactivate_beam()

func activate_beam():
	is_active = true
	timer = active_time
	show_warning = true
	queue_redraw()
	
	# Check collision immediately when activated
	check_collision()

func deactivate_beam():
	var world = get_parent()
	if world.has_method("unregister_diagonal_beam"):
		world.unregister_diagonal_beam(self)
	queue_free()

func check_collision():
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	if snake and snake.has_method("cut_snake"):
		var body = snake.body
		# Check from tail to head or head to tail?
		# Beam.gd checks and breaks at first intersection.
		for i in range(body.size()):
			var pos = body[i]
			if is_on_beam(pos):
				snake.cut_snake(i)
				break

func is_on_beam(grid_pos: Vector2i) -> bool:
	if type == Type.FORWARD_SLASH:
		return grid_pos.x + grid_pos.y == offset_k
	else: # BACK_SLASH
		return grid_pos.x - grid_pos.y == offset_k

func _draw():
	var cell_size = GameConstants.CELL_SIZE
	var color = GameConstants.COLOR_DANGER
	
	if not is_active and not show_warning:
		return
		
	var draw_color = color
	if not is_active:
		draw_color.a = 0.2
		
	# Draw blocks in view
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	var center_grid = Vector2i(snake.position / cell_size) if snake else Vector2i.ZERO
	
	var range_val = 40 # Draw enough blocks to cover the screen
	
	for i in range(-range_val, range_val):
		var grid_pos: Vector2i
		if type == Type.FORWARD_SLASH:
			# x + y = k => y = k - x
			var x = center_grid.x + i
			var y = offset_k - x
			grid_pos = Vector2i(x, y)
		else:
			# x - y = k => y = x - offset_k
			var x = center_grid.x + i
			var y = x - offset_k
			grid_pos = Vector2i(x, y)
			
		var rect = Rect2(grid_pos.x * cell_size, grid_pos.y * cell_size, cell_size, cell_size)
		draw_rect(rect, draw_color)
