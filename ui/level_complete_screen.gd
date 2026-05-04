extends Control

signal continue_pressed

@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var score_label: Label = $Center/VBox/ScoreLabel
@onready var next_button: Button = $Center/VBox/NextButton


func _ready() -> void:
	next_button.pressed.connect(func() -> void: continue_pressed.emit())


func show_for(completed_level: int, current_score: int, next_level: int) -> void:
	title_label.text = "Level %d complete!" % completed_level
	score_label.text = "Score: %d" % current_score
	next_button.text = "Level %d" % next_level
	visible = true


func hide_screen() -> void:
	visible = false
