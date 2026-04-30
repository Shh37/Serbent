extends Node2D
class_name Beam

enum Orientation { HORIZONTAL, VERTICAL }

var orientation: Orientation
var global_grid_index: int # Global grid coordinate
var warning_time = 2.0
var active_time = 0.5
var timer = 0.0
var is_active = false
var flicker_speed = 0.1
var flicker_timer = 0.0
var show_warning = true
var thickness = 1

func setup(p_orientation: Orientation, p_index: int, p_thickness: int = 1):
	orientation = p_orientation
	global_grid_index = p_index
	thickness = p_thickness
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
	# Beam finished, remove it
	var world = get_parent()
	if world.has_method("unregister_beam"):
		world.unregister_beam(self)
	queue_free()

func check_collision():
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	if snake and snake.has_method("cut_snake"):
		var body = snake.body
		var hit_indices = []
		for i in range(body.size()):
			var pos = body[i]
			
			if orientation == Orientation.HORIZONTAL:
				if abs(pos.y - global_grid_index) <= thickness / 2:
					hit_indices.append(i)
			else:
				if abs(pos.x - global_grid_index) <= thickness / 2:
					hit_indices.append(i)
		
		if not hit_indices.is_empty():
			snake.cut_snake(hit_indices[0])

func _draw():
	var cell_size = GameConstants.CELL_SIZE
	var color = GameConstants.COLOR_DANGER
	
	# Get player position to center the beam span
	var world = get_parent()
	var snake = world.get_parent().get_node("Snake")
	var center = snake.position if snake else Vector2.ZERO
	
	# Drawing range (enough to cover the screen)
	var span = 5000 
	
	if is_active:
		# Draw the actual beam
		var rect: Rect2
		if orientation == Orientation.HORIZONTAL:
			var top_y = (global_grid_index - thickness / 2) * cell_size
			rect = Rect2(center.x - span/2, top_y, span, cell_size * thickness)
		else:
			var left_x = (global_grid_index - thickness / 2) * cell_size
			rect = Rect2(left_x, center.y - span/2, cell_size * thickness, span)
		
		draw_rect(rect, color)
	elif show_warning:
		# Draw warning block (faint red)
		var warning_color = color
		warning_color.a = 0.2
		
		var rect: Rect2
		if orientation == Orientation.HORIZONTAL:
			var top_y = (global_grid_index - thickness / 2) * cell_size
			rect = Rect2(center.x - span/2, top_y, span, cell_size * thickness)
		else:
			var left_x = (global_grid_index - thickness / 2) * cell_size
			rect = Rect2(left_x, center.y - span/2, cell_size * thickness, span)
		
		draw_rect(rect, warning_color)
