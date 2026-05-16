extends Control
class_name SnakePreview

var move_timer = 0.0
var move_speed = 0.2
var body = []
var old_body = []
var direction = Vector2i.RIGHT

var color_type = GameConstants.SkinColor.BASIC
var pattern_type = GameConstants.SkinPattern.SOLID

# Area for movement: A 6x6 grid
var path_size = 6

func _ready():
	custom_minimum_size = Vector2(200, 200)
	reset_snake()

func reset_snake():
	# Start at a safe middle position
	var head = Vector2i(path_size / 2, path_size / 2)
	body = []
	for i in range(8):
		body.append(head) # Just stack it at start or move it back
	old_body = body.duplicate()
	move_timer = 0.0

func _process(delta):
	move_timer += delta
	if move_timer >= move_speed:
		move_timer -= move_speed
		move_step()
	queue_redraw()

func get_animated_t() -> float:
	var t = clamp(move_timer / move_speed, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)

func move_step():
	old_body = body.duplicate()
	var head = body[0]
	
	var possible_dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var valid_dirs = []
	
	for d in possible_dirs:
		var next_p = head + d
		# Check bounds
		if next_p.x < 0 or next_p.x >= path_size or next_p.y < 0 or next_p.y >= path_size:
			continue
		# Check self-collision (exclude the tail as it will move)
		var is_collision = false
		for i in range(body.size() - 1):
			if body[i] == next_p:
				is_collision = true
				break
		if is_collision:
			continue
		valid_dirs.append(d)
	
	if valid_dirs.is_empty():
		reset_snake()
		return
		
	# Pick a direction
	# 70% chance to continue in the same direction if valid, to look more natural
	if direction in valid_dirs and randf() < 0.7:
		pass 
	else:
		direction = valid_dirs[randi() % valid_dirs.size()]
		
	var new_head = head + direction
	body.insert(0, new_head)
	body.pop_back()

func _draw():
	var t = get_animated_t()
	var cell_size = GameConstants.CELL_SIZE
	
	# Center the preview
	var center_offset = size / 2.0 - Vector2(path_size * cell_size / 2.0, path_size * cell_size / 2.0)
	
	var visual_positions = []
	for i in range(body.size()):
		var curr_pos = Vector2(body[i])
		var prev_pos = Vector2(old_body[i] if i < old_body.size() else body[i])
		visual_positions.append(prev_pos.lerp(curr_pos, t))
		
	for i in range(body.size() - 1, -1, -1):
		var visual_pos = visual_positions[i]
		var rect: Rect2
		
		if i > 0 and i - 1 < old_body.size():
			var dest_pos = Vector2(old_body[i-1])
			var min_x = min(visual_pos.x, dest_pos.x) * cell_size
			var min_y = min(visual_pos.y, dest_pos.y) * cell_size
			var max_x = max(visual_pos.x, dest_pos.x) * cell_size + cell_size
			var max_y = max(visual_pos.y, dest_pos.y) * cell_size + cell_size
			rect = Rect2(center_offset + Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
		else:
			var draw_pos = center_offset + visual_pos * cell_size
			rect = Rect2(draw_pos, Vector2.ONE * cell_size)
			
		var base_color = GameConstants.SKIN_COLORS[color_type]
		var darker_color = base_color.darkened(0.3)
		var color = base_color
		
		match pattern_type:
			GameConstants.SkinPattern.STRIPE11:
				color = base_color if i % 2 == 0 else darker_color
			GameConstants.SkinPattern.STRIPE12:
				color = base_color if i % 3 == 0 else darker_color
			GameConstants.SkinPattern.STRIPE21:
				color = base_color if i % 3 != 2 else darker_color
			GameConstants.SkinPattern.STRIPE22:
				color = base_color if (i / 2) % 2 == 0 else darker_color
			GameConstants.SkinPattern.GRADIENT:
				color = base_color.lerp(darker_color, float(i) / float(body.size()))
				
		if i == 0:
			color = color.lightened(0.2)
			
		draw_rect(rect, color)
