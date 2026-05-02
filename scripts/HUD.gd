extends CanvasLayer

@onready var length_label = $Control/MarginContainer/HBoxContainer/LengthLabel
@onready var time_label = $Control/MarginContainer/HBoxContainer/TimeLabel
@onready var edge_blur = $EdgeBlur

var snake: Node2D
var game_time = 0.0
var fx_tween: Tween

# Shader defaults
const DEFAULT_BLUR = 4.0
const DEFAULT_TINT = Color(0.1, 0.1, 0.1, 0.4)

func _ready():
	# Make material unique to prevent parameter persistence across scene reloads
	if edge_blur and edge_blur.material:
		edge_blur.material = edge_blur.material.duplicate()
		# Reset to defaults immediately
		edge_blur.material.set_shader_parameter("blur_strength", DEFAULT_BLUR)
		edge_blur.material.set_shader_parameter("tint_color", DEFAULT_TINT)
		
	# Wait for the scene to be fully loaded to find the snake
	await get_tree().process_frame
	snake = get_tree().root.find_child("Snake", true, false)
	
	# Sync shader visibility
	_update_shader_visibility(Config.crt_enabled)
	Config.crt_changed.connect(_update_shader_visibility)

func _update_shader_visibility(enabled: bool):
	if edge_blur and edge_blur.material:
		edge_blur.material.set_shader_parameter("crt_enabled", enabled)
	if edge_blur:
		edge_blur.visible = true

func _process(delta):
	if snake and snake.is_reversing:
		update_ui() # Keep updating UI (like length) but skip timer
		return
		
	game_time += delta
	update_ui()

func update_ui():
	if snake:
		length_label.text = "LENGTH: %d" % snake.body.size()
	
	# Format time: MM:SS.mmm
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	var milliseconds = int((game_time - int(game_time)) * 1000)
	time_label.text = "TIME: %02d:%02d.%03d" % [minutes, seconds, milliseconds]

func play_screen_fx(target_blur: float, target_tint: Color, duration: float) -> Tween:
	if not (edge_blur and edge_blur.material):
		return null
		
	if fx_tween:
		fx_tween.kill()
		
	var blur_mat = edge_blur.material as ShaderMaterial
	fx_tween = create_tween()
	
	var current_blur = blur_mat.get_shader_parameter("blur_strength")
	var current_tint = blur_mat.get_shader_parameter("tint_color")
	
	# Intensify (Fast pop: 20% of duration)
	fx_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	fx_tween.tween_method(func(v): blur_mat.set_shader_parameter("blur_strength", v), current_blur, target_blur, duration * 0.2)
	fx_tween.parallel().tween_method(func(v): blur_mat.set_shader_parameter("tint_color", v), current_tint, target_tint, duration * 0.2)
	
	# Fade back to ABSOLUTE defaults (not current state)
	fx_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fx_tween.tween_method(func(v): blur_mat.set_shader_parameter("blur_strength", v), target_blur, DEFAULT_BLUR, duration * 0.8)
	fx_tween.parallel().tween_method(func(v): blur_mat.set_shader_parameter("tint_color", v), target_tint, DEFAULT_TINT, duration * 0.8)
	
	return fx_tween
