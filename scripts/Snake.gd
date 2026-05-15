extends Node2D

var body = [] # Array of Vector2i (grid positions)
var old_body = [] # Previous grid positions for animation
var dead_parts = [] # List of { segments: Array, time: float }
var direction = Vector2i.RIGHT
var next_direction = Vector2i.RIGHT
var input_queue = []

# Result screen stats
var max_length = 3 # Track the longest body length achieved
var points_collected = 0 # Track total points collected
var is_dead = false # Whether the game is over (result screen showing)

var move_timer = 0.0
var move_speed_normal = GameConstants.SNAKE_INITIAL_SPEED
var move_speed_dash = move_speed_normal * GameConstants.SNAKE_DASH_MULTIPLIER
var is_dashing = false
var is_reversing = false
var dash_dir_hold = Vector2i.ZERO

var active_powerups = {} # PowerUpType -> float (time remaining)

func _dir_to_action(dir: Vector2i) -> String:
	if dir == Vector2i.UP:
		return "ui_up"
	if dir == Vector2i.DOWN:
		return "ui_down"
	if dir == Vector2i.LEFT:
		return "ui_left"
	if dir == Vector2i.RIGHT:
		return "ui_right"
	return ""

func get_animated_t() -> float:
	var speed = move_speed_dash if is_dashing else move_speed_normal
	var t = clamp(move_timer / speed, 0.0, 1.0)
	# Cubic Ease Out: snappy but slightly smoother than Quartic
	return 1.0 - pow(1.0 - t, 3.0)

func update_is_dashing():
	var dir_action := _dir_to_action(dash_dir_hold)
	var dir_dashing := dash_dir_hold != Vector2i.ZERO and dir_action != "" and Input.is_action_pressed(dir_action)
	is_dashing = Input.is_key_pressed(KEY_SPACE) or dir_dashing

func _ready():
	# Randomize initial direction
	var dirs = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	direction = dirs[randi() % dirs.size()]
	next_direction = direction
	
	# Initial snake (3 segments) arranged according to direction
	var head = Vector2i(5, 5)
	body = [head, head - direction, head - 2 * direction]
	
	old_body = body.duplicate()
	recalculate_speed()
	update_position_from_grid()

func _process(delta):
	var old_speed = move_speed_dash if is_dashing else move_speed_normal
	
	update_is_dashing()
	handle_input()
	update_is_dashing()
	
	var new_speed = move_speed_dash if is_dashing else move_speed_normal
	if old_speed != new_speed:
		# Rescale timer to maintain the same visual progress (t)
		move_timer = move_timer * (new_speed / old_speed)
	
	_update_dead_parts(delta)
	_update_powerups(delta)
	
	if is_reversing:
		return
	
	var current_speed = move_speed_dash if is_dashing else move_speed_normal
	
	move_timer += delta
	if move_timer >= current_speed:
		move_timer = 0.0
		move_step()
	
	# Update visual position and redraw for animation
	update_position_from_grid()
	queue_redraw()

func handle_input():
	if is_dashing:
		return # Cannot change direction while dashing
		
	var new_dir = Vector2i.ZERO
	if Input.is_action_just_pressed("ui_up"): new_dir = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down"): new_dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_left"): new_dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_right"): new_dir = Vector2i.RIGHT
	
	if new_dir != Vector2i.ZERO:
		if new_dir == direction and input_queue.is_empty():
			# Re-press the current movement direction to start dashing while held
			dash_dir_hold = new_dir
			return
		# Turning cancels any directional dash; after turning, another press is required
		dash_dir_hold = Vector2i.ZERO
		# Check if it's the opposite of the last intended direction
		var last_dir = input_queue.back() if not input_queue.is_empty() else direction
		if new_dir == -last_dir:
			reverse_snake()
			input_queue.clear() # Clear any pending turns
		else:
			input_queue.append(new_dir)

func _update_dead_parts(delta):
	if dead_parts.is_empty():
		return
	var i = dead_parts.size() - 1
	var changed = false
	while i >= 0:
		dead_parts[i].time -= delta
		changed = true
		if dead_parts[i].time <= 0:
			dead_parts.remove_at(i)
		i -= 1
	if changed:
		queue_redraw()

func _update_powerups(delta):
	var world = get_parent().get_node("World")
	world.is_time_stopped = false
	
	var to_remove = []
	for type in active_powerups.keys():
		active_powerups[type] -= delta
		if active_powerups[type] <= 0:
			to_remove.append(type)
		
		if type == GameConstants.PowerUpType.TIME_STOP:
			world.is_time_stopped = true
			
	for type in to_remove:
		active_powerups.erase(type)
	
	if not to_remove.is_empty():
		queue_redraw()

var score = 0
var pending_growth = 0

func _update_max_length():
	if body.size() > max_length:
		max_length = body.size()

func move_step():
	old_body = body.duplicate()
	if not input_queue.is_empty():
		var new_direction = input_queue.pop_front()
		if new_direction != direction:
			dash_dir_hold = Vector2i.ZERO
		direction = new_direction
		
	var new_head = body[0] + direction
	
	# Self collision check
	if new_head in body and not active_powerups.has(GameConstants.PowerUpType.GHOST):
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
		var growth = GameConstants.POINT_VALUE_NORMAL
		var score_gain = GameConstants.POINT_VALUE_NORMAL
		
		if active_powerups.has(GameConstants.PowerUpType.DOUBLE_GROWTH):
			growth *= 2
			score_gain *= 2
			
		score += score_gain
		points_collected += score_gain
		pending_growth += growth
		print("Score: ", score, " Length: ", body.size(), " Growth: +", growth)

	# Check for power-up collection
	var collected_pu = world.collect_powerup(new_head)
	if collected_pu:
		apply_powerup(collected_pu.type)

	
	if pending_growth > 0:
		# Don't pop tail, let the snake grow
		pending_growth -= 1
	else:
		# Normal move, remove tail
		body.pop_back()
	
	# Hazard collision is now ONLY checked at the moment the hazard activates.
	
	update_position_from_grid()
	recalculate_speed()
	_update_max_length()
	# queue_redraw() is now called in _process

func apply_powerup(type: GameConstants.PowerUpType):
	active_powerups[type] = 5.0 # All powerups last 5 seconds
	print("Power-up collected: ", type)
	
	queue_redraw()

func cut_snake(cut_index: int):
	if active_powerups.has(GameConstants.PowerUpType.GHOST) and cut_index > 0:
		return # Ghost body protection
		
	if cut_index == 0:


		game_over()
		return
		
	if cut_index > 0 and cut_index < body.size():
		# Save the severed part for a visual fade-out effect
		var severed_part = body.slice(cut_index)
		dead_parts.append({"segments": severed_part, "time": 2.0})
		
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
		old_body = body.duplicate() # Reset animation
		move_timer = 0.0
		queue_redraw()

func recalculate_speed():
	var segments_added = max(0, body.size() - 3)
	move_speed_normal = max(GameConstants.SNAKE_MIN_SPEED, GameConstants.SNAKE_INITIAL_SPEED - (segments_added * GameConstants.SNAKE_SPEED_INCREMENT))
	move_speed_dash = move_speed_normal * GameConstants.SNAKE_DASH_MULTIPLIER

func update_position_from_grid():
	var t = get_animated_t()
	var head_curr = Vector2(body[0])
	var head_prev = Vector2(old_body[0] if not old_body.is_empty() else body[0])
	var visual_head_pos = head_prev.lerp(head_curr, t)
	
	# Centering the camera/pivot on the head
	position = visual_head_pos * GameConstants.CELL_SIZE

func _draw():
	var t = get_animated_t()
	var visual_positions = []
	for i in range(body.size()):
		var curr_pos = Vector2(body[i])
		var prev_pos = Vector2(old_body[i] if i < old_body.size() else body[i])
		visual_positions.append(prev_pos.lerp(curr_pos, t))
	
	# 0. Draw Dead Parts (severed tail fading out)
	for part in dead_parts:
		var alpha = clamp(part.time / 1.0, 0.0, 1.0) # Fade out in the last 1 second
		var color = GameConstants.COLOR_GHOST
		color.a = alpha * 0.6 # Apply transparency
		for segment in part.segments:
			var draw_pos = Vector2(segment) * GameConstants.CELL_SIZE - position
			var rect = Rect2(draw_pos, Vector2.ONE * GameConstants.CELL_SIZE)
			draw_rect(rect, color)
	
	
	# 1. Draw Segments (from tail to head so head is on top)
	for i in range(body.size() - 1, -1, -1):
		var visual_pos = visual_positions[i]
		var rect: Rect2
		
		# Draw a rectangle spanning from current visual position to the destination cell
		# to seamlessly fill gaps and corners without static blocks.
		if i > 0 and i - 1 < old_body.size():
			var dest_pos = Vector2(old_body[i-1])
			var min_x = min(visual_pos.x, dest_pos.x) * GameConstants.CELL_SIZE - position.x
			var min_y = min(visual_pos.y, dest_pos.y) * GameConstants.CELL_SIZE - position.y
			var max_x = max(visual_pos.x, dest_pos.x) * GameConstants.CELL_SIZE - position.x + GameConstants.CELL_SIZE
			var max_y = max(visual_pos.y, dest_pos.y) * GameConstants.CELL_SIZE - position.y + GameConstants.CELL_SIZE
			rect = Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
		else:
			# The head (i=0) just draws at its current visual position
			var draw_pos = visual_pos * GameConstants.CELL_SIZE - position
			rect = Rect2(draw_pos, Vector2.ONE * GameConstants.CELL_SIZE)
		
		# Fill
		var base_color = GameConstants.SKIN_COLORS[Config.selected_color]
		var darker_color = base_color.darkened(0.3)
		var color = base_color
		var pattern = Config.selected_pattern
		
		match pattern:
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
			# Brighter head for better visibility
			color = color.lightened(0.2)
		elif active_powerups.has(GameConstants.PowerUpType.GHOST):
			color = color.darkened(0.5) # Dark green for ethereal body
			
		draw_rect(rect, color)

		# Individual block borders removed to make the body look seamless

func reverse_snake():
	if body.size() < 2 or is_reversing:
		return
		
	dash_dir_hold = Vector2i.ZERO
		
	is_reversing = true
	var camera = $Camera2D
	
	# Record the current head position before flipping
	var old_head_pos = global_position
	
	body.reverse()
	old_body = body.duplicate() # Reset animation
	
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
	tween.set_trans(Tween.TRANS_EXPO) # Fast start, slow end
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
	if is_reversing or is_dead: return # Prevent multiple calls
	is_reversing = true
	is_dead = true
	
	print("Game Over!")
	_update_max_length()
	
	# Visual effect: Noticeable dark red flash and blur for game over
	var red_tint = GameConstants.COLOR_DANGER.darkened(0.6)
	red_tint.a = 0.6
	var fx_tween = _play_screen_fx(5.0, red_tint, 1.5)
	
	await get_tree().create_timer(1.5, false).timeout
	
	# Show result screen instead of reloading
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_result_screen"):
		var game_time = hud.game_time
		hud.show_result_screen(body.size(), game_time, max_length, points_collected)
		get_tree().paused = true
	else:
		get_tree().reload_current_scene()

func _play_screen_fx(target_blur: float, target_tint: Color, duration: float) -> Tween:
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("play_screen_fx"):
		return hud.play_screen_fx(target_blur, target_tint, duration)
	return null
