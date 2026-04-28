extends Node2D

var body = [] # Array of Vector2i (grid positions)
var direction = Vector2i.RIGHT
var next_direction = Vector2i.RIGHT
var input_queue = []

var move_timer = 0.0
var move_speed_normal = GameConstants.SNAKE_INITIAL_SPEED
var move_speed_dash = move_speed_normal * GameConstants.SNAKE_DASH_MULTIPLIER
var is_dashing = false

func _ready():
	# Initial snake (3 segments)
	body = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
	recalculate_speed()
	update_position_from_grid()

func _process(delta):
	is_dashing = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	handle_input()
	
	var current_speed = move_speed_dash if is_dashing else move_speed_normal
	
	move_timer += delta
	if move_timer >= current_speed:
		move_timer = 0.0
		move_step()

func handle_input():
	if is_dashing:
		return # Cannot change direction while dashing
		
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
		
	# Check for thorn collision
	var world = get_parent().get_node("World")
	if world.has_thorn(new_head):
		game_over()
		return
		
	body.insert(0, new_head)
	
	# Check for point collection
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
	
	# Check for hazard collision (if any beam/bomb is currently active)
	# This is for when the snake MOVES into an already active hazard
	if world.has_method("check_hazard_collision"):
		world.check_hazard_collision(self)
	
	update_position_from_grid()
	recalculate_speed()
	queue_redraw()

func cut_snake(cut_index: int):
	if cut_index == 0:
		game_over()
		return
		
	if cut_index > 0 and cut_index < body.size():
		var segments_lost = body.size() - cut_index
		# Keep only the part before the cut (head is at index 0)
		body = body.slice(0, cut_index)
		# Spec: Score reduction (number of segments lost)
		score = max(0, score - segments_lost)
		print("Snake cut! Lost ", segments_lost, " segments. New score: ", score)
		recalculate_speed()
		queue_redraw()

func recalculate_speed():
	var segments_added = max(0, body.size() - 3)
	move_speed_normal = max(GameConstants.SNAKE_MIN_SPEED, GameConstants.SNAKE_INITIAL_SPEED - (segments_added * GameConstants.SNAKE_SPEED_INCREMENT))
	move_speed_dash = move_speed_normal * GameConstants.SNAKE_DASH_MULTIPLIER

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
