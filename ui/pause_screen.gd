extends Control
class_name PauseScreen

signal resume_pressed
signal settings_pressed
signal how_to_play_pressed
signal main_menu_pressed

@onready var resume_button: Button = $Center/Panel/Margin/VBox/ResumeButton
@onready var how_to_play_button: Button = $Center/Panel/Margin/VBox/HowToPlayButton
@onready var settings_button: Button = $Center/Panel/Margin/VBox/SettingsButton
@onready var main_menu_button: Button = $Center/Panel/Margin/VBox/MainMenuButton


func _ready() -> void:
	resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	how_to_play_button.pressed.connect(func() -> void: how_to_play_pressed.emit())
	settings_button.pressed.connect(func() -> void: settings_pressed.emit())
	main_menu_button.pressed.connect(func() -> void: main_menu_pressed.emit())


func show_pause() -> void:
	visible = true


func hide_pause() -> void:
	visible = false
