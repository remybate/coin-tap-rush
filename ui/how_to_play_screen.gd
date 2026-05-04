extends Control
class_name HowToPlayScreen

signal closed

@onready var close_button: Button = $Center/Panel/Margin/VBox/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


func show_help() -> void:
	visible = true


func hide_help() -> void:
	visible = false


func _on_close_pressed() -> void:
	AudioService.play_button_click()
	hide_help()
	closed.emit()
