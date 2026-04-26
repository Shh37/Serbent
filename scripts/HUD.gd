extends CanvasLayer

@onready var length_label = $Control/MarginContainer/HBoxContainer/LengthLabel
@onready var time_label = $Control/MarginContainer/HBoxContainer/TimeLabel

var snake: Node2D
var game_time = 0.0

func _ready():
	# Wait for the scene to be fully loaded to find the snake
	await get_tree().process_frame
	snake = get_tree().root.find_child("Snake", true, false)

func _process(delta):
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
