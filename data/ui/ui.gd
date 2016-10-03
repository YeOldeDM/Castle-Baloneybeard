tool
extends Control

# Time limit for the map
export(int) var time = 999 setget set_time
export(int) var level = 999 setget set_level
# var level = null

# Timer
var timer = null

# Time Label
onready var time_label = get_node("color_frame/hbox_time/label_time_value")
onready var level_label = get_node("color_frame/hbox_level/label_level_value")
onready var intro_label = get_node("intro/label")

# Intro Overlay (Level name and possibly extra information later)
onready var intro_node = get_node("intro")

# Time out Overlay
onready var time_out_node = get_node("time_out")

# Signal for game over
signal game_over()


func _ready():
	# time_label.set_text(str(time).pad_zeros(3))
	# level_label.set_text(str(level).pad_zeros(3))
	
	# Create timer and start it
	timer = Timer.new()
	timer.set_one_shot(false)
	timer.set_wait_time(1)
	timer.connect("timeout", self, "_countdown")
	add_child(timer)

func start_countdown():
	timer.start()

func _countdown():
	time -= 1 # decrease by one
	# If time is up
	if(time < 0):
		time = 0 # Time to 0
		timer.stop()
		time_out_node.show()
		print("TICK_COUNTDOWN_GAME OVER")
		emit_signal("game_over")
		# Game over
	time_label.set_text(str(time).pad_zeros(3))

func set_time(t):
	time = t
	
	# Due to tool being a bit weird; we have to use get_node in order to see "time" changes in the editor
	if(get_node("color_frame/hbox_time/label_time_value") != null):
		get_node("color_frame/hbox_time/label_time_value").set_text(str(time).pad_zeros(3))

func set_level(l):
	level = l
	
	if(get_node("intro/label") != null):
		get_node("intro/label").set_text("Level: " + str(level).pad_zeros(3))
	
	if(get_node("color_frame/hbox_level/label_level_value") != null):
		get_node("color_frame/hbox_level/label_level_value").set_text(str(level).pad_zeros(3))

func set_intro(is_enabled):
	if(is_enabled):
		intro_node.show()
	else:
		intro_node.hide()

func set_time_out(is_enabled):
	if(is_enabled):
		time_out_node.show()
	else:
		time_out_node.hide()
	