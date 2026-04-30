extends Node2D

var body = [] # Array of Vector2i (grid positions)
var direction = Vector2i.RIGHT
var next_direction = Vector2i.RIGHT
var input_queue = []

var move_timer = 0.0
var move_speed_normal = GameConstants.SNAKE_INITIAL_SPEED
var move_speed_dash = move_speed_normal * GameConstants.SNAKE_DASH_MULTIPLIER
var is_dashing = false
var is_reversing = false

func _ready():
	# Initial snake (3 segments)
	body = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
	recalculate_speed()
	update_position_from_grid()

func _process(delta):
	is_dashing = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	handle_input()
	
	if is_reversing:
		return
	
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
		# Check if it's the opposite of the last intended direction
		var last_dir = input_queue.back() if not input_queue.is_empty() else direction
		if new_dir == -last_dir:
			reverse_snake()
			input_queue.clear() # Clear any pending turns
		else:
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
		
		# Visual effect: Subtle dark red flash but noticeable blur
		var red_tint = GameConstants.COLOR_DANGER.darkened(0.6)
		red_tint.a = 0.3
		_play_screen_fx(5.0, red_tint, GameConstants.SNAKE_REVERSE_TIME)
		
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
	for i in range(body.size()):
		var segment = body[i]
		var draw_pos = Vector2(segment) * GameConstants.CELL_SIZE - position
		var rect = Rect2(draw_pos, Vector2.ONE * GameConstants.CELL_SIZE)
		
		# Fill
		var color = GameConstants.COLOR_SNAKE
		if i == 0:
			# Brighter head for better visibility
			color = color.lightened(0.2)
			
		draw_rect(rect, color)
		# Border
		draw_rect(rect, GameConstants.COLOR_BLOCK_BORDER, false, 1.0)

func reverse_snake():
	if body.size() < 2 or is_reversing:
		return
		
	is_reversing = true
	var camera = $Camera2D
	
	# Record the current head position before flipping
	var old_head_pos = global_position
	
	body.reverse()
	
	# Set direction to move away from the new second segment.
	# This ensures we don't immediately collide with our own body
	# when reversing from a curved position (the "spinning" issue).
	direction = body[0] - body[1]
	
	# Update position to the new head (this would normally jump the camera)
	update_position_from_grid()
	
	# Keep the camera at the old head position initially
	camera.global_position = old_head_pos
	
	# Disable smoothing during manual tweening to avoid conflicts
	var old_smoothing = camera.position_smoothing_enabled
	camera.position_smoothing_enabled = false
	
	# Tween camera from old head to new head (local 0,0)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART) # Fast start
	tween.set_ease(Tween.EASE_OUT)      # Slow end
	tween.tween_property(camera, "position", Vector2.ZERO, GameConstants.SNAKE_REVERSE_TIME)
	
	# Visual effect: Stronger blur and darkening during transition
	_play_screen_fx(5.0, Color(0, 0, 0, 0.9), GameConstants.SNAKE_REVERSE_TIME)
	
	# Resume movement when the animation finished
	tween.finished.connect(func():
		is_reversing = false
		camera.position_smoothing_enabled = old_smoothing
		# Set move_timer close to current_speed to trigger the first move quickly
		# This removes the "delay" feel after the camera transition.
		var current_speed = move_speed_dash if is_dashing else move_speed_normal
		move_timer = current_speed * 0.9
	)
	
	move_timer = 0.0
	queue_redraw()

func game_over():
	if is_reversing: return # Prevent multiple calls
	is_reversing = true
	
	print("Game Over!")
	
	# Visual effect: Noticeable dark red flash and blur for game over
	var red_tint = GameConstants.COLOR_DANGER.darkened(0.6)
	red_tint.a = 0.6
	var fx_tween = _play_screen_fx(5.0, red_tint, 1.5)
	
	await get_tree().create_timer(1.5, false).timeout
		
	get_tree().reload_current_scene()

func _play_screen_fx(target_blur: float, target_tint: Color, duration: float) -> Tween:
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("play_screen_fx"):
		return hud.play_screen_fx(target_blur, target_tint, duration)
	return null
