extends Node2D

var body = [] # Array of Vector2i (grid positions)
var direction = Vector2i.RIGHT
var next_direction = Vector2i.RIGHT
var input_queue = []

var move_timer = 0.0
var move_speed = 0.15 # Seconds per move

func _ready():
	# Initial snake (3 segments)
	body = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
	update_position_from_grid()

func _process(delta):
	handle_input()
	
	move_timer += delta
	if move_timer >= move_speed:
		move_timer = 0.0
		move_step()

func handle_input():
	var new_dir = Vector2i.ZERO
	if Input.is_action_just_pressed("ui_up"): new_dir = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down"): new_dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_left"): new_dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_right"): new_dir = Vector2i.RIGHT
	
	if new_dir != Vector2i.ZERO:
		# Don't allow immediate 180 turn
		var last_dir = input_queue.back() if not input_queue.is_empty() else direction
		if new_dir != -last_dir:
			input_queue.append(new_dir)

var score = 0
var pending_growth = 0

func move_step():
	if not input_queue.is_empty():
		direction = input_queue.pop_front()
		
	var new_head = body[0] + direction
	
	# Self collision check
	if new_head in body:
		game_over()
		return
		
	body.insert(0, new_head)
	
	# Check for point collection
	var world = get_parent().get_node("World")
	var collected_point = world.collect_point(new_head)
	
	if collected_point:
		var growth = 0
		match collected_point.type:
			Point.Type.NORMAL:
				score += GameConstants.POINT_VALUE_NORMAL
				growth = GameConstants.POINT_VALUE_NORMAL
			Point.Type.MEDIUM:
				score += GameConstants.POINT_VALUE_MEDIUM
				growth = GameConstants.POINT_VALUE_MEDIUM
			Point.Type.LARGE:
				score += GameConstants.POINT_VALUE_LARGE
				growth = GameConstants.POINT_VALUE_LARGE
		
		# growth - 1 because we already added the head and haven't popped the tail yet
		# Wait, if we don't pop the tail, we grow by 1.
		# So if growth is 3, we skip popping the tail for 3 steps.
		pending_growth += growth
		print("Score: ", score, " Length: ", body.size(), " Growth: +", growth)
	
	if pending_growth > 0:
		# Don't pop tail, let the snake grow
		pending_growth -= 1
	else:
		# Normal move, remove tail
		body.pop_back()
	
	update_position_from_grid()
	queue_redraw()

func update_position_from_grid():
	# Centering the camera/pivot on the head
	position = Vector2(body[0]) * GameConstants.CELL_SIZE

func _draw():
	# Draw segments relative to the head (since the node follows the head)
	var head_pos = Vector2(body[0]) * GameConstants.CELL_SIZE
	
	for segment in body:
		var draw_pos = Vector2(segment) * GameConstants.CELL_SIZE - position
		var rect = Rect2(draw_pos, Vector2.ONE * GameConstants.CELL_SIZE)
		
		# Fill
		draw_rect(rect, GameConstants.COLOR_SNAKE)
		# Border
		draw_rect(rect, GameConstants.COLOR_BLOCK_BORDER, false, 1.0)

func game_over():
	print("Game Over!")
	# Simple reset for now
	get_tree().reload_current_scene()
